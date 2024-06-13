string insertBacktestQuery(
    string strategyName, string inputJson, string sessionLimits, double accountStartBalance, string dateFrom
) {
    int isOptimization = (int)IsOptimization();
    int isTest = (int)IsTesting();

    string dateTo = getCurrentDateTime();
    string accountCurrency = AccountInfoString(ACCOUNT_CURRENCY);

    string query = "INSERT INTO backtests_raw";
    StringAdd(query, " (strategy_name, inputs, session_limits, symbol, period, account_currency, account_balance, date_from, date_to, is_optimization, is_test)");
    string valueStr = StringFormat(" VALUES ('%s', '%s', '%s', '%s', %d, '%s', %f, '%s', '%s', %d, %d)",
                                   strategyName, inputJson, sessionLimits, Symbol(), Period(), accountCurrency, accountStartBalance, dateFrom, dateTo, isOptimization, isTest);
    StringAdd(query, valueStr);
    return query;
}

string insertPositionsQuery(int btRawId) {
    string query = "INSERT INTO positions";
    StringAdd(query, " (bt_raw_id, type, order_number, open_time, close_time, lot_size, open_price, close_price, sl_price, tp_price, net_profit, gross_profit, commission, swap) VALUES ");
    int historyTotal = OrdersHistoryTotal();
    for (int i = 0; i < historyTotal; i++) {
        if (OrderSelect(i, SELECT_BY_POS, MODE_HISTORY)) {
            string openTime = getStrDateTime(OrderOpenTime());
            string closeTime = getStrDateTime(OrderCloseTime());

            double lotSize = NormalizeDouble(OrderLots(), 2);
            double openPrice = NormalizeDouble(OrderOpenPrice(), Digits);
            double closePrice = NormalizeDouble(OrderClosePrice(), Digits);
            double slPrice = NormalizeDouble(OrderStopLoss(), Digits);
            double tpPrice = NormalizeDouble(OrderTakeProfit(), Digits);

            double grossProfit = NormalizeDouble(OrderProfit(), 2);
            double commission = NormalizeDouble(OrderCommission(), 2);
            double swap = NormalizeDouble(OrderSwap(), 2);
            double netProfit = NormalizeDouble(grossProfit + commission + swap, 2);

            string position = StringFormat("(%d, %d, %d, '%s', '%s', %f, %f, %f, %f, %f, %f, %f, %f, %f)",
                                             btRawId, OrderType(), OrderTicket(), openTime, closeTime, lotSize, openPrice, closePrice, slPrice, tpPrice, netProfit, grossProfit, commission, swap);

            if (i < historyTotal - 1) {
                StringAdd(position, ", ");
            }
            StringAdd(query, position);
        }
    }
    StringAdd(query, ";");
    return query;
}

string getStrDateTime(datetime dt) {
    return TimeToStr(dt, TIME_DATE | TIME_SECONDS);
}

string getCurrentDateTime() {
    return getStrDateTime(iTime(Symbol(), Period(), 0));
}


