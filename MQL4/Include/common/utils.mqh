#property copyright "Framework 4"
#property strict

/*
   Custom logic functions to validate indicator output.
   Example on usage is shown in Example.mq4
   User must understand default output values and nature of indicator
   before adding validation function.
*/

// Checks for long crossover
bool LongCrossOver(double buy, double sell, double buyPrev, double sellPrev) {
   return buy > sell && sellPrev > buyPrev;
}

// Checks for short crossover
bool ShortCrossOver(double buy, double sell, double buyPrev, double sellPrev) {
   return sell > buy && buyPrev > sellPrev;
}

// Checks if the values are bullish
bool CheckForLong(double buy, double sell) {
   return buy > sell;
}

// Checks if the values are bearish
bool CheckForShort(double buy, double sell) {
   return sell > buy;
}
  
// Checks for long crossover if one of the values is NULL
bool LongCrossOverNull(double buy, double sellPrev) {
   return buy != NULL && sellPrev != NULL;
}
  
// Checks for short crossover if one of the values is NULL
bool ShortCrossOverNull(double sell, double buyPrev) {
   return sell != NULL && buyPrev != NULL;
}
  
// Checks for long signal with EMPTY_VALUE
bool LongSignalEmptyValue(double buy, double sell) {
   return buy != EMPTY_VALUE && sell == EMPTY_VALUE;
}
  
// Checks for short signal with EMPTY_VALUE  
bool ShortSignalEmptyValue(double buy, double sell) {
   return sell != EMPTY_VALUE && buy == EMPTY_VALUE;
}
  
// Checks for long crossover with EMPTY_VALUE  
bool LongCrossOverEmptyValue(double buy, double sellPrev) {
    return buy != EMPTY_VALUE && sellPrev != EMPTY_VALUE;
}
  
// Checks for short crossover with EMPTY_VALUE
bool ShortCrossOverEmptyValue(double sell, double buyPrev) {
    return sell != EMPTY_VALUE && buyPrev != EMPTY_VALUE;
}

// Checks if the open price is above baseline
bool CheckForLongBaseline(double baseline) {
   return iOpen(NULL,0,0) >= baseline;
}
  
// Checks if the open price is below baseline  
bool CheckForShortBaseline(double baseline) {
   return iOpen(NULL,0,0) <= baseline;
}  
  
// Checks if the value is above zero line
bool CheckForAboveZeroLine(double buy, double buyPrev) {
   return buy > 0 && buyPrev < 0;
}  
  
// Checks if the value is below zero line
bool CheckForBelowZeroLine(double sell, double sellPrev) {
   return sell < 0 && sellPrev > 0;
}  
