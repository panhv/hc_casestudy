import pandas as pd
from pathlib import Path

from config import DB_PATH, EXCEL_PATH, SHEETS

# function to load data from excel file and return pandas dataframes
def load_data_from_excel(excel_path: Path, sheets: dict) -> tuple[pd.DataFrame, pd.DataFrame, pd.DataFrame]:
    if not EXCEL_PATH.exists():  
        raise FileNotFoundError(f"Excel-Datei nicht gefunden: {EXCEL_PATH}")  

    DB_PATH.parent.mkdir(parents=True, exist_ok=True) 

    excel_file = pd.ExcelFile(EXCEL_PATH) 

    campaign = pd.read_excel(excel_file, sheet_name=SHEETS["campaign"]) 
    bookings = pd.read_excel(excel_file, sheet_name=SHEETS["bookings"])  
    hotels = pd.read_excel(excel_file, sheet_name=SHEETS["hotels"]) 

    print(f"Gefundene Excel-Sheets:{SHEETS}") 

    return campaign, bookings, hotels
