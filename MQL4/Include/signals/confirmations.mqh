// Functions used as confirmations when building a model.
// Function variables with suggested ranges, note that {}
// means flexible & [] means fixed (including)

#property copyright "Framework 4"
#property strict

#include <CAT/common/enums.mqh>
#include <CAT/common/utils.mqh>
#include <CAT/signals/entry.mqh>

//| EMA Baseline check
//| EMA_period - {65 - 200}  |  EMA_set_price - [0 - 8]                           
OrderAction EMA_Baseline(double EMA_period, double EMA_set_price) {
  OrderAction signal = OA_IGNORE;
  double EMA_baseline = iCustom(NULL, 0, "EMA", EMA_period, 0.0, 0, EMA_set_price, 0, 1);
  if (CheckForLongBaseline(EMA_baseline)) signal = OA_OPEN_LONG;
  if (CheckForShortBaseline(EMA_baseline)) signal = OA_OPEN_SHORT;
  return signal;
}

//| RSI Confirmation
//| RSI_period - {14 - 28}
OrderAction RSI_Confirmation(int RSI_period) {
  OrderAction signal = OA_IGNORE;
  double RSI_Line = iCustom(NULL, 0, "RSI", RSI_period, 0, 1);
  if (RSI_Line > 30 && RSI_Line < 70) signal = OA_CONFIRMED;
  return signal;
}