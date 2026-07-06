-- executive summary: comparison 2024 vs. 2025
-- KPIs: cost, leads, cpl, bookings, revenue, ROAS, conversion rate and deltas
WITH campaign_yearly AS (
    SELECT
        EXTRACT(YEAR FROM date) AS year,
        SUM(cost) AS cost,
        SUM(leads) AS leads
    FROM campaign_performance
    WHERE EXTRACT(YEAR FROM date) IN (2024, 2025)
    GROUP BY
        EXTRACT(YEAR FROM date)
),

booking_yearly AS (
    SELECT
        EXTRACT(YEAR FROM booking_date) AS year,
        COUNT(DISTINCT booking_id) AS bookings,
        SUM(revenue) AS revenue
    FROM booking_data
    WHERE EXTRACT(YEAR FROM booking_date) IN (2024, 2025)
    GROUP BY
        EXTRACT(YEAR FROM booking_date)
),

yearly_kpis AS (
    SELECT
        c.year,
        c.cost,
        c.leads,
        c.cost / NULLIF(c.leads, 0) AS cost_per_lead,
        COALESCE(b.bookings, 0) AS bookings,
        COALESCE(b.revenue, 0) AS revenue,
        COALESCE(b.revenue, 0) / NULLIF(c.cost, 0) AS roas,
        COALESCE(b.bookings, 0) / NULLIF(c.leads, 0) AS bookings_per_lead
    FROM campaign_yearly c
    LEFT JOIN booking_yearly b
        ON c.year = b.year
),

pivoted AS (
    SELECT
        MAX(CASE WHEN year = 2024 THEN cost END) AS cost_2024,
        MAX(CASE WHEN year = 2025 THEN cost END) AS cost_2025,

        MAX(CASE WHEN year = 2024 THEN leads END) AS leads_2024,
        MAX(CASE WHEN year = 2025 THEN leads END) AS leads_2025,

        MAX(CASE WHEN year = 2024 THEN cost_per_lead END) AS cost_per_lead_2024,
        MAX(CASE WHEN year = 2025 THEN cost_per_lead END) AS cost_per_lead_2025,

        MAX(CASE WHEN year = 2024 THEN bookings END) AS bookings_2024,
        MAX(CASE WHEN year = 2025 THEN bookings END) AS bookings_2025,

        MAX(CASE WHEN year = 2024 THEN revenue END) AS revenue_2024,
        MAX(CASE WHEN year = 2025 THEN revenue END) AS revenue_2025,

        MAX(CASE WHEN year = 2024 THEN roas END) AS roas_2024,
        MAX(CASE WHEN year = 2025 THEN roas END) AS roas_2025,

        MAX(CASE WHEN year = 2024 THEN bookings_per_lead END) AS bookings_per_lead_2024,
        MAX(CASE WHEN year = 2025 THEN bookings_per_lead END) AS bookings_per_lead_2025
    FROM yearly_kpis
)

SELECT
    ROUND(cost_2024, 2) AS cost_2024,
    ROUND(cost_2025, 2) AS cost_2025,
    ROUND((cost_2025 - cost_2024) / NULLIF(cost_2024, 0) * 100, 2) AS cost_change_pct,

    leads_2024,
    leads_2025,
    ROUND((leads_2025 - leads_2024) / NULLIF(leads_2024, 0) * 100, 2) AS leads_change_pct,

    ROUND(cost_per_lead_2024, 2) AS cost_per_lead_2024,
    ROUND(cost_per_lead_2025, 2) AS cost_per_lead_2025,
    ROUND((cost_per_lead_2025 - cost_per_lead_2024) / NULLIF(cost_per_lead_2024, 0) * 100, 2) AS cost_per_lead_change_pct,

    bookings_2024,
    bookings_2025,
    ROUND((bookings_2025 - bookings_2024) / NULLIF(bookings_2024, 0) * 100, 2) AS bookings_change_pct,

    ROUND(revenue_2024, 2) AS revenue_2024,
    ROUND(revenue_2025, 2) AS revenue_2025,
    ROUND((revenue_2025 - revenue_2024) / NULLIF(revenue_2024, 0) * 100, 2) AS revenue_change_pct,

    ROUND(roas_2024, 2) AS roas_2024,
    ROUND(roas_2025, 2) AS roas_2025,
    ROUND((roas_2025 - roas_2024) / NULLIF(roas_2024, 0) * 100, 2) AS roas_change_pct,

    ROUND(bookings_per_lead_2024, 4) AS bookings_per_lead_2024,
    ROUND(bookings_per_lead_2025, 4) AS bookings_per_lead_2025,
    ROUND((bookings_per_lead_2025 - bookings_per_lead_2024) / NULLIF(bookings_per_lead_2024, 0) * 100, 2) AS bookings_per_lead_change_pct

FROM pivoted;