"""
Kleiner regelbasierter Chatbot für das HolidayCheck-Media-Projekt.

Der Bot nutzt KEINE externe KI-API. Er erkennt einfache Schlüsselwörter
in der Nutzerfrage und führt dann passende, bereits vorhandene SQL-Dateien aus.
Dadurch bleiben die Antworten nachvollziehbar und reproduzierbar.

Angepasst für die gelieferten SQL-Dateien:
01, 02a, 02b, 03a, 04a, 04b, 05a, 05b, 06a, 06b, 07a, 07b, 10 und 11.
"""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
import re
from typing import Optional

import pandas as pd


BASE_DIR = Path(__file__).resolve().parent

try:
    # if file is in same project as config.py
    from config import DB_PATH, SQL_DIR
except ImportError:
    # fallback, if bot is tested separately 
    # if sql-file exists, if not current file 
    DB_PATH = BASE_DIR / "data" / "processed" / "hc_analysis.duckdb"
    SQL_DIR = BASE_DIR / "sql" if (BASE_DIR / "sql").exists() else BASE_DIR

DB_PATH = Path(DB_PATH)
SQL_DIR = Path(SQL_DIR)


@dataclass
class BotResponse:
    """Ein einfaches Antwort-Objekt."""

    answer: str
    data: Optional[pd.DataFrame] = None


# Pro Analyse-Frage definieren wir mögliche Dateinamen.
# Die Liste enthält saubere Projektnamen und die gelieferten Exportnamen mit Versionssuffixen wie (7).
# Zusätzlich sucht find_sql_file tolerant nach gleichwertigen Namen ohne Versionssuffix.
SQL_FILES = {
    "monthly_per_hotel": [
        "01_monthly_per_hotel.sql",
    ],
    "rising_sinking_strict": [
        "02a_rising_sinking_consec.sql",
    ],
    "rising_sinking": [
        "02b_rising_sinking.sql",

    ],
    "moving_average": [
        "03_moving_average_trends.sql",
    ],

    "hotel_segments_total": [
        "04a_hotel_segments_total.sql",
    ],

    "hotel_segments_per_year": [
        "04b_hotel_segments_per_year.sql",

    ],
    "time_series_monthly": [
        "05a_time_series_monthly.sql",

    ],
    "time_series_weekly": [
        "05b_time_series_weekly.sql",

    ],
    "anomaly_total": [
        "06a_anomaly_detection_total.sql",

    ],
    "anomaly_per_year": [
        "06b_anomaly_detection_per_year.sql",

    ],
    "volatility_total": [
        "07a_volatility_total.sql",

    ],
    "volatility_by_year": [
        "07b_volatility_by_year.sql",

    ],
    "executive_summary_sql": [
        "10_executive_summary.sql",

    ],
    "hotel_18_comparison_years": [
        "11_hotel_18_comparison_years.sql",

    ],
    "hotel_18_kpi_jun_aug": [
        "11_hotel_18_kpi_jun_aug.sql",

    ],
}


HELP_TEXT = """
Ich kann dir Fragen zu folgenden Themen beantworten:

1. Monatliche Performance pro Hotel: Impressions, Clicks, Leads, Cost, CTR, CPC, Conversion Rate
2. Hotels mit steigenden Kosten und sinkenden Leads, optional streng/konsekutiv
3. 3-Monats-Moving-Average und Trends
4. Hotelsegmente insgesamt oder pro Jahr
5. Zeitreihen für Leads, Revenue und Cost, monatlich oder wöchentlich
6. Anomalien in der Performance, insgesamt oder pro Jahr
7. Top volatile Hotels, insgesamt oder pro Jahr
8. Executive Summary 2024 vs. 2025 aus SQL
9. Hotel 18: Jahresvergleich 2024/2025 und KPI-Analyse Juni bis August 2025
10. Business-Fragen: Hypothesen, zusätzliche Daten und Budget-Empfehlung

Beispiele:
- "Zeig mir die monatliche Performance pro Hotel"
- "Welche Hotels haben steigende Kosten und sinkende Leads?"
- "Gibt es Anomalien pro Jahr?"
- "Zeig mir Hotelsegmente pro Jahr"
- "Executive Summary 2024 vs 2025"
- "Hotel 18 KPI Juni August"
- "Welche Daten sollten wir zusätzlich anfordern?"
- "Soll der Kunde das Budget erhöhen?"
""".strip()


BUSINESS_ANSWERS = {
    "hypothesen": """
Mögliche Hypothesen für sinkende Leads trotz steigender Kosten:

1. Die Anzeigen werden teurer, aber nicht relevanter: CPC steigt, CTR oder Lead Rate sinken.
2. Die Zielgruppe passt nicht mehr gut zum beworbenen Hotel oder Angebot.
3. Saisonale Effekte: Nachfrage kann je nach Monat, Region oder Reisezeitraum schwanken.
4. Landingpage-Problem: Nutzer klicken, brechen aber vor der Anfrage oder Buchung ab.
5. Kampagnen-Mix hat sich verändert: Mehr Budget fließt in weniger effiziente Kampagnentypen.
6. Wettbewerb ist stärker geworden und erhöht die Werbekosten.
7. Preis, Verfügbarkeit oder Bewertungen des Hotels sind weniger attraktiv geworden.

""".strip(),
    "daten": """
Zusätzliche Daten, die ich anfordern würde:

Must Have:

| Priorität | Daten | Nutzen |
|---:|---|---|
| 1 | Budget je Kampagne, Gebotsstrategie, Tagesbudget | Um zu verstehen, ob Kostenanstieg durch Budget-/Bid-Änderungen verursacht wurde. |
| 2 | Channel / Plattform / Placement | Um ineffiziente Kanäle zu identifizieren. |
| 3 | Impression Share, Auction Insights, Wettbewerbsdaten | Um Auktionsdruck und Marktveränderungen zu erklären. |
| 4 | Landingpage Sessions, Bounce Rate, Ladezeit, Formularabbrüche | Um Lead-Verluste nach dem Klick zu erklären. |
| 5 | Tracking-Events und Consent-Daten | Um Messprobleme auszuschließen. |
| 6 | Hotelpreise, Verfügbarkeit, Angebotsdetails | Um Nachfrage- und Angebotsprobleme zu prüfen. |
| 7 | Kampagnenänderungen mit Datum | Um Anomalien konkreten Änderungen zuzuordnen. |

Nice to Have:

| Daten | Nutzen |
|---|---|
| Wetter, Ferien, Feiertage, lokale Events | Erklärung saisonaler oder regionaler Schwankungen. |
| Wettbewerberpreise | Bewertung der relativen Attraktivität des Hotelangebots. |
| Creative-Versionen und Frequenz | Identifikation von Creative Fatigue. |
| Device, Geo, Audience, Demografie | Genauere Optimierung nach Segmenten. |
| Stornoquote und finale Buchungsqualität | Leads können hoch sein, aber wirtschaftlich schlecht. |
| Customer Lifetime Value | Bessere Budgetentscheidung als nur kurzfristiger ROAS. |

""".strip(),
    "budget": """
Meine Budget-Empfehlung:

Das Werbebudget zunächst nicht erhöhen, da der Umsatz und die Buchungen gestiegen sind. Zuerst weitere KPIs heranziehen, um die sinkenden Leads zu erklären. 
Die Werbekampagne optimieren und in Hinsicht auf Kampagnetypen analysieren, z.B. welcher Typ generiert mehr Klicks und Leads und ggfs. das Budget auf bessere Placements umschichten. 
Wenn die fehlenden Informationen keinen Aufschluss darüber geben, kann das Budget für eine Testperiode unter kontrollierten Bedingungen und nur für zunächst einen bestimmten Zeitraum erhöht werden

Relevante KPIs
| KPI | Warum wichtig? |
| :-: | :-: |
| Kosten | Zeigt, ob der Kunde tatsächlich mehr investiert |
| Leads | Zentrale Zielgröße des Kunden |
| CPL | Wichtigster Effizienz-KPI für Lead-Kampagnen |
| Klicks | Prüft, ob das Problem bereits beim Traffic entsteht |
| CPC | Zeigt, ob Media-Einkauf teurer wird |
| Lead Rate | Zeigt, ob Klicks schlechter in Leads konvertieren |
| Buchungen | Prüft, ob Leads auch zu Geschäft führen |
| Konversionsrate Bookings/Lead | Bewertet Lead-Qualität |
| Umsatz | Zeigt Business Impact |
| ROAS | Bewertet Umsatz je Werbe-Euro |
| AOV Umsatz/Buchung | Zeigt, ob hochwertige Buchungen entstehen |

""".strip(),
}


def normalize_text(text: str) -> str:
    """Macht Nutzereingaben einfacher vergleichbar."""
    text = text.lower().strip()
    replacements = {
        "ä": "ae",
        "ö": "oe",
        "ü": "ue",
        "ß": "ss",
    }
    for old, new in replacements.items():
        text = text.replace(old, new)
    return text


def normalize_filename(filename: str) -> str:
    """Normalisiert SQL-Dateinamen für tolerante Vergleiche."""
    filename = filename.lower().strip()
    filename = re.sub(r"\(\d+\)(?=\.sql$)", "", filename)
    filename = re.sub(r"\s+", "", filename)
    return filename


def candidate_sql_dirs() -> list[Path]:
    """Liefert alle sinnvollen Ordner, in denen SQL-Dateien liegen können."""
    dirs = [SQL_DIR, BASE_DIR / "sql", BASE_DIR]
    unique_dirs: list[Path] = []
    for directory in dirs:
        directory = Path(directory)
        if directory not in unique_dirs:
            unique_dirs.append(directory)
    return unique_dirs


def find_sql_file(intent: str) -> Path:
    """Sucht die passende SQL-Datei im SQL-Ordner oder im Projektordner."""
    if intent not in SQL_FILES:
        raise KeyError(f"Unbekannter SQL-Intent: {intent}")

    search_dirs = [directory for directory in candidate_sql_dirs() if directory.exists()]

    # 1) exact file names
    for directory in search_dirs:
        for filename in SQL_FILES[intent]:
            path = directory / filename
            if path.exists():
                return path

    # # 2) tolerates version suffixes in file names 
    # expected_names = {normalize_filename(filename) for filename in SQL_FILES[intent]}
    # for directory in search_dirs:
    #     for path in directory.glob("*.sql"):
    #         if normalize_filename(path.name) in expected_names:
    #             return path

    possible_names = ", ".join(SQL_FILES[intent])
    searched = ", ".join(str(directory) for directory in search_dirs)
    raise FileNotFoundError(
        "Keine passende SQL-Datei gefunden.\n"
        f"Intent: {intent}\n"
        f"Erwartete Dateinamen: {possible_names}\n"
        f"Durchsuchte Ordner: {searched}"
    )


def read_sql(intent: str) -> str:
    """Liest eine SQL-Datei als Text ein."""
    sql_path = find_sql_file(intent)
    return sql_path.read_text(encoding="utf-8")


def run_sql(intent: str) -> pd.DataFrame:
    """Führt eine bekannte SQL-Datei in DuckDB aus und gibt das Ergebnis zurück."""
    if not DB_PATH.exists():
        raise FileNotFoundError(
            f"Die Datenbank wurde nicht gefunden: {DB_PATH}\n"
            "Bitte zuerst die Datenpipeline starten, z. B. mit: python load.py"
        )

    try:
        import duckdb
    except ImportError as exc:
        raise ImportError(
            "Das Paket 'duckdb' ist nicht installiert. Bitte installieren mit: pip install duckdb"
        ) from exc

    query = read_sql(intent)

    with duckdb.connect(str(DB_PATH)) as con:
        return con.execute(query).fetchdf()


def extract_top_n(question: str, default: int = 10) -> int:
    """Erkennt z. B. 'Top 5' aus einer Frage."""
    match = re.search(r"top\s*(\d+)", question)
    if match:
        return int(match.group(1))
    return default


def extract_year(question: str) -> Optional[int]:
    """Erkennt Jahreszahlen wie 2023, 2024 oder 2025."""
    match = re.search(r"\b(20\d{2})\b", question)
    if match:
        return int(match.group(1))
    return None


def extract_hotel_id(question: str) -> Optional[str]:
    """Erkennt Formulierungen wie 'Hotel 18' oder 'hotel_id 18'."""
    match = re.search(r"\bhotel(?:_id)?\s*[:#-]?\s*(\d+)\b", question)
    if match:
        return match.group(1)
    return None


def filter_result(df: pd.DataFrame, question: str) -> pd.DataFrame:
    """Filtert Ergebnisdaten optional nach Jahr, Hotel-ID oder begrenzt auf Top-N."""
    top_n = extract_top_n(question)
    year = extract_year(question)
    hotel_id = extract_hotel_id(question)

    if year is not None and "year" in df.columns:
        df = df[df["year"].astype(str) == str(year)]

    if hotel_id is not None and "hotel_id" in df.columns:
        df = df[df["hotel_id"].astype(str) == hotel_id]

    return df.head(top_n)


def dataframe_to_markdown(df: pd.DataFrame) -> str:
    """Wandelt ein DataFrame in eine gut lesbare Markdown-Tabelle um."""
    if df.empty:
        return "Ich habe keine passenden Daten gefunden."

    try:
        return df.to_markdown(index=False)
    except Exception:
        # fallback in case 'tabulate' not installed 
        return "```\n" + df.to_string(index=False) + "\n```"


def sql_response(intent: str, intro: str, question: str) -> BotResponse:
    """Führt SQL aus, filtert optional und baut die Bot-Antwort."""
    df = filter_result(run_sql(intent), question)
    return BotResponse(f"{intro}:\n\n" + dataframe_to_markdown(df), df)


def asks_for_year_view(q: str) -> bool:
    """Erkennt, ob die Frage eine Auswertung pro Jahr meint."""
    return any(word in q for word in ["jahr", "jahre", "year", "years", "pro jahr", "per year", "by year"])


def asks_for_weekly_view(q: str) -> bool:
    """Erkennt, ob die Frage eine wöchentliche Zeitreihe meint."""
    return any(word in q for word in ["woechentlich", "weekly", "woche", "kw", "kalenderwoche"])


def asks_for_hotel_18(q: str) -> bool:
    """Erkennt spezifische Fragen zu Hotel 18."""
    return bool(re.search(r"\bhotel\s*18\b|\bhotel_id\s*18\b", q))


def answer_question(question: str) -> BotResponse:
    """Hauptfunktion: Frage verstehen, passende Aktion wählen, Antwort bauen."""
    q = normalize_text(question)

    if not q or any(word in q for word in ["hilfe", "help", "was kannst", "beispiele"]):
        return BotResponse(HELP_TEXT)

    # Spezifische SQL-Fragen zuerst, damit sie nicht von allgemeinen Keywords abgefangen werden.
    if asks_for_hotel_18(q):
        if any(word in q for word in ["juni", "june", "august", "aug", "jun", "kritische phase", "jun aug", "juni august"]):
            return sql_response(
                "hotel_18_kpi_jun_aug",
                "Hier ist die KPI-Analyse für Hotel 18 von Juni bis August 2025",
                q,
            )
        return sql_response(
            "hotel_18_comparison_years",
            "Hier ist der Jahresvergleich 2024 vs. 2025 für Hotel 18",
            q,
        )

    if any(word in q for word in ["executive summary", "management summary", "gesamtvergleich", "2024 vs", "2025 vs"]):
        return sql_response(
            "executive_summary_sql",
            "Hier ist die Executive Summary 2024 vs. 2025 aus der SQL-Auswertung",
            q,
        )

    # answers questions without sql input
    if any(word in q for word in ["hypothese", "hypothesen", "gruende", "warum"]):
        return BotResponse(BUSINESS_ANSWERS["hypothesen"])

    if any(word in q for word in ["zusaetzliche daten", "welche daten", "must have", "nice to have"]):
        return BotResponse(BUSINESS_ANSWERS["daten"])

    if any(word in q for word in ["budget", "erhoehen", "werbebudget"]):
        return BotResponse(BUSINESS_ANSWERS["budget"])

    # Datenfragen mit SQL
    if any(word in q for word in ["zeitreihe", "time series", "zeitverlauf", "woechentlich", "weekly", "woche"]):
        intent = "time_series_weekly" if asks_for_weekly_view(q) else "time_series_monthly"
        return sql_response(intent, "Hier ist die Zeitreihe", q)

    if any(word in q for word in ["monatlich", "monthly", "ctr", "cpc", "conversion rate", "performance pro hotel"]):
        return sql_response(
            "monthly_per_hotel",
            "Hier ist die monatliche Performance pro Hotel",
            q,
        )

    if any(word in q for word in ["steigende kosten", "sinkende leads", "auffaellig", "rising", "sinking"]):
        # Wenn der Nutzer 'konsekutiv' oder 'streng' sagt, nehmen wir die strengere Variante.
        intent = "rising_sinking_strict" if any(
            word in q for word in ["konsekutiv", "streng", "3 monate am stueck", "drei monate am stueck"]
        ) else "rising_sinking"
        return sql_response(
            intent,
            "Diese Hotels sind auffällig, weil Kosten steigen und Leads sinken",
            q,
        )

    if any(word in q for word in ["moving average", "gleitender durchschnitt", "trend", "trends"]):
        return sql_response(
            "moving_average",
            "Hier sind Moving Average und Trendinformationen",
            q,
        )

    if any(word in q for word in ["segment", "segmente", "segmentierung"]):
        intent = "hotel_segments_per_year" if asks_for_year_view(q) else "hotel_segments_total"
        return sql_response(intent, "Hier ist die Segmentierung der Hotels", q)

    if any(word in q for word in ["anomalie", "anomalien", "anomaly", "ausreisser"]):
        intent = "anomaly_per_year" if asks_for_year_view(q) else "anomaly_total"
        return sql_response(intent, "Hier sind die erkannten Anomalien", q)

    if any(word in q for word in ["volatil", "volatilitaet", "schwankung", "schwankungen"]):
        intent = "volatility_by_year" if asks_for_year_view(q) else "volatility_total"
        return sql_response(intent, "Hier sind die volatilsten Hotels", q)

    if any(word in q for word in ["handlungsempfehlung", "empfehlung", "summary"]):
        return sql_response(
            "executive_summary_sql",
            "Hier ist die Executive Summary 2024 vs. 2025 aus der SQL-Auswertung",
            q,
        )

    return BotResponse(
        "Diese Frage konnte ich noch nicht eindeutig zuordnen.\n\n"
        "Formuliere sie bitte etwas näher an einem Analyse-Thema, zum Beispiel:\n"
        "- 'Zeig mir Anomalien'\n"
        "- 'Welche Hotels haben steigende Kosten und sinkende Leads?'\n"
        "- 'Zeig mir Hotel 18 KPI Juni August'\n"
        "- 'Gib mir eine Budget-Empfehlung'\n\n"
        + HELP_TEXT
    )


def run_console_chat() -> None:
    """Startet einen einfachen Chat im Terminal."""
    print("HolidayCheck Media Chatbot")
    print("Schreibe 'exit', um den Chat zu beenden.\n")
    print(HELP_TEXT)
    print()

    while True:
        question = input("Du: ")
        if question.lower().strip() in {"exit", "quit", "ende"}:
            print("Bot: Bis bald!")
            break

        try:
            response = answer_question(question)
            print("\nBot:")
            print(response.answer)
            print()
        except Exception as exc:
            print("\nBot: Es ist ein Fehler aufgetreten:")
            print(exc)
            print()


if __name__ == "__main__":
    run_console_chat()
