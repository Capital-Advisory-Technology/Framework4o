import json
import sqlite3
import time

import pandas as pd
import polars as pl
import keyboard

from pywinauto import Desktop, mouse, findwindows

# from calculations import calculate_stats


def copy_optimization_results() -> pd.DataFrame:
    window_class = "MetaQuotes::MetaTrader::4.00"

    try:
        desktop = Desktop(backend="uia")
        window = desktop.window(class_name=window_class)
        window.set_focus()

        # Click on the "Optimization Results" tab
        window_rect = window.rectangle()
        click_x = window_rect.left + 150
        click_y = window_rect.bottom - 40
        mouse.click(coords=(click_x, click_y))
        time.sleep(0.5)

        # Access the optimization result table
        list_view = window.child_window(class_name="SysListView32", found_index=0)
        mouse.click(coords=list_view.rectangle().mid_point())
        time.sleep(0.1)

        # Copy results
        keyboard.press_and_release("alt+a")
        time.sleep(0.1)
        # results = paste()

        return pd.read_clipboard(sep="\t", dtype_backend="pyarrow")

    except findwindows.ElementNotFoundError:
        print("MetaTrader 4 window not found.")


def parse_number(number: str) -> int | float | str:
    number = number.strip()
    if number.isnumeric():
        return int(number)
    elif "." in number:
        return float(number)
    return number


def clean_results(df: pd.DataFrame) -> pd.DataFrame:
    stats = df.iloc[:, 0:7]
    stats.columns = ["pass", "profit", "trades", "profit_factor", "expected_payoff", "drawdown", "drawdown_percent"]
    stats.drawdown_percent = stats.drawdown_percent.str.rstrip("%").astype(float)

    inputs = df.iloc[:, 7:]
    input_results = []

    for row in inputs.itertuples(index=False):
        new_row = {}
        for input in row:
            if isinstance(input, str):
                key, value = input.split("=")
                new_row[key] = parse_number(value)

        input_results.append(json.dumps(new_row))

    stats["inputs"] = input_results
    return stats


def get_backtests() -> pl.DataFrame:
    # TODO: Change path to dynamic 
    FILE_PATH = r"C:\Users\you\AppData\Roaming\MetaQuotes\Terminal\3ECBA7B376E7B0171B098071238161DA\MQL4\Files\mt4_backtests.db"
    con = sqlite3.connect(FILE_PATH)
    query = "SELECT * FROM backtests_raw where is_processed = 0"
    return pd.read_sql(query, con)


def main():
    # raw_results = copy_optimization_results()
    # raw_results.to_csv("raw_results.csv", index=False)
    raw_results = pd.read_csv("raw_results.csv", header=None, dtype_backend="pyarrow")

    stats_df = clean_results(raw_results)
    bt_df = get_backtests()

    raw_df = pd.merge(
        stats_df, bt_df,
        on=['profit', 'trades', 'profit_factor', 'expected_payoff', 'drawdown', 'drawdown_percent'],
        how='inner'
    )
    # result_df = calculate_stats(raw_df)
    print(bt_df)


if __name__ == "__main__":
    pd.set_option("display.width", None)
    main()
