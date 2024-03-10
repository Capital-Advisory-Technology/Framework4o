// provides functions that are used for risk management
#property copyright "Framework 4"
#property strict

#include <CAT/common/logger.mqh> 

bool CheckForBreakEven(double breakeven) {

   if (OrderSelect(0, SELECT_BY_POS) == true) {
   
      int oticket = OrderTicket();
      double oop = NormalizeDouble(OrderOpenPrice(), Digits);
      double osl = NormalizeDouble(OrderStopLoss(), Digits);
      double otp = NormalizeDouble(OrderTakeProfit(), Digits);
      
      //--- Skip if the Open Order has stopLossPrice = openPrice or stopLoss in range openPrice +- 10 points
      if (oop == osl || (oop + (10 * _Point) > osl && oop - (10 * _Point) < osl)) {
         return false;
         
      } else {
         double high = High[1];
         double low = Low[1];
         double breakEvenPrice;
         bool orderModify;
         
         if (OrderType() == OP_BUY) {
            breakEvenPrice = NormalizeDouble(((otp - oop) * breakeven + oop), Digits);
            
            if (Bid >= breakEvenPrice || high >= breakEvenPrice) {
               orderModify = OrderModify(oticket, oop, oop, otp, 0, clrOrange);
               // if (!orderModify) Logger::log("Error in OrderModify. Error code = " + IntegerToString(GetLastError())); return false;
               return true;

            } else return false;

         } else {
            breakEvenPrice = NormalizeDouble((oop - (oop - otp) * breakeven), Digits);
            
            if (Ask <= breakEvenPrice || low <= breakEvenPrice) {
               orderModify = OrderModify(oticket, oop, oop, otp, 0, clrOrange);
               // if (!orderModify) Logger::log("Error in OrderModify. Error code = " +  IntegerToString(GetLastError())); return false;
               return true;
              
            } else return false;
         }      
      }
   } else return false;
}