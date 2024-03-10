#property copyright "Framework 4"
#property strict

#define ATRIndicator "Indicators\\Adaptive_ATR.ex4"
#resource "\\" + ATRIndicator

//+------------------------------------------------------------------+
//| Calculates LotSize based on balance, risk and StopLoss           |
//+------------------------------------------------------------------+
double CalculateLotSize(double risk, int stopLoss) {
  double lotStep = MarketInfo(Symbol(), MODE_LOTSTEP);
  double minLot = MarketInfo(Symbol(), MODE_MINLOT);
  double maxLot = MarketInfo(Symbol(), MODE_MAXLOT);
  double tickVal = MarketInfo(Symbol(), MODE_TICKVALUE);

  double lotSize = AccountBalance() * risk / 100 / (stopLoss * tickVal);
  
  return MathMin(maxLot, MathMax(minLot,NormalizeDouble(lotSize / lotStep, 0) * lotStep));
}

//+------------------------------------------------------------------+
//| Calculates SL based on ATR or fixed value                        |
//+------------------------------------------------------------------+
int CalculateSL(double stopLossRatio, int ATRPeriod, bool fixed) {
  int stopLoss = NULL;
  double atr = NULL;

  switch (fixed) {
    case true:
      stopLoss = (int)MathRound(stopLossRatio);
      break;
    case false:
      atr = NormalizeDouble(iATR(Symbol(), Period(), ATRPeriod, 1), Digits);
      stopLoss = (int)(atr / _Point * stopLossRatio);
      if (stopLoss < 100) stopLoss = 100;
      break;
  }

  return stopLoss;
}

//+------------------------------------------------------------------+
//| Calculates TP according to calculated SL                         |
//+------------------------------------------------------------------+
int CalculateTP(double takeProfitRatio, int stopLoss ,bool fixed) {
  int takeProfit = NULL;

  switch (fixed) {
    case true:
      takeProfit = (int)MathRound(takeProfitRatio);
      break;
    case false:
      takeProfit = (int)(stopLoss * takeProfitRatio);
      break;
    }

  return takeProfit;
}

//+------------------------------------------------------------------+
//| Returns SL price for instrument                                  |
//+------------------------------------------------------------------+
double GetSLprice(int stopLoss, int orderType) {
  double price = NULL;

  switch(orderType) {
    case OP_BUY:
      price = NormalizeDouble(Ask-stopLoss*_Point, Digits);
      break;
    case OP_SELL:
      price = NormalizeDouble(Bid+stopLoss*_Point, Digits);
      break;
  }
  return price;
}


//+------------------------------------------------------------------+
//| Returns TP price for instrument                                  |
//+------------------------------------------------------------------+
double GetTPprice(int takeProfit, int orderType) {
  double price = NULL;

  switch(orderType) {
    case OP_BUY:
      price = NormalizeDouble(Ask+takeProfit*_Point, Digits);
      break;
    case OP_SELL:
      price = NormalizeDouble(Bid-takeProfit*_Point, Digits);
      break;
  }
  
  return price;
}
