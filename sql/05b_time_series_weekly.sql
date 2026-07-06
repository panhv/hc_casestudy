-- Aufgabe 5: Visualisiere Leads, Revenue und Cost über die Zeit (wöchentlich)


-- weekly time series for cost, leads and revenue
-- calendar week is calculated as ISO week (%V) with ISO year (%G)
-- avoids mixing the first calendar week with the last days of December
WITH campaign_weekly AS (
    SELECT
        CAST(STRFTIME(CAST(date AS DATE), '%G') AS INTEGER) AS year,
        CAST(STRFTIME(CAST(date AS DATE), '%V') AS INTEGER) AS week,
        SUM(cost) AS cost,
        SUM(leads) AS leads
    FROM campaign_performance
    WHERE CAST(STRFTIME(CAST(date AS DATE), '%G') AS INTEGER) IN (2024, 2025)
    GROUP BY year, week
),

revenue_weekly AS (
    SELECT
        CAST(STRFTIME(CAST(booking_date AS DATE), '%G') AS INTEGER) AS year,
        CAST(STRFTIME(CAST(booking_date AS DATE), '%V') AS INTEGER) AS week,
        SUM(revenue) AS revenue
    FROM booking_data
    WHERE CAST(STRFTIME(CAST(booking_date AS DATE), '%G') AS INTEGER) IN (2024, 2025)
    GROUP BY year, week
),

weeks AS (
    SELECT week FROM campaign_weekly
    UNION
    SELECT week FROM revenue_weekly
),

weekly_joined AS (
    SELECT
        COALESCE(c.year, r.year) AS year,
        COALESCE(c.week, r.week) AS week,
        COALESCE(c.cost, 0) AS cost,
        COALESCE(c.leads, 0) AS leads,
        COALESCE(r.revenue, 0) AS revenue
    FROM campaign_weekly AS c
    FULL OUTER JOIN revenue_weekly AS r
        ON c.year = r.year
       AND c.week = r.week
)

SELECT
    w.week,
    COALESCE(SUM(CASE WHEN wj.year = 2024 THEN wj.cost END), 0) AS cost_2024,
    COALESCE(SUM(CASE WHEN wj.year = 2025 THEN wj.cost END), 0) AS cost_2025,
    COALESCE(SUM(CASE WHEN wj.year = 2024 THEN wj.leads END), 0) AS leads_2024,
    COALESCE(SUM(CASE WHEN wj.year = 2025 THEN wj.leads END), 0) AS leads_2025,
    COALESCE(SUM(CASE WHEN wj.year = 2024 THEN wj.revenue END), 0) AS revenue_2024,
    COALESCE(SUM(CASE WHEN wj.year = 2025 THEN wj.revenue END), 0) AS revenue_2025
FROM weeks AS w
LEFT JOIN weekly_joined AS wj
    ON w.week = wj.week
GROUP BY w.week
ORDER BY w.week;