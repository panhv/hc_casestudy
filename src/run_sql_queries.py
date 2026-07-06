import duckdb

from config import DB_PATH, SQL_DIR, OUTPUT_DIR 

def main() -> None: 
    if not DB_PATH.exists():  
        raise FileNotFoundError("No data found. Please run main.py first.")  

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)  

    sql_files = sorted(SQL_DIR.glob("*.sql"))  

    with duckdb.connect(str(DB_PATH)) as con:  
        for sql_file in sql_files:  
            query = sql_file.read_text(encoding="utf-8")  
            result_df = con.execute(query).fetchdf()  
            output_path = OUTPUT_DIR / f"{sql_file.stem}.csv"  
            result_df.to_csv(output_path, index=False)  
            print(f"Saved: {output_path}") 


if __name__ == "__main__":  
    main() 