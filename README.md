# Framework4 Concept Repo

OFramework4 is an open-source framework written in MQL4 for development of trading models in MetaTrader 4.
Framework provides a structured approach to strategy development by having main modules pre-defined.

## Features

- **Position Management**: Accurate management of all open deals. Includes functionality for opening, closing and managing positions based on indicator actions.
- **Risk Management**: Accurate management of exposure and risk. Includes functionality for custom stop levels (SL/TP), lot size calculation, breakeven, and profit zone management.
- **Custom Actions**: Define custom actions for entry, confirmation and exit models.
- **Custom Session**: Define custom trading sessions based on minute, hour, day of the week, and month ranges to specify when actions must be considered valid.
- **Modularity**: Given structure is highly customisable for decision tree trading model creation. Build on the structure by setting together different actions with different signal models, explore other options.

## Folder Structure

The repository contains the following folders:

- **MQL4**
  - **Experts**: Contains expert advisors. Is considered as the **main** file and created seperate for each trading model. 
  - **Include**: Contains main backend logic and pre-defined modules. 
  - **Indicators**: Contains custom mathematical models.

## Getting Started

0. **Add MQL4 to terminal folder**: Can be copied on same level as `\MQL4` or with each folder added seperately. 

1. **Adjust the Model**: Open the main file  `Experts\Example.mq4` and adjust the strategy parameters according to your needs. The main parameters include risk per trade, stop-loss and take-profit ratios, session ranges, and more.
```mql4
// Strategy name - version
extern string strategy_name = "Example";

// Backtest externs for optimization
extern bool fixed_sltp = false;
extern int slippage = 3;
extern int ATR_period = 14;
extern double SL_ratio = 1.5;
extern double TP_ratio = 3.0;
extern double breakeven = 0.5;
extern double profit_zone = 0.9;
extern double profit_zone_reward = 0.2;
extern double risk_per_trade = 1.0;

// Action model externs
extern int linreg_period = 60;
extern int linreg_price = 0;

// Action model externs
extern int ema_period = 200;
extern int ema_price = 7;
```
2. **Customize Sessions**: Customize the session ranges in the `CustomSession` class to define when trading signals are valid.

```mql4
   customSession = new CustomSession();
   customSession.addMinuteRange(0, 59, OPEN_BOTH); // Min 0, Max 59
   customSession.addHourRange(2, 22, OPEN_BOTH); // Min 0, Max 23
   customSession.addDayOfWeekRange(1, 7, OPEN_BOTH); // Min 1, Max 7
   customSession.addMonthRange(1, 12, OPEN_BOTH); // Min 1, Max 12
   customSession.setPositionLimit(10, PERIOD_D1); // Support only H1, D1 and MN
```
3. **Customise actions**: Explore options for custom action models or use predefined.

```mql4
OrderAction linear_reg_Simple(int lr_period, int lr_price) {
  OrderAction signal = OA_IGNORE;

  double lr_Buy = iCustom(NULL, 0, "linear-regression", lr_period, lr_price, 0, 1, 1);
  double lr_Sell = iCustom(NULL, 0, "linear-regression", lr_period, lr_price, 0, 2, 1);
  double lr_BuyPrev = iCustom(NULL, 0, "linear-regression", lr_period, lr_price, 0, 1, 2);
  double lr_SellPrev = iCustom(NULL, 0, "linear-regression", lr_period, lr_price, 0, 2, 2);

  if (LongCrossOverEmptyValue(lr_Buy, lr_SellPrev)) signal = OA_OPEN_LONG;
  if (ShortCrossOverEmptyValue(lr_Sell,  lr_BuyPrev)) signal = OA_OPEN_SHORT;
  return signal; 
}
```

```mql4
   OrderAction action = linear_reg_Simple(linreg_period, linreg_price);

   OrderAction confirm = EMA_Baseline(ema_period, ema_price);
```

4. **Compile and Deploy**: Compile your expert advisor in MetaEditor and deploy it to MetaTrader 4 for testing or live trading.

## Adjusting the Model

### Customizing Strategy Parameters

In the main file (`Experts/your_strategy.mq4`), you'll find various strategy parameters that you can adjust according to your trading strategy:

- `riskPerTrade`: Set the percentage of account balance to risk per trade.
- `SLRatio`: Set the stop-loss ratio relative to the average true range (ATR) for risk management.
- `TPRatio`: Set the take-profit ratio relative to the stop-loss level for risk management.
- `breakevenZone`: Set the breakeven zone as a percentage of the take-profit level.
- `profitZone`: Set the profit zone as a percentage of the take-profit level.
- `profitRatio`: Set the profit ratio to determine the profit zone stop-loss level.
- `ATRPeriod`: Set the period for calculating the average true range (ATR) indicator.

### Customizing Session Ranges

In the `CustomSession` class, you can customize session ranges based on minute, hour, day of the week, and month to define when trading signals should be considered valid.

### Customizing Risk Management Parameters

In the `RiskManager` class, you can customize risk management parameters such as stop-loss and take-profit levels, lot size calculation, breakeven, and profit zone management.

## Contribution

Public repository contains more/less up-to-date code we use for our research and development. Difference is that this repo is stripped of all research, custom connections and other findings.
Ideas are welcome, but we encourage you to build and test systems rather than re-work the code. MetaTrader 4 is sort of a legacy system and we're looking ahead for OFramework5 release. 

We have developed great systems with OFramework4 and we hope you will too. 

## License

This project is licensed under the [GNU General Public License v3.0](LICENSE).

