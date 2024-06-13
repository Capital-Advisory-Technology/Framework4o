#property copyright "Framework 4"
#property strict

#include <CAT/main/riskmanager.mqh>

#include <CAT/common/enums.mqh>
#include <CAT/common/logger.mqh>
#include <CAT/common/session.mqh>

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
      int slippage;
      int maxOpenPositions;
      datetime lastBarTime;
      RiskManager* riskManager;
      CustomSession* customSession;

   public:
      PositionManager::PositionManager(RiskManager* cRiskManager, CustomSession* cCustomSession, int cSlippage, int cMaxOpenPositions = 1) {
        this.riskManager = cRiskManager;
        this.slippage = cSlippage;
        this.lastBarTime = Time[0];
        this.customSession = cCustomSession;
        this.maxOpenPositions = cMaxOpenPositions;
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
      NewTrade trade = riskManager.getNewTrade(positionType);
      Logger::log("Open Order: " + string(trade.positionType) + " Lot Size: " + string(trade.lotSize) + " Open Price: " + string(trade.openPrice) + " SL: " + string(trade.slPrice) + " TP: " + string(trade.tpPrice));

      int number = OrderSend(Symbol(), positionType, trade.lotSize, trade.openPrice, slippage, trade.slPrice, trade.tpPrice, "Comment", 0, 0, Red);
      Logger::log("Opened order number: " + string(number));

      if  (number != -1) {
         Logger::log("Order send success");
         if (OrderSelect(0, SELECT_BY_POS)) {
            customSession.onPositionOpened();
         } else {
           Logger::log("Select position error: " + string(GetLastError()));
         }
      } else {
         Logger::log("Open position error: " + string(GetLastError()));
      }
   };

   /*
      Check and set breakeven or profit zone for a position.
      This function is called from getStatus() function.
   */
   void checkProfitZones() {
      int orderType = OrderType();

      double oop = NormalizeDouble(OrderOpenPrice(), Digits);
      double osl = NormalizeDouble(OrderStopLoss(), Digits);
      double otp = NormalizeDouble(OrderTakeProfit(), Digits);

      bool isBreakeven = riskManager.getBreakevenStatus(orderType, oop, otp);
      bool isProfitZone = riskManager.getProfitZoneStatus(orderType, oop, otp);

      // Check for breakeven
      if (isBreakeven && ((orderType == OP_BUY && osl < oop) || (orderType == OP_SELL && osl > oop))) {
         bool orderModify = OrderModify(OrderTicket(), oop, oop, otp, 0, clrOrange);
         if (orderModify) Logger::log("PositionManager.checkProfitZones() - Breakeven set");
         else Logger::log("PositionManager.checkProfitZones() - Break even error: " + string(GetLastError()));
      }

      // Check for profit zone
      if (isProfitZone && osl == oop) {
         double nsl = riskManager.getProfitZoneSL(orderType, oop, otp);
         bool orderModify = OrderModify(OrderTicket(), oop, nsl, otp, 0, clrWhite);
         if (orderModify) Logger::log("PositionManager.checkProfitZones() - Profit zone set! New SL: " + string(nsl) + " Old SL: " + string(osl) + " Open Price: " + string(oop) + " TP: " + string(otp) + " Order Type: " + string(orderType) + " Order SL: " + string(osl) + " Order TP: " + string(otp) + " Order Open Price: " + string(oop));
         else Logger::log("PositionManager.checkProfitZones() - Profit zone error: " + string(GetLastError()));
      }
   }

   PositionStatus getStatus() {
      int ordersTotal = OrdersTotal();
      if (ordersTotal > 0) {
         for( int i = 0 ; i < OrdersTotal() ; i++ ) {
            if (OrderSelect( i, SELECT_BY_POS, MODE_TRADES ) && OrderSymbol() == Symbol()) {
               checkProfitZones();
            };
         }
         if (ordersTotal >= maxOpenPositions) {
            Logger::log("PositionManager.getStatus() - MULTIPLE_POSITIONS");
            return IS_OPENED;
         }
         Logger::log("PositionManager.getStatus() - IS_OPENED");
         return AVAILABLE_TO_OPEN;
      } else {
         Logger::log("PositionManager.getStatus() - AVAILABLE_TO_OPEN");
         return AVAILABLE_TO_OPEN;
      }
   }

   bool rolloverDeals() {
      // Get current date
      datetime currentTime = TimeCurrent();
      int currentMonth = TimeMonth(currentTime);

      // Check if a new month has started
      static int lastMonth = -1;
      if (currentMonth != lastMonth) {
         // Loop through all open positions
         for (int i = OrdersTotal()-1; i >= -1 ; i--) {
            Logger::log("PositionManager.rolloverDeals() - Orders Total: " + string(OrdersTotal()));

            if (OrderSelect(i, SELECT_BY_POS)) {
               // Close the position, use ASK to sell position
               if (OrderType() == OP_SELL) {
                  if (!OrderClose(OrderTicket(), OrderLots(), MarketInfo(OrderSymbol(), MODE_ASK), 3)) {
                     Logger::log("PositionManager.rolloverDeals() - Failed to close deal: " 
                                 + string(OrderTicket()) + " Last error: " + string(GetLastError()));
                     return false;
                  }
               else {
                  if (!OrderClose(OrderTicket(), OrderLots(), MarketInfo(OrderSymbol(), MODE_BID), 3)) {
                     Logger::log("PositionManager.rolloverDeals() - Failed to close deal: " 
                                 + string(OrderTicket()) + " Last error: " + string(GetLastError()));
                     return false;
                  }}
               }
            } else {
               Logger::log("PositionManager.rolloverDeals() - No orders selected, SELECT_BY_POS: "
                           + string(SELECT_BY_POS));
            }
         }

         Logger::log("PositionManager.rolloverDeals() - All deals rolled over for month " + string(lastMonth));
         
         // Update last month
         lastMonth = currentMonth;
      }
      return true;
   }
};
