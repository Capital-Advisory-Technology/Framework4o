// Functions used for entry when building a model.
// Function variables with suggested ranges, note that {}     
// means flexible & [] means fixed (including)
#property copyright "Framework 4"
#property strict

#include <CAT/common/enums.mqh>
#include <CAT/common/utils.mqh>

//| linear-reg Crossover Entry
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

  
enum enMaTypes {
  ma_sma,     // Simple moving average
  ma_ema,     // Exponential moving average
  ma_smma,    // Smoothed MA
  ma_lwma,    // Linear weighted MA
  ma_tema     // Triple exponential moving average - TEMA
};