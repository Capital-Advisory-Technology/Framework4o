// provides functions that are used for risk management
#property copyright "Framework 4"
#property strict

#include <CAT/common/logger.mqh>

struct NewTrade {
    int positionType;
    int slPoints;
    double openPrice;
    double slPrice;
    double tpPrice;
    double lotSize;
};

class RiskManager {
    private:
        double riskPerTrade;
        double SLRatio;
        double TPRatio;
        double breakevenZone;
        double profitZone;
        double profitRatio;
        int ATRPeriod;

        int getSLpoints() {
            double atr = NormalizeDouble(iATR(Symbol(), Period(), ATRPeriod, 1), Digits);
            int points = (int)(atr / _Point * SLRatio);
            return points;
        }

        int getTPpoints(int stopLossPoints) {
            return (int)(stopLossPoints * TPRatio);
        }

        double getSLprice(NewTrade &t) {
            double stopLoss = t.slPoints * _Point;
            if (t.positionType == OP_BUY) return NormalizeDouble(t.openPrice - stopLoss, Digits);
            else return NormalizeDouble(t.openPrice + stopLoss, Digits);
        }

        double getTPprice(NewTrade &t) {
            double takeProfit = getTPpoints(t.slPoints) * _Point;
            if (t.positionType == OP_BUY) return NormalizeDouble(t.openPrice + takeProfit, Digits);
            else return NormalizeDouble(t.openPrice - takeProfit, Digits);
        }

        double getLotSize(NewTrade &t) {
            double tickVal;
            do {
                tickVal = MarketInfo(Symbol(), MODE_TICKVALUE);
                Logger::log("Tick value: " + string(tickVal));
                Sleep(200);
            } while (tickVal <= 0.00001);
                        
            double lotStep = MarketInfo(Symbol(), MODE_LOTSTEP);
            double minLot = MarketInfo(Symbol(), MODE_MINLOT);
            double maxLot = MarketInfo(Symbol(), MODE_MAXLOT);
            
            double lots = AccountBalance() * (riskPerTrade / 100) / (t.slPoints * tickVal);
            
            Logger::log("Lots: " + string(lots));
            double lotSize = MathMin(
                maxLot,
                MathMax(
                    minLot,
                    NormalizeDouble(lots / lotStep, 0) * lotStep
                )
            );
            Logger::log("Lot size: " + string(lotSize));
            return lotSize;
        }

    public:
        RiskManager::RiskManager(double cMaxOpenRisk, double cMaxOpenTrades, double cSLRatio, double cTPRatio, double cBreakevenZone, double cProfitZone, double cProfitRatio, int cATRPeriod) {
            this.riskPerTrade = NormalizeDouble(cMaxOpenRisk / cMaxOpenTrades, 2);
            this.SLRatio = cSLRatio;
            this.TPRatio = cTPRatio;
            this.breakevenZone = cBreakevenZone;
            this.profitZone = cProfitZone;
            this.profitRatio = cProfitRatio;
            this.ATRPeriod = cATRPeriod;
        }

        ~RiskManager() {
        }

        NewTrade getNewTrade(int cPositionType) {
            NewTrade trade;
            trade.positionType = cPositionType;
            trade.slPoints = getSLpoints();
            if (trade.positionType == OP_BUY) trade.openPrice = Ask;
            else trade.openPrice = Bid;

            trade.slPrice = getSLprice(trade);
            trade.tpPrice = getTPprice(trade);
            trade.lotSize = getLotSize(trade);
            return trade;
        }

        bool getBreakevenStatus(int cOrderType, double cOpenPrice, double cTpPrice) {
            if (breakevenZone <= 0 || breakevenZone >= 1) return false;

            double bePrice = NormalizeDouble(cOpenPrice + (cTpPrice - cOpenPrice) * breakevenZone, Digits);
            double lastHigh = iHigh(Symbol(), Period(), 1);
            double lastLow = iLow(Symbol(), Period(), 1);

            if (cOrderType == OP_BUY &&  bePrice <= lastHigh) return true;
            else if (cOrderType == OP_SELL && bePrice >= lastLow) return true;
            else return false;
        }

        bool getProfitZoneStatus(int cOrderType, double cOpenPrice, double cTpPrice) {
            if (profitZone <= 0 || profitZone >= 1) return false;

            double pzPrice = NormalizeDouble(cOpenPrice + (cTpPrice - cOpenPrice) * profitZone, Digits);
            double lastHigh = iHigh(Symbol(), Period(), 1);
            double lastLow = iLow(Symbol(), Period(), 1);

            if (cOrderType == OP_BUY &&  pzPrice <= lastHigh) return true;
            else if (cOrderType == OP_SELL && pzPrice >= lastLow) return true;
            else return false;
        }

        double getProfitZoneSL(int cOrderType, double cOpenPrice, double cTpPrice) {
            if (cOrderType == OP_BUY) return cOpenPrice + (cTpPrice - cOpenPrice) * profitRatio;
            else return cOpenPrice - (cOpenPrice - cTpPrice) * profitRatio;
        }
};