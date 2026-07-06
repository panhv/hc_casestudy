from config import SQL_DIR
from load import get_connection
from visualization import plot_time_series


## function to read SQL file
def read_sql_file(filename: str) -> str:
    sql_path = SQL_DIR / filename

    if not sql_path.exists():
        raise FileNotFoundError(f"SQL-file not found: {sql_path}")

    return sql_path.read_text(encoding="utf-8")


## function to run SQL query from file and return result as pandas dataframe
def run_query_from_file(filename: str):
    query = read_sql_file(filename)

    con = get_connection()
    df = con.execute(query).fetchdf()
    con.close()

    return df


## main function to run the visualization
def main():
    monthly_df = run_query_from_file("05a_time_series_monthly.sql")
    weekly_df = run_query_from_file("05b_time_series_weekly.sql")

    plot_time_series(
        df=monthly_df,
        time_column="month",
        period_label="month",
        filename="monthly_time_series.png",
        show=False
    )

    plot_time_series(
        df=weekly_df,
        time_column="week",
        period_label="calendar week",
        filename="weekly_time_series.png",
        tick_step=10,
        show=False
    )


if __name__ == "__main__":
    main()