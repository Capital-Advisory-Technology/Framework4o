// Functions used for entry when building a model.
// Commented above the function is QC for Quality Control &
// Function variables with suggested ranges, note that {}     
// means flexible & [] means fixed (including)
#property copyright "Framework 4"
#property strict

#include <CAT/common/enums.mqh>
#include <CAT/common/utils.mqh>

//| DEMA Crossover Entry (QC) 
//| DEMA_period - {20 - 120}
//| cDEMA_filter = [0 - 20]  | cDEMA_filter_period - {0 - 8}
//| cDEMA_enum_filter - [0 - 2]  |  cDEMA_enum_price - [0-32]
OrderAction DEMA_Simple(double cDEMA_period, int cDEMA_enum_price, double cDEMA_filter, int cDEMA_filter_period, int cDEMA_enum_filter) {
  enPrices DEMA_Price = (enPrices)cDEMA_enum_price;
  enFilterWhat DEMA_FilterOn = (enFilterWhat)cDEMA_enum_filter;

  double DEMA_Buy = iCustom(NULL, 0, "DEMA", PERIOD_CURRENT, cDEMA_period, DEMA_Price, cDEMA_filter, cDEMA_filter_period, DEMA_FilterOn, 3, 1);
  double DEMA_Sell = iCustom(NULL, 0, "DEMA", PERIOD_CURRENT, cDEMA_period, DEMA_Price, cDEMA_filter, cDEMA_filter_period, DEMA_FilterOn, 4, 1);

  if(LongSignalEmptyValue(DEMA_Buy,  DEMA_Sell)) return OA_OPEN_LONG;
  if(ShortSignalEmptyValue(DEMA_Buy,  DEMA_Sell)) return OA_OPEN_SHORT;
  return OA_IGNORE;
}

//| lr_period - {35 - 145}  |  lr_price [0 - 6]                 
OrderAction linear_reg_Simple(int lr_period, int lr_price) {
  OrderAction signal = OA_IGNORE;

  double lr_Buy = iCustom(NULL, 0, "linear-regression", lr_period, lr_price, 0, 1, 1);
  double lr_Sell = iCustom(NULL, 0, "linear-regression", lr_period, lr_price, 0, 2, 1);
  double lr_BuyPrev = iCustom(NULL, 0, "linear-regression", lr_period, lr_price, 0, 1, 2);
  double lr_SellPrev = iCustom(NULL, 0, "linear-regression", lr_period, lr_price, 0, 2, 2);

  if(LongCrossOverEmptyValue(lr_Buy, lr_SellPrev)) signal = OA_OPEN_LONG;
  if(ShortCrossOverEmptyValue(lr_Sell,  lr_BuyPrev)) signal = OA_OPEN_SHORT;
  return signal; 
}

  
// Custom ENUMS 0-32
enum enPrices {
  pr_close,       // Close 0
  pr_open,        // Open 1
  pr_high,        // High 2
  pr_low,         // Low 3
  pr_median,      // Median 4
  pr_typical,     // Typical 5
  pr_weighted,    // Weighted 6
  pr_average,     // Average (high+low+open+close)/4 7
  pr_medianb,     // Average median body (open+close)/2 8
  pr_tbiased,     // Trend biased price 9
  pr_tbiased2,    // Trend biased (extreme) price 10
  pr_haclose,     // Heiken ashi close 11
  pr_haopen,      // Heiken ashi open 12
  pr_hahigh,      // Heiken ashi high 13
  pr_halow,       // Heiken ashi low 14 
  pr_hamedian,    // Heiken ashi median 15
  pr_hatypical,   // Heiken ashi typical 16
  pr_haweighted,  // Heiken ashi weighted 17
  pr_haaverage,   // Heiken ashi average 18
  pr_hamedianb,   // Heiken ashi median body 19
  pr_hatbiased,   // Heiken ashi trend biased price 20
  pr_hatbiased2,  // Heiken ashi trend biased (extreme) price 21
  pr_habclose,    // Heiken ashi (better formula) close 22
  pr_habopen,     // Heiken ashi (better formula) open 23
  pr_habhigh,     // Heiken ashi (better formula) high 24
  pr_hablow,      // Heiken ashi (better formula) low 25
  pr_habmedian,   // Heiken ashi (better formula) median 26
  pr_habtypical,  // Heiken ashi (better formula) typical 27
  pr_habweighted, // Heiken ashi (better formula) weighted 28
  pr_habaverage,  // Heiken ashi (better formula) average 29
  pr_habmedianb,  // Heiken ashi (better formula) median body 30
  pr_habtbiased,  // Heiken ashi (better formula) trend biased price 31
  pr_habtbiased2 // Heiken ashi (better formula) trend biased (extreme) price 32
};

enum enMaTypes {
  ma_sma,     // Simple moving average
  ma_ema,     // Exponential moving average
  ma_smma,    // Smoothed MA
  ma_lwma,    // Linear weighted MA
  ma_tema    // Triple exponential moving average - TEMA
};

enum enFilterWhat {
  flt_prc,   // Filter the price
  flt_val,   // Filter the Dema value
  flt_both  // Filter both
};
