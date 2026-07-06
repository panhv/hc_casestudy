### HolidayCheck Business Analyst Media Case Study

Dieses Projekt ist die Abgabe zur Case Study bei HolidayCheck für die Position Business Analyst Media. 

Unter README_workbook.md werden die jeweiligen Aufgaben ausführlich beantwortet.

Außerdem habe ich als Extra einen Miniminimini-Chatbot erstellt, der regelbasiert arbeitet und Nutzerfragen mit bestimmten SQL-Abfragen verknüpft. 

**Was macht welches .py-Skript?**

1. config.py: Konfigurations Datei, gibt Pfade an
2. extract.py: Funktion zum Extrahieren der Excel-Datei und deren Sheets und gibt sie als pandas Dataframes zurück
3. transform.py: Funktionen zur Vereinheitlichung des Datensatzes. Identifiziert Duplicates, Missing Values, Negative Values oder Invalids
4. load.py: Stellt Verbindung zu DuckDB her und erstellt die Datenbank under Anwendung der config.py, extract.py und transform.py
5. run_sql_queries.py: Ausführung der SQL-Abfragen. Erstellt eine .csv-Datei
6. visualization.py: Skript für die Plots
7. run_visualization.py: Ausführung des Skriptes für die Plots
8. chatbot_app.py: Backend-Datei für die Chatbot-UI
9. chatbot_streamlit.py: Einfache Chatbot-UI

