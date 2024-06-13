DROP TABLE IF EXISTS position_types;
CREATE TABLE IF NOT EXISTS position_types
(
    id    INTEGER PRIMARY KEY,
    value INTEGER NOT NULL,
    name  TEXT    NOT NULL
);

INSERT INTO position_types (value, name)
VALUES (0, 'Long'),
       (1, 'Short');


DROP TABLE IF EXISTS periods;
CREATE TABLE IF NOT EXISTS periods
(
    period_id INTEGER PRIMARY KEY,
    value     INTEGER NOT NULL,
    name      TEXT    NOT NULL
);
INSERT INTO periods (value, name)
VALUES (1, 'M1')
     , (5, 'M5')
     , (10, 'M10')
     , (15, 'M15')
     , (30, 'M30')
     , (60, 'H1')
     , (240, 'H4')
     , (1440, 'DAY')
     , (7200, 'WEEK')
     , (28800, 'MONTH')
;

DROP TABLE IF EXISTS symbols;
CREATE TABLE IF NOT EXISTS symbols
(
    symbol_id INTEGER PRIMARY KEY,
    name      TEXT    NOT NULL,
    base      TEXT    NOT NULL,
    exchange  TEXT    NOT NULL,
    digits    INTEGER NOT NULL
);

INSERT INTO symbols (name, base, exchange, digits)
VALUES ('AUDCAD', 'AUD', 'CAD', 5)
     , ('AUDCHF', 'AUD', 'CHF', 5)
     , ('AUDJPY', 'AUD', 'JPY', 3)
     , ('AUDNZD', 'AUD', 'NZD', 5)
     , ('AUDUSD', 'AUD', 'USD', 5)
     , ('CADCHF', 'CAD', 'CHF', 5)
     , ('CADJPY', 'CAD', 'JPY', 3)
     , ('CHFJPY', 'CHF', 'JPY', 3)
     , ('EURAUD', 'EUR', 'AUD', 5)
     , ('EURCAD', 'EUR', 'CAD', 5)
     , ('EURCHF', 'EUR', 'CHF', 5)
     , ('EURGBP', 'EUR', 'GBP', 5)
     , ('EURJPY', 'EUR', 'JPY', 3)
     , ('EURNZD', 'EUR', 'NZD', 5)
     , ('EURUSD', 'EUR', 'USD', 5)
     , ('GBPAUD', 'GBP', 'AUD', 5)
     , ('GBPCAD', 'GBP', 'CAD', 5)
     , ('GBPCHF', 'GBP', 'CHF', 5)
     , ('GBPJPY', 'GBP', 'JPY', 3)
     , ('GBPNZD', 'GBP', 'NZD', 5)
     , ('GBPUSD', 'GBP', 'USD', 5)
     , ('NZDCAD', 'NZD', 'CAD', 5)
     , ('NZDCHF', 'NZD', 'CHF', 5)
     , ('NZDJPY', 'NZD', 'JPY', 3)
     , ('NZDUSD', 'NZD', 'USD', 5)
     , ('USDCAD', 'USD', 'CAD', 5)
     , ('USDCHF', 'USD', 'CHF', 5)
     , ('USDJPY', 'USD', 'JPY', 3)
;

DROP TABLE IF EXISTS backtests_raw;
CREATE TABLE IF NOT EXISTS backtests_raw
(
    bt_raw_id        INTEGER PRIMARY KEY,
    symbol           TEXT NOT NULL,
    period           INTEGER NOT NULL,
    account_currency TEXT    NOT NULL,
    account_balance  REAL    NOT NULL,
    date_from        INTEGER NOT NULL,
    date_to          INTEGER NOT NULL,

    strategy_name    TEXT    NOT NULL,
    inputs           TEXT    NOT NULL,
    session_limits   TEXT    NOT NULL,

    is_optimization  INTEGER NOT NULL,
    is_test          INTEGER NOT NULL,
    is_processed     INTEGER NOT NULL DEFAULT 0
    -- entry_list        TEXT    NOT NULL,
    -- exit_list         TEXT    NOT NULL,
    -- confirmation_list TEXT    NOT NULL,

);

DROP TABLE IF EXISTS positions;
CREATE TABLE IF NOT EXISTS positions
(
    id           INTEGER PRIMARY KEY,
    bt_raw_id    INTEGER NOT NULL,
    type         INT     NOT NULL,
    order_number INTEGER NOT NULL,
    open_time    TEXT    NOT NULL,
    close_time   TEXT    NOT NULL,
    lot_size     REAL    NOT NULL,
    open_price   REAL    NOT NULL,
    close_price  REAL    NOT NULL,
    sl_price     REAL    NOT NULL,
    tp_price     REAL    NOT NULL,
    gross_profit REAL    NOT NULL,
    net_profit   REAL    NOT NULL,
    commission   REAL    NOT NULL,
    swap         REAL    NOT NULL,

    FOREIGN KEY (bt_raw_id) REFERENCES backtests_raw (bt_raw_id) ON DELETE CASCADE
);

DROP TABLE IF EXISTS strategies;
CREATE TABLE IF NOT EXISTS strategies
(
    strategy_id     INTEGER PRIMARY KEY,
    name            TEXT NOT NULL UNIQUE
);

DROP TABLE IF EXISTS backtests;
CREATE TABLE IF NOT EXISTS backtests
(
    bt_id            INTEGER PRIMARY KEY,
    strategy_id      INTEGER NOT NULL,
    bt_raw_id        INTEGER NOT NULL,
    symbol_id        INTEGER NOT NULL,
    period_id        INTEGER NOT NULL,
    account_currency TEXT    NOT NULL,
    inputs           TEXT    NOT NULL,

    UNIQUE (bt_raw_id, strategy_id, symbol_id, period_id, account_currency, inputs),
    FOREIGN KEY (bt_raw_id) REFERENCES backtests_raw (bt_raw_id) ON DELETE CASCADE,
    FOREIGN KEY (strategy_id) REFERENCES strategies (strategy_id)  ON DELETE CASCADE,
    FOREIGN KEY (symbol_id) REFERENCES symbols (symbol_id) ON DELETE CASCADE,
    FOREIGN KEY (period_id) REFERENCES periods (period_id) ON DELETE CASCADE
);

DROP TABLE IF EXISTS backtests_stats;
CREATE TABLE IF NOT EXISTS backtests_stats
(
    bt_stats_id     INTEGER PRIMARY KEY,
    bt_id           INTEGER NOT NULL,

    date_from       INTEGER NOT NULL,
    date_to         INTEGER NOT NULL,

    overall_stats   TEXT    NOT NULL,
    yearly_stats    TEXT    NOT NULL,
    monthly_stats   TEXT    NOT NULL,

    is_optimization INTEGER NOT NULL,
    is_test         INTEGER NOT NULL,

    FOREIGN KEY (bt_id) REFERENCES backtests (bt_id) ON DELETE CASCADE

);


--     start_balance  REAL NOT NULL,
--     final_balance  REAL NOT NULL,
--     min_balance    REAL NOT NULL,
--     max_balance    REAL NOT NULL,
--     net_profit     REAL NOT NULL,
--     profit_factor          REAL    NOT NULL,
--     trans_cost           REAL    NOT NULL,
--     trans_cost_percent  REAL    NOT NULL,
--
--     expected_payoff        REAL    NOT NULL,
--     drawdown               REAL    NOT NULL,
--     drawdown_percent       REAL    NOT NULL,
--
--     avg_drawdown    REAL NOT NULL,
--     max_drawdown    REAL NOT NULL,
--     min_drawdown    REAL NOT NULL,
--     avg_dd_duration REAL NOT NULL,
--     max_dd_duration REAL NOT NULL,
--     min_dd_duration REAL NOT NULL,
--     max_drawdown_duration    REAL NOT NULL,
--
--     total_trades    REAL NOT NULL,
--     long_trades REAL NOT NULL,
--     short_trades    REAL NOT NULL,
--     long_wins   REAL NOT NULL,
--     short_wins  REAL NOT NULL,
--     long_wr REAL NOT NULL,
--     short_wr    REAL NOT NULL,
--     long_pf REAL NOT NULL,
--     short_pf    REAL NOT NULL,
--     win_rate    REAL NOT NULL,
--     breakeven_wr    REAL NOT NULL,
--
--     max_cons_wins REAL NOT NULL,
--     max_cons_losses REAL NOT NULL,
--     avg_cons_wins REAL NOT NULL,
--     avg_cons_losses REAL NOT NULL,
--     max_cons_l_duration REAL NOT NULL,
--     max_cons_w_duration REAL NOT NULL,
--     avg_cons_l_duration REAL NOT NULL,
--     avg_cons_w_duration REAL NOT NULL,
