#property copyright "Framework 4"
#property strict

#include <main/riskmanager.mqh>

#include <common/calculations.mqh>
#include <common/enums.mqh>
#include <common/logger.mqh>
#include <common/session.mqh>

static int openPositionType;

/*
   Position manager meant for controlling when we can open/close position. 
   This class should be initialized in EA's onInit() function. PositionManager is linked together
   with Backtest instance.
   
   Important note if you decide to modify this class:
       DO NOT SPAM "OrderSelect" across separate files. As we have MAX
       one position at any given time, "OrderSelect" is called only after order is opened.
       The global OrderSelect instance is used accross multiple functions and files and if you select different
       order at incorrect time, you WILL mess up values.
*/
class PositionManager {

   private:
      double riskPerTrade;
      double SLRatio;
      double TPRatio;
      int ATRPeriod;
      int slippage;
      double breakEven;
      bool fixedSLTP;
      datetime lastBarTime;
      RiskManager* riskManager;
      CustomSession* customSession;
   
   public:
      PositionManager::PositionManager(RiskManager* cRiskManager, CustomSession* cCustomSession, double cSLRatio, double cTPRatio, int cATRPeriod,double cRiskPerTrade, int cSlippage, double cBreakEven, bool cfixedSLTP) {
        this.riskManager = cRiskManager;
        this.riskPerTrade = cRiskPerTrade;
        this.SLRatio = cSLRatio;
        this.TPRatio = cTPRatio;
        this.ATRPeriod = cATRPeriod;
        this.slippage = cSlippage;
        this.lastBarTime = Time[0];
        this.breakEven = cBreakEven;
        this.fixedSLTP = cfixedSLTP;
        this.customSession = cCustomSession;
      }
      
      ~PositionManager() {
         delete customSession;
         delete riskManager;
      }
    
   /*
      Open order. TP/SL is calculted according to externals.
      To not complictae things, call this function from EA's switch/case statement
      where we check if there are no other positions open. If you decide 
      to call this function from other parts of code, you might open multiple 
      positions at once.
   */
   void openOrder(int positionType) {
      if (!customSession.allowToOpen(positionType)) return;
      // Calculate values for order
      riskManager.newTrade(positionType);
      double lotSize = riskManager.getLotSize();
      double slPrice = riskManager.getSLprice();
      double tpPrice = riskManager.getTPprice();
      double openPrice;
      if (positionType == OP_BUY) openPrice = Ask; else openPrice = Bid;
      
      int number = OrderSend(Symbol(), positionType, lotSize, openPrice, slippage, slPrice, tpPrice, "Comment", 0, 0, Red);
      Logger::log("Opened order number: " + string(number));
      
      if  (number != -1) {
         Logger::log("Order send success");
         if (OrderSelect(0, SELECT_BY_POS)) {
            openPositionType = positionType;
            customSession.onPositionOpened();
         } else {
           Logger::log("Select position error: " + string(GetLastError()));
         }
      } else {
         Logger::log("Open position error: " + string(GetLastError()));
      }  
   };
   
    /*
      Close order. 
      To not complicate things, call this function from EA's switch/case statement
      Where we check if there are open positions. Used only for manual closing i.e. in EA's 
      IS_OPENED block.
   */
   void closePosition() {
      if (OrdersTotal() == 0) return;

      double price;

      if (OrderType() == OP_BUY) price = Bid; else price = Ask;
      
      if (OrderClose(OrderTicket(), OrderLots(), price, 30, White)) {
         if (OrderSelect(OrdersHistoryTotal() - 1, SELECT_BY_POS, MODE_HISTORY) == true) {
            Logger::log("Position closed");
         } else {
            Logger::log("Could not access last historical order... ErrorCode= " + string(GetLastError()));
         }
      } else {
         Logger::log("Close position error: " + string(GetLastError()));
      }
   }
   
   void checkBreakeven() {
      if (OrderSelect(0, SELECT_BY_POS) == true) {
         int oticket = OrderTicket();
         double oop = NormalizeDouble(OrderOpenPrice(), Digits); 
         double osl = NormalizeDouble(OrderStopLoss(), Digits);
         double otp = NormalizeDouble(OrderTakeProfit(), Digits);
         double breakevenPrice = riskManager.getBreakevenPrice();
         bool orderModify;

         if (OrderType() == OP_BUY) {
            if (Bid >= breakevenPrice || High[1] >= breakevenPrice) {
               orderModify = OrderModify(oticket, oop, oop, otp, 0, clrOrange);
            }
         } else {
            if (Ask <= breakevenPrice || Low[1] <= breakevenPrice) {
               orderModify = OrderModify(oticket, oop, oop, otp, 0, clrOrange);
            }
         }

         if (orderModify) {
            riskManager.setBreakeven();
            Logger::log("Breakeven set");
         } else {
            Logger::log("Break even error: " + string(GetLastError()));
         }
      } else {
         Logger::log("Could not access last historical order... ErrorCode= " + string(GetLastError()));
      }
   }

   void checkProfitZone() {
      if (OrderSelect(0, SELECT_BY_POS) == true) {
         int oticket = OrderTicket();
         double oop = NormalizeDouble(OrderOpenPrice(), Digits); 
         double otp = NormalizeDouble(OrderTakeProfit(), Digits);
         double profitZonePrice = riskManager.getProfitZonePrice();
         double newSL = riskManager.getProfitZoneSLPrice();
         bool orderModify;

         if (OrderType() == OP_BUY) {
            if (Bid >= profitZonePrice || High[1] >= profitZonePrice) {
               orderModify = OrderModify(oticket, oop, newSL, otp, 0, clrWhite);
            }
         } else {
            if (Ask <= profitZonePrice || Low[1] <= profitZonePrice) {
               orderModify = OrderModify(oticket, oop, newSL, otp, 0, clrWhite);
            }
         }

         if (orderModify) {
            riskManager.setProfitZone();
            Logger::log("Profit zone set");
         } else {
            Logger::log("Profit zone error: " + string(GetLastError()));
         }

      } else {
         Logger::log("Could not access last historical order... ErrorCode= " + string(GetLastError()));
      }
   }

   void checkBreakevenProfit() {
      int orderType = OrderType();

      double oop = NormalizeDouble(OrderOpenPrice(), Digits); 
      double osl = NormalizeDouble(OrderStopLoss(), Digits);
      double otp = NormalizeDouble(OrderTakeProfit(), Digits);

      // Check for breakeven
      if (((orderType == OP_BUY && osl < oop) || (orderType == OP_SELL && osl > oop)) && riskManager.getBreakevenStatus(orderType, oop, otp)) {
         bool orderModify = OrderModify(OrderTicket(), oop, oop, otp, 0, clrOrange);
         if (orderModify) Logger::log("PositionManager.checkBreakevenNew() - Breakeven set");
         else Logger::log("PositionManager.checkBreakevenNew() - Break even error: " + string(GetLastError()));
      }
      
      // Check for profit zone
      if (osl == oop && riskManager.getProfitZoneStatus(orderType, oop, otp)) {
         double nsl = riskManager.getProfitZoneSL(orderType, oop, otp);
         bool orderModify = OrderModify(OrderTicket(), oop, nsl, otp, 0, clrWhite);
         if (orderModify) Logger::log("PositionManager.checkBreakevenNew() - Profit zone set");
         else Logger::log("PositionManager.checkBreakevenNew() - Profit zone error: " + string(GetLastError()));
      }
   }

   PositionStatus getStatus() {
      if (OrdersTotal() > 0) {
         for( int i = 0 ; i < OrdersTotal() ; i++ ) { 
            if (OrderSelect( i, SELECT_BY_POS, MODE_TRADES ) && OrderSymbol() == Symbol()) {   
               checkBreakevenProfit();
            }; 
         }
         Logger::log("PositionManager.getStatus() - IS_OPENED"); 
         return IS_OPENED;
      } else {
         Logger::log("PositionManager.getStatus() - AVAILABLE_TO_OPEN");
         return AVAILABLE_TO_OPEN;
      }
   }
};
