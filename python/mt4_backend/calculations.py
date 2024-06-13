import polars as pl


def add_balance_column(positions: list[dict], start_balance: float) -> pl.DataFrame:
    pos_df = pl.DataFrame(positions)
    pos_df = pos_df.with_columns(
        pl.col("close_time").str.to_datetime(format="%Y.%m.%d %H:%M:%S"),
        (pl.col("net_profit").cumsum() + start_balance).alias("balance")
    )
    return pos_df


def balance_stats(backtest: dict, positions: pl.DataFrame):
    start_balance = backtest["account_balance"]
    final_balance = round(start_balance + positions.select(pl.col("net_profit").sum()).to_numpy()[0][0], 2)

    pos_profit_sum = positions.filter(pl.col('net_profit') > 0)['net_profit'].sum()
    neg_profit_sum = abs(positions.filter(pl.col('net_profit') < 0)['net_profit'].sum())
    if neg_profit_sum == 0 or pos_profit_sum == 0:
        profit_factor = 0
    else:
        profit_factor = round(pos_profit_sum / neg_profit_sum, 2)

    net_profit = abs(positions.select(
        pl.when(pl.col('net_profit') == 0.0).then(0.01).otherwise(pl.col('net_profit')).alias('net_profit')
    )['net_profit'].sum())
    net_profit = 0.01 if net_profit == 0 else net_profit
    transaction_cost = round(
        (positions['commission'].sum() + positions['swap'].sum()) / abs(net_profit) * 100, 2
    )

    return {
        "start_balance": start_balance,
        "final_balance": final_balance,
        "min_balance": positions['balance'].min(),
        "max_balance": positions['balance'].max(),
        "net_profit": round(final_balance - start_balance, 2),
        "net_profit_percent": round(((final_balance / start_balance - 1) * 100), 2),
        "profit_factor": profit_factor,
        "trans_cost_percent": transaction_cost
    }


def drawdown_stats(backtest: dict, positions: pl.DataFrame):
    if positions.shape[0] == 0:
        return {
            "avg_drawdown": 0,
            "max_drawdown": 0,
            "min_drawdown": 0,
            "avg_dd_duration": 0,
            "max_dd_duration": 0,
            "min_dd_duration": 0,
            "max_drawdown_duration": 0
        }
    datetime = pl.concat([
        pl.Series([backtest["date_from"]]).str.to_datetime(format="%Y.%m.%d %H:%M:%S"),
        positions['close_time']
    ])

    # datetime = datetime.str.to_datetime(format="%Y.%m.%d %H:%M:%S")
    balance = pl.concat([
        pl.Series([backtest["account_balance"]]),
        positions['balance']
    ]).alias("balance")
    cummax = balance.cummax()
    dd_abs = balance - cummax
    dd_rel = ((dd_abs / cummax) * 100).round(2)

    dd_df = pl.DataFrame({
        "datetime": datetime,
        "balance": balance,
        "cummax": cummax,
        "dd_abs": dd_abs,
        "dd_rel": dd_rel,
        "group": (dd_abs == 0).cast(pl.UInt32).cumsum()
    })

    group_df = dd_df.groupby("group").agg(
        pl.col("datetime").first().alias("start_dt"),
        pl.col("datetime").last().alias("end_dt"),
        (pl.col("datetime").last() - pl.col("datetime").first()).alias("duration"),
        pl.col("balance").first().alias("start_balance"),
        pl.col("balance").last().alias("end_balance"),
        pl.col("cummax").last().alias("max_balance"),
        pl.col("dd_abs").min().alias("dd_abs"),
        pl.col("dd_rel").min().alias("dd_rel"),
        pl.col("balance").count().alias("trade_count")
    )
    group_df = group_df.filter(pl.col("dd_rel") < 0)

    group_dd = group_df['dd_rel']
    group_duration = group_df['duration']

    return {
        "avg_drawdown": round(group_dd.mean(), 2),
        "max_drawdown": round(group_dd.min(), 2),
        "min_drawdown": round(group_dd.max(), 2),
        "avg_dd_duration": int(group_duration.mean().total_seconds()),
        "max_dd_duration": int(group_duration.max().total_seconds()),
        "min_dd_duration": int(group_duration.min().total_seconds()),
        "max_drawdown_duration": group_df.filter(pl.col("dd_rel") == group_dd.min())['duration'].max().total_seconds()
    }


def trade_stats(positions: pl.DataFrame):
    if positions.shape[0] == 0:
        return {
            "total_trades": 0,
            "long_trades": 0,
            "short_trades": 0,
            "long_wins": 0,
            "short_wins": 0,
            "long_wr": 0,
            "short_wr": 0,
            "long_pf": 0,
            "short_pf": 0,
            "win_rate": 0,
            "breakeven_wr": 0
        }
    total_trades = positions['type'].count()
    # position types: 0 - long, 1 - short
    long_trades = positions.filter(pl.col('type') == 0)['type'].count()
    short_trades = positions.filter(pl.col('type') == 1)['type'].count()

    long_wins = positions.filter((pl.col('type') == 0) & (pl.col('net_profit') > 0))['type'].count()
    short_wins = positions.filter((pl.col('type') == 1) & (pl.col('net_profit') > 0))['type'].count()

    long_wr = round(long_wins / long_trades * 100, 2)
    short_wr = round(short_wins / short_trades * 100, 2)

    long_pf = round(
        positions.filter((pl.col('type') == 0) & (pl.col('net_profit') > 0))['net_profit'].sum() /
        abs(positions.filter((pl.col('type') == 0) & (pl.col('net_profit') < 0))['net_profit'].sum()),
        2
    )

    short_pf = round(
        positions.filter((pl.col('type') == 1) & (pl.col('net_profit') > 0))['net_profit'].sum() /
        abs(positions.filter((pl.col('type') == 1) & (pl.col('net_profit') < 0))['net_profit'].sum()),
        2
    )

    win_rate = round((long_wins + short_wins) / total_trades * 100, 2)
    # breakeven_wr = round(positions.filter(pl.col('net_profit') == 0)['net_profit'].count() / total_trades * 100, 2)

    return {
        "total_trades": total_trades,
        "long_trades": long_trades,
        "short_trades": short_trades,
        "long_wins": long_wins,
        "short_wins": short_wins,
        "long_wr": long_wr,
        "short_wr": short_wr,
        "long_pf": long_pf,
        "short_pf": short_pf,
        "win_rate": win_rate,
        "breakeven_wr": 0  # TODO: need to read from backtest.inputs SL and TP values
    }


def consecutive_stats(positions: pl.DataFrame):
    if positions.shape[0] == 0:
        return {
            "max_cons_wins": 0,
            "avg_cons_wins": 0,
            "max_cons_w_duration": 0,
            "avg_cons_w_duration": 0,

            "max_cons_losses": 0,
            "avg_cons_losses": 0,
            "max_cons_l_duration": 0,
            "avg_cons_l_duration": 0
        }
    cons_df = positions.with_columns(
        pl.col("close_time").alias("dt"),
        pl.col('gross_profit').gt(0).cast(pl.UInt32).alias('win'),
        pl.col('gross_profit').lt(0).cast(pl.UInt32).alias('loss'),
    )
    cons_df = cons_df.with_columns(
        pl.col('win').cumsum().alias('win_count'),
        pl.col('loss').cumsum().alias('loss_count')
    )
    loss_starts = cons_df['loss'].diff().fill_null(0) != 0
    group_id = loss_starts.cumsum()

    loss_df = pl.DataFrame({"dt": cons_df["dt"], "data": cons_df['loss'], "group_id": group_id})
    loss_df = loss_df.with_columns(
        pl.when(loss_df["data"] == 1)
        .then(pl.col("data").cumsum().over("group_id"))
        .otherwise(0)
        .alias("sequence")
    ).filter(pl.col("data") == 1)

    loss_results = loss_df.groupby("group_id").agg(
        pl.col("sequence").max().alias("max_loss"),
        (pl.col("dt").last() - pl.col("dt").first()).alias("duration")
    )

    win_df = pl.DataFrame({"dt": cons_df["dt"], "data": cons_df['win'], "group_id": group_id})
    win_df = win_df.with_columns(
        pl.when(win_df["data"] == 1)
        .then(pl.col("data").cumsum().over("group_id"))
        .otherwise(0)
        .alias("sequence")
    ).filter(pl.col("data") == 1)

    win_results = win_df.groupby("group_id").agg(
        pl.col("sequence").max().alias("max_win"),
        (pl.col("dt").last() - pl.col("dt").first()).alias("duration")
    )
    max_wins = win_results.filter(pl.col("max_win") == win_results["max_win"].max())
    max_losses = loss_results.filter(pl.col("max_loss") == loss_results["max_loss"].max())
    return {
        "max_cons_wins": cons_df['win_count'].max(),
        "avg_cons_wins": round(win_results['max_win'].mean(), 2),
        "max_cons_w_duration": int(max_wins['duration'].mean().total_seconds()),
        "avg_cons_w_duration": int(win_results['duration'].mean().total_seconds()),

        "max_cons_losses": cons_df['loss_count'].max(),
        "avg_cons_losses": round(loss_results['max_loss'].mean(), 2),
        "max_cons_l_duration": int(max_losses['duration'].mean().total_seconds()),
        "avg_cons_l_duration": int(loss_results['duration'].mean().total_seconds()),
    }


def get_stats(backtest: dict, positions: pl.DataFrame):
    return {
        "balance_stats": balance_stats(backtest, positions),
        "drawdown_stats": drawdown_stats(backtest, positions),
        "trade_stats": trade_stats(positions),
        "consecutive_stats": consecutive_stats(positions),
    }


def calculate_stats(backtest: dict, positions: list[dict]):
    position_df = add_balance_column(positions, backtest["account_balance"])

    overall_stats = get_stats(backtest, position_df)

    yearly_stats = []
    for year in position_df["close_time"].dt.year().unique():
        yearly_stats.append(
            {f"{year}": get_stats(backtest, position_df.filter(pl.col('close_time').dt.year() == year))})

    monthly_stats = []
    position_df = position_df.with_columns(
        pl.datetime(pl.col('close_time').dt.year(), pl.col('close_time').dt.month(), 1).alias("month_start")
    )

    for month in position_df["month_start"].unique():
        month_df = position_df.filter(pl.col('month_start') == month)
        if month_df.shape[0] != 0:
            monthly_stats.append(
                {month.strftime('%Y-%m-%d'): get_stats(backtest, position_df.filter(
                    pl.col('close_time').dt.month_start() == month))})

    return {
        "overall": overall_stats,
        "yearly": yearly_stats,
        "monthly": monthly_stats
    }
