-- Aufgabe 5: Visualisiere Leads, Revenue und Cost über die Zeit (monatlich)


-- monthly time series for cost, leads and revenue
-- one row per month and one column per metric/year
WITH months AS (
    SELECT month
    FROM range(1, 13) AS t(month)
),

campaign_monthly AS (
    SELECT
        EXTRACT(year FROM CAST(date AS DATE)) AS year,
        EXTRACT(month FROM CAST(date AS DATE)) AS month,
        SUM(cost) AS cost,
        SUM(leads) AS leads
    FROM campaign_performance
    WHERE EXTRACT(year FROM CAST(date AS DATE)) IN (2024, 2025)
    GROUP BY year, month
),

revenue_monthly AS (
    SELECT
        EXTRACT(year FROM CAST(booking_date AS DATE)) AS year,
        EXTRACT(month FROM CAST(booking_date AS DATE)) AS month,
        SUM(revenue) AS revenue
    FROM booking_data
    WHERE EXTRACT(year FROM CAST(booking_date AS DATE)) IN (2024, 2025)
    GROUP BY year, month
),

monthly_joined AS (
    SELECT
        COALESCE(c.year, r.year) AS year,
        COALESCE(c.month, r.month) AS month,
        COALESCE(c.cost, 0) AS cost,
        COALESCE(c.leads, 0) AS leads,
        COALESCE(r.revenue, 0) AS revenue
    FROM campaign_monthly AS c
    FULL OUTER JOIN revenue_monthly AS r
        ON c.year = r.year
       AND c.month = r.month
)

SELECT
    m.month,
    COALESCE(SUM(CASE WHEN mj.year = 2024 THEN mj.cost END), 0) AS cost_2024,
    COALESCE(SUM(CASE WHEN mj.year = 2025 THEN mj.cost END), 0) AS cost_2025,
    COALESCE(SUM(CASE WHEN mj.year = 2024 THEN mj.leads END), 0) AS leads_2024,
    COALESCE(SUM(CASE WHEN mj.year = 2025 THEN mj.leads END), 0) AS leads_2025,
    COALESCE(SUM(CASE WHEN mj.year = 2024 THEN mj.revenue END), 0) AS revenue_2024,
    COALESCE(SUM(CASE WHEN mj.year = 2025 THEN mj.revenue END), 0) AS revenue_2025
FROM months AS m
LEFT JOIN monthly_joined AS mj
    ON m.month = mj.month
GROUP BY m.month
ORDER BY m.month;