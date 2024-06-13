#include <CAT/signals/confirmations.mqh>
#include <CAT/signals/exit.mqh>
#include <CAT/common/exporter.mqh>

// Backtest's externals for optimization
input string BACKTEST_EXTERNALS = "";
extern string strategy_name = "DEMAEMARSI";
extern int slippage = 3;
extern double exportPFThreshold = 0;
input string RISK_EXTERNALS = "";
extern double max_open_risk = 1.0;
extern int max_open_trades = 3;
extern int ATR_period = 14; 
extern double SL_ratio = 1.5;
extern double TP_ratio = 3.0;
input string PROFIT_EXTERNALS = "";
extern double breakeven = 0.5;
extern double profit_zone = 0.9;
extern double profit_zone_reward = 0.2;
input string SESSION_EXTERNALS = "";
extern int hour_limit_start = 2;
extern int hour_limit_end = 22;

// Strategies externals
input string STRATEGIES_EXTERNALS = "";
input string DEMA_EXTERNALS = "";
extern double DEMA_period = 26;
extern double DEMA_filter = 0;
extern int DEMA_filter_period = 0;
extern int DEMA_enum_price = 0;
extern int DEMA_enum_filter = 0;

input string EMA_EXTERNALS = "";
extern int ema_period = 30;
extern int ema_price = 8;

input string RSI_EXTERNALS = "";
extern int rsi_period = 14;
extern bool rsi_vol = true;

BacktestExporter* backtestExporter;
PositionManager* positionManager;
CustomSession* customSession;
RiskManager* riskManager;

int OnInit() {
    Logger::log("Strategy name: " + strategy_name + " Symbol: " + Symbol() + " Point: " + string(_Point));
    
    customSession = new CustomSession();
    customSession.addMinuteRange(0, 59, OPEN_BOTH);                           // Min 0, Max 59
    customSession.addHourRange(hour_limit_start, hour_limit_end, OPEN_BOTH);  // Min 0, Max 23
    customSession.addDayOfWeekRange(1, 7, OPEN_BOTH);                         // Min 1, Max 7
    customSession.addMonthRange(1, 12, OPEN_BOTH);                            // Min 1, Max 12
    customSession.setPositionLimit(10, PERIOD_D1);                            // Support only H1, D1 and MN1

    backtestExporter = new BacktestExporter();
    
    riskManager = new RiskManager(max_open_risk, max_open_trades, SL_ratio, TP_ratio,
                                  breakeven, profit_zone, profit_zone_reward, ATR_period);

    positionManager = new PositionManager(riskManager, customSession, slippage, max_open_trades);

    return (INIT_SUCCEEDED);
}

void OnTick() {
    static datetime timeCur;
    datetime timePre = timeCur;
    timeCur = Time[0];
    bool isNewBar = timeCur != timePre;
    if (!isNewBar) return;
    Logger::log("New bar: " + string(timeCur));

    // not working quite yet...
    // if (positionManager.rolloverDeals() != true) return;
    if (positionManager.getStatus() != AVAILABLE_TO_OPEN) return;

    customSession.refresh();

    OrderAction dema_signal = DEMA_Simple(DEMA_period,DEMA_enum_price,DEMA_filter,
                                          DEMA_filter_period,DEMA_enum_filter);

    OrderAction ema_confirm = EMA_Baseline(ema_period, ema_price);

    OrderAction rsi_confirm = RSI_Confirmation(rsi_period, rsi_vol);

    if (dema_signal == OA_OPEN_SHORT 
        && ema_confirm == OA_OPEN_SHORT 
        && rsi_confirm == OA_CONFIRMED) 
    {
        positionManager.openOrder(OP_SELL);

    } else if (dema_signal == OA_OPEN_LONG 
              && ema_confirm == OA_OPEN_LONG 
              && rsi_confirm == OA_CONFIRMED) 
    {
        positionManager.openOrder(OP_BUY);

    } else Logger::log("OnTick: No signal");
    
}

void OnDeinit(const int reason) {
    if ((IsOptimization() || IsTesting()) && TesterStatistics(STAT_PROFIT_FACTOR) >= exportPFThreshold) {
        CJAVal inputJson;
    
        inputJson["strategy_name"] = strategy_name;
        inputJson["slippage"] = slippage;

        inputJson["max_open_risk"] = max_open_risk;
        inputJson["max_open_trades"] = max_open_trades;
        inputJson["ATR_period"] = ATR_period;
        inputJson["SL_ratio"] = SL_ratio;
        inputJson["TP_ratio"] = TP_ratio;

        inputJson["breakeven"] = breakeven;
        inputJson["profit_zone"] = profit_zone;
        inputJson["profit_zone_reward"] = profit_zone_reward;

        inputJson["hour_limit_start"] = hour_limit_start;
        inputJson["hour_limit_end"] = hour_limit_end;

        inputJson["DEMA_period"] = DEMA_period;
        inputJson["DEMA_filter"] = DEMA_filter;
        inputJson["DEMA_filter_period"] = DEMA_filter_period;
        inputJson["DEMA_enum_price"] = DEMA_enum_price;
        inputJson["DEMA_enum_filter"] = DEMA_enum_filter;

        inputJson["EMA_period"] = ema_period;
        inputJson["EMA_price"] = ema_price;

        inputJson["RSI_period"] = rsi_period;

        backtestExporter.exportBacktest(strategy_name, inputJson.Serialize(), customSession.toString());
    }

    delete backtestExporter;
    delete positionManager;
}