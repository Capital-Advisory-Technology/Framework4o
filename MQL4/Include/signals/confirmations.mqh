// Functions used as confirmations when building a model.            |
// Commented above the function is QC for Quality Control &          |
// Function variables with suggested ranges, note that {}            |
// means flexible & [] means fixed (including)                       |

#property copyright "Framework 4"
#property strict

#include <CAT/common/enums.mqh>
#include <CAT/common/utils.mqh>
#include <CAT/signals/entry.mqh>

//| EMA Baseline check
//| EMA Baseline check (QC)
//| EMA_period - {65 - 200}  |  EMA_set_price - [0 - 8]                           
OrderAction EMA_Baseline(double EMA_period, double EMA_set_price) {
  OrderAction signal = OA_IGNORE;
  double EMA_baseline = iCustom(NULL, 0, "EMA", EMA_period, 0.0, 0, EMA_set_price, 0, 1);
  if(CheckForLongBaseline(EMA_baseline)) signal = OA_OPEN_LONG;
  if(CheckForShortBaseline(EMA_baseline)) signal = OA_OPEN_SHORT;
  return signal;
}

//| RSI Confirmation
//| DEMA Baseline check (QC)
//| cDEMA_period - {60 - 200}     |  cDEMA_enum_price - [ANY enPrice ENUM]  |  cDEMA_Filter = {0 - 8}
//| cDEMA_FilterPeriod - {0 - 8}  |  cDEMA_enum_filter - [0 - 2]                          
OrderAction DEMA_Baseline(double cDEMA_period, int cDEMA_enum_price, double cDEMA_Filter, int cDEMA_FilterPeriod, int cDEMA_enum_filter) {
  OrderAction signal = OA_IGNORE;

  enPrices DEMA_Price = (enPrices)cDEMA_enum_price; 
  enFilterWhat DEMA_FilterOn = (enFilterWhat)cDEMA_enum_filter;

  double DEMA_Baseline = iCustom(NULL, 0, "DEMA", PERIOD_CURRENT, cDEMA_period, DEMA_Price, cDEMA_Filter, cDEMA_FilterPeriod, DEMA_FilterOn, 0, 1);
  if(CheckForLongBaseline(DEMA_Baseline)) signal = OA_OPEN_LONG;
  if(CheckForShortBaseline(DEMA_Baseline)) signal = OA_OPEN_SHORT;
  return signal; 
}
//| RSI Confirmation (QC) (OA_CONFIRMED)
//| RSI_period - {14 - 28}
OrderAction RSI_Confirmation(int RSI_period, bool RSI_vol) {
  OrderAction signal = OA_IGNORE;
  double RSI_Line = iCustom(NULL, 0, "RSI", RSI_period, 0, 1);

  if (RSI_Line > 30 && RSI_Line < 70) {
    if (RSI_Line < 44.94 || RSI_Line > 54.94) {
      return OA_CONFIRMED;  
    }
  }

  return OA_IGNORE;
}

