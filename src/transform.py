import pandas as pd
import numpy as np


### function to convert column names to lower case and replace/remove spaces with underscores
def clean_column_names(df: pd.DataFrame) -> pd.DataFrame: 
    df = df.copy()  
    df.columns = (  
        df.columns  
        .str.strip() 
        .str.lower()  
        .str.replace(" ", "_", regex=False)
        .str.replace("traveltype", "travel_type", regex=False)
    )  
    return df  

### function to transform dataframes: clean column names, convert date columns to datetime format, convert identifiers to string format, normalize categorical values
def transform_data(campaign: pd.DataFrame, bookings: pd.DataFrame, hotels: pd.DataFrame) -> tuple[pd.DataFrame, pd.DataFrame, pd.DataFrame]:

    # clean column names
    campaign = clean_column_names(campaign)  
    bookings = clean_column_names(bookings)  
    hotels = clean_column_names(hotels)  

    # convert date columns to datetime format
    campaign["date"] = pd.to_datetime(campaign["date"], errors="coerce").dt.date
    bookings["booking_date"] = pd.to_datetime(bookings["booking_date"], errors="coerce").dt.date 
    
    # convert identifiers to string format
    ids_to_string = ["campaign_id", "hotel_id", "booking_id", "hotel_category", "campaign_type", "travel_type"]

    for df in [campaign, bookings, hotels]:
        for col in ids_to_string:
            if col in df.columns: 
                df[col] = df[col].astype("string")

    # normalize categorical values
    campaign["campaign_type"] = campaign["campaign_type"].str.strip().str.title()
    bookings["travel_type"] = bookings["travel_type"].str.strip().str.title()
    hotels["hotel_category"] = hotels["hotel_category"].str.strip().str.title()

    return campaign, bookings, hotels

# function for quality checks
def run_quality_checks(campaign: pd.DataFrame, bookings: pd.DataFrame, hotels: pd.DataFrame) -> tuple[pd.DataFrame, pd.DataFrame, pd.DataFrame]:
    print("\n" + "="*40 + "\n START QUALITY CHECKS \n" + "="*40)

    # show missing values in each table
    for name, df in [("CAMPAIGN", campaign), ("BOOKINGS", bookings), ("HOTELS", hotels)]:
        print(f"\nMissing Values in {name}:")
        print(df.isna().sum()[df.isna().sum() > 0]) # Zeigt nur Spalten mit Fehlwerten

    # check for duplicates of booking_id in booking_data
    print(f"\nDUPLICATES in booking_id")
    print(bookings["booking_id"].duplicated().sum())

    # check for negative values in clicks, leads, cost and revenue columns
    # if negative values are found, set them to 0 or NaN and print a warning
    if "cost" in campaign.columns:
        negative_costs = campaign["cost"] <= 0
        print(f"\nRows with negative or 0 costs (cost <= 0): {negative_costs.sum()}")
        if negative_costs.sum() > 0:
            campaign.loc[negative_costs, "cost"] = 0.0  # or np.nan

    if "revenue" in bookings.columns:
        negative_revenue = bookings["revenue"] <= 0
        print(f"Rows with negative revenue (revenue <= 0): {negative_revenue.sum()}")
        if negative_revenue.sum() > 0:
            bookings.loc[negative_revenue, "revenue"] = 0.0  # or np.nan

    if "clicks" in campaign.columns:
        negative_clicks = campaign["clicks"] <= 0
        print(f"Rows with negative or 0 clicks (clicks <= 0): {negative_clicks.sum()}")
        if negative_clicks.sum() > 0:
            campaign.loc[negative_clicks, "clicks"] = 0.0  # or np.nan
    
    if "leads" in campaign.columns:
        negative_leads = campaign["leads"] <= 0
        print(f"Rows with negative or 0 leads (leads <= 0): {negative_leads.sum()}")
        if negative_leads.sum() > 0:
            campaign.loc[negative_leads, "leads"] = 0.0  # or np.nan

    # plausibility check: impressions >= clicks >= leads
    # if clicks > impressions or leads > clicks, set to NaN and print a warning
    invalid_clicks = campaign["clicks"] > campaign["impressions"]
    print(f"\nInvalid clicks (Clicks > Impressions): {invalid_clicks.sum()}")
    campaign.loc[invalid_clicks, "clicks"] = np.nan

    invalid_leads = campaign["leads"] > campaign["clicks"]
    print(f"\nInvalid leads (Leads > Clicks): {invalid_leads.sum()}")
    campaign.loc[invalid_leads, "leads"] = np.nan

    # check for mismatched hotel_ids in campaign and bookings based on hotels
    valid_hotel_ids = set(hotels["hotel_id"])

    unknown_campaign = campaign[~campaign["hotel_id"].isin(valid_hotel_ids)]
    print(f"\nUnknown hotel_ids in campaign_performance: {len(unknown_campaign)}")

    unknown_bookings = bookings[~bookings["hotel_id"].isin(valid_hotel_ids)]
    print(f"Unknown hotel_ids in booking_data: {len(unknown_bookings)}")
    
    print("\n" + "="*40 + "\n QUALITY CHECKS COMPLETED \n" + "="*40)
    print("\n")
    return campaign, bookings, hotels

# function to print summary
def print_summary(campaign: pd.DataFrame, bookings: pd.DataFrame, hotels: pd.DataFrame) -> None:
    print(campaign.info())  
    print(bookings.info())  
    print(hotels.info()) 

    print("\nZeilen") 
    print(f" - campaign_performance: {len(campaign)}")
    print(f" - booking_data: {len(bookings)}")
    print(f" - hotel_information: {len(hotels)}")