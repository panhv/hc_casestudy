from pathlib import Path

BASE_DIR = Path(__file__).resolve().parents[1]

EXCEL_PATH = BASE_DIR / "data" / "raw" / "Business_Analyst_Media_Testdaten.xlsx"
DB_PATH = BASE_DIR / "data" / "processed" / "hc_analysis.duckdb"

SQL_DIR = BASE_DIR / "sql"

OUTPUT_DIR = BASE_DIR / "outputs" / "csv"
OUTPUT_FIG_DIR = BASE_DIR / "outputs" / "figures"

SHEETS = {
    "campaign": "campaign_performance",
    "bookings": "booking_data",
    "hotels": "hotel_information",
}