/*
   Custom header classes for trading session setting. 
   Example provided in Example.mq4.
   Remove object creation in case it is not needed.
*/

#property copyright "Framework 4"
#property strict

#include <common/logger.mqh>
#include <common/enums.mqh>

class Range {
   private:
      int beginning;
      int end;
      AllowedOrder allowedOrder;

   public:
      Range::Range(int cBeginning, int cEnd, AllowedOrder cAllowedOrder) {
         this.beginning = cBeginning;
         this.end = cEnd;
         this.allowedOrder = cAllowedOrder;
      }
      
      int getBeginning() { return beginning; }
      
      int getEnd() { return end; }
      
      AllowedOrder getAllowedOrder() { return allowedOrder; }
};

class CustomSession {  
   public:
      CustomSession::CustomSession() {
         positionsInPeriod = 0;
         limitPeriod = PERIOD_MN1;
         allowToOpen(0);
      }
      
      ~CustomSession() {
         for(int i = 0; i < ArraySize(minuteRanges); i++) {
            delete minuteRanges[i];
         }
         for(int i = 0; i < ArraySize(hourRanges); i++) {
            delete hourRanges[i];
         }
         for(int i = 0; i < ArraySize(dayRanges); i++) {
            delete dayRanges[i];
         }
         for(int i = 0; i < ArraySize(monthRanges); i++) {
            delete monthRanges[i];
         }
      }

      void addMinuteRange(int beginning, int end, AllowedOrder allowedOrder) {
         ArrayResize(minuteRanges, ArraySize(minuteRanges) + 1); 
         minuteRanges[ArraySize(minuteRanges) - 1] = new Range(beginning, end, allowedOrder);
      }
      
      void addHourRange(int beginning, int end, AllowedOrder allowedOrder) {
         ArrayResize(hourRanges, ArraySize(hourRanges) + 1); 
         hourRanges[ArraySize(hourRanges) - 1] = new Range(beginning, end, allowedOrder);
      }
      
      void addDayOfWeekRange(int beginning, int end, AllowedOrder allowedOrder) {
         ArrayResize(dayRanges, ArraySize(dayRanges) + 1); 
         dayRanges[ArraySize(dayRanges) - 1] = new Range(beginning, end, allowedOrder);
      }
      
      void addMonthRange(int beginning, int end, AllowedOrder allowedOrder) {
         ArrayResize(monthRanges, ArraySize(monthRanges) + 1); 
         monthRanges[ArraySize(monthRanges) - 1] = new Range(beginning, end, allowedOrder);
      }
      
      void refresh() {   
          switch (limitPeriod) {   
            case PERIOD_H1:
               checkNewLimitPeriod(Hour());
               break;
           
            case PERIOD_D1:
               checkNewLimitPeriod(Day());
               break;
           
            case PERIOD_MN1:
               checkNewLimitPeriod(Month());
               
            default:
               Logger::log("Limit period is not supported");
               ExpertRemove();
         }
      }
    
      bool allowToOpen(int positionType) {
         bool isPositionLimitExceeded = isPositionLimitExceeded();
         bool isCustomSessionMinute = isInSession(minuteRanges, Minute(), positionType);
         bool isCustomSessionHour = isInSession(hourRanges, Hour(), positionType);
         bool isCustomSessionDayOfWeek = isInSession(dayRanges, DayOfWeek(), positionType);
         bool isCustomSessionMonth = isInSession(monthRanges, Month(), positionType);
         
         bool hourExpression = isCustomSessionDayOfWeek && isCustomSessionHour && isCustomSessionMonth;
         bool minuteExpression = isCustomSessionDayOfWeek
          && isCustomSessionHour
          && isCustomSessionMinute
          && isCustomSessionMonth;
           
         switch (Period()) {
            case PERIOD_M1:
               return minuteExpression && !isPositionLimitExceeded;
               
            case PERIOD_M5:
               return minuteExpression && !isPositionLimitExceeded;
            
            case PERIOD_M30:
               return minuteExpression && !isPositionLimitExceeded;
               
            case PERIOD_M15:
               return minuteExpression && !isPositionLimitExceeded;
            
            case PERIOD_H1:
               return hourExpression && !isPositionLimitExceeded;
            
            case PERIOD_H4:
               return hourExpression && !isPositionLimitExceeded;
               
            case PERIOD_D1:
               return isCustomSessionDayOfWeek && isCustomSessionMonth && !isPositionLimitExceeded;
            
            case PERIOD_MN1:
               return isCustomSessionMonth && !isPositionLimitExceeded;
            
            default:
               return false;
         }
      }
      
      void onPositionOpened() {
         positionsInPeriod++;
      }
      
      void setPositionLimit(int limit, int period) {
         if (period < Period()) {
            Logger::log("Position limit period is below current EA period. Please set it equal or larger");
            ExpertRemove();
            return;
         }
         limitPeriod = period;
         positionLimit = limit;
      }
         
   private:
      Range* minuteRanges[];
      Range* hourRanges[];
      Range* dayRanges[];
      Range* monthRanges[];
      int positionLimit;
      int positionsInPeriod;
      int limitPeriod;
      int lastTimeValue;
      
      bool isPositionLimitExceeded() {
         return positionsInPeriod == positionLimit;
      }
      
      bool isInSession(Range* &rangeList[], int compareTo, int positionType) {
         for (int i = 0; i < ArraySize(rangeList); i++) {
            Range* range = rangeList[i];
            bool isSupportedOrderType = true;
            
            switch (range.getAllowedOrder()) {
               case OPEN_LONG:
                  if (positionType != OP_BUY) isSupportedOrderType = false;
                  break;
               case OPEN_SHORT:
                  if (positionType != OP_SELL) isSupportedOrderType = false;
                  break;
               case OPEN_BOTH:
                  break;
            }
            
            if (!isSupportedOrderType) continue;
            
            if (compareTo >= range.getBeginning() && compareTo <= range.getEnd()) {
               return true;
            }
         }
         return false;
      }
      
      void checkNewLimitPeriod(int currentTime) {
         if (lastTimeValue != currentTime) {
            lastTimeValue = currentTime;
            positionsInPeriod = 0;
        }
      }  
};