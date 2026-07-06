import pandas as pd
import duckdb

from config import DB_PATH, EXCEL_PATH, SHEETS
from extract import load_data_from_excel
from transform import print_summary, run_quality_checks, transform_data

### function to connect to duckdb
def get_connection():
    return duckdb.connect(str(DB_PATH))

### function to connect to duckdb and register pandas dataframes as tables
def register_df_to_duckdb(campaign: pd.DataFrame, bookings: pd.DataFrame, hotels: pd.DataFrame, db_path: str) -> None:
    with duckdb.connect(str(db_path)) as con:  

        # register
        con.register("campaign_df", campaign) 
        con.register("booking_df", bookings)  
        con.register("hotel_df", hotels)

        # create or replace tables
        con.execute("CREATE OR REPLACE TABLE campaign_performance AS SELECT * FROM campaign_df")
        con.execute("CREATE OR REPLACE TABLE booking_data AS SELECT * FROM booking_df")
        con.execute("CREATE OR REPLACE TABLE hotel_information AS SELECT * FROM hotel_df")

        # create indeces on hotel_id for faster joins
        con.execute("CREATE INDEX IF NOT EXISTS idx_campaign_hotel_id ON campaign_performance(hotel_id)")
        con.execute("CREATE INDEX IF NOT EXISTS idx_booking_hotel_id ON booking_data(hotel_id)")
        con.execute("CREATE INDEX IF NOT EXISTS idx_hotel_hotel_id ON hotel_information(hotel_id)")

    print("\n")
    print("Data successfully registered in DuckDB and tables created.")


def main() -> None: 
    # extract
    campaign, bookings, hotels = load_data_from_excel(EXCEL_PATH, SHEETS)

    # transform
    campaign, bookings, hotels = transform_data(campaign, bookings, hotels)
    campaign, bookings, hotels = run_quality_checks(campaign, bookings, hotels)

    # print summary
    print("Summary of the transformed data:")
    print_summary(campaign, bookings, hotels)
    
    # load
    register_df_to_duckdb(campaign, bookings, hotels, DB_PATH)

if __name__ == "__main__": 
    main()  