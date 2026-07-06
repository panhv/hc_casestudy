-- comparison Hotel 18: 2024 vs. 2025
-- KPIs: cost, leads, cost per lead, bookings, revenue, ROAS, conversion rate as bookings / leads

WITH campaign_yearly AS (
    SELECT
        hotel_id,
        EXTRACT(YEAR FROM date) AS year,
        SUM(cost) AS cost,
        SUM(leads) AS leads
    FROM campaign_performance
    WHERE hotel_id = '18'
      AND EXTRACT(YEAR FROM date) IN (2024, 2025)
    GROUP BY hotel_id, year
),

booking_yearly AS (
    SELECT
        hotel_id,
        EXTRACT(YEAR FROM booking_date) AS year,
        COUNT(DISTINCT booking_id) AS bookings,
        SUM(revenue) AS revenue
    FROM booking_data
    WHERE hotel_id = '18'
      AND EXTRACT(YEAR FROM booking_date) IN (2024, 2025)
    GROUP BY hotel_id, year
),


yearly_joined AS (
    SELECT
        COALESCE(c.hotel_id, b.hotel_id) AS hotel_id,
        COALESCE(c.year, b.year) AS year,
        COALESCE(c.cost, 0) AS cost,
        COALESCE(c.leads, 0) AS leads,
        COALESCE(b.bookings, 0) AS bookings,
        COALESCE(b.revenue, 0) AS revenue
    FROM campaign_yearly c
    FULL OUTER JOIN booking_yearly b
        ON c.hotel_id = b.hotel_id
       AND c.year = b.year
),

pivoted AS (
    SELECT
        hotel_id,
        MAX(CASE WHEN year = 2024 THEN cost END) AS cost_2024,
        MAX(CASE WHEN year = 2025 THEN cost END) AS cost_2025,
        MAX(CASE WHEN year = 2024 THEN leads END) AS leads_2024,
        MAX(CASE WHEN year = 2025 THEN leads END) AS leads_2025,
        MAX(CASE WHEN year = 2024 THEN bookings END) AS bookings_2024,
        MAX(CASE WHEN year = 2025 THEN bookings END) AS bookings_2025,
        MAX(CASE WHEN year = 2024 THEN revenue END) AS revenue_2024,
        MAX(CASE WHEN year = 2025 THEN revenue END) AS revenue_2025
    FROM yearly_joined
    GROUP BY 1
)

-- calculation final KPIs
SELECT
    p.hotel_id,
    h.region,
    h.country,

    -- cost
    ROUND(p.cost_2024, 2) AS cost_2024,
    ROUND(p.cost_2025, 2) AS cost_2025,
    ROUND((p.cost_2025 - p.cost_2024) / NULLIF(p.cost_2024, 0) * 100, 2) AS cost_change_pct,

    -- leads
    p.leads_2024,
    p.leads_2025,
    ROUND((p.leads_2025 - p.leads_2024) / NULLIF(p.leads_2024, 0) * 100, 2) AS leads_change_pct,

    -- cost per lead
    ROUND(p.cost_2024 / NULLIF(p.leads_2024, 0), 2) AS cost_per_lead_2024,
    ROUND(p.cost_2025 / NULLIF(p.leads_2025, 0), 2) AS cost_per_lead_2025,
    ROUND(
        ((p.cost_2025 / NULLIF(p.leads_2025, 0)) - (p.cost_2024 / NULLIF(p.leads_2024, 0)))
        / NULLIF(p.cost_2024 / NULLIF(p.leads_2024, 0), 0) * 100, 
        2
    ) AS cost_per_lead_change_pct,

    -- bookings
    p.bookings_2024,
    p.bookings_2025,
    ROUND((p.bookings_2025 - p.bookings_2024) / NULLIF(p.bookings_2024, 0) * 100, 2) AS bookings_change_pct,

    -- revenue
    ROUND(p.revenue_2024, 2) AS revenue_2024,
    ROUND(p.revenue_2025, 2) AS revenue_2025,
    ROUND((p.revenue_2025 - p.revenue_2024) / NULLIF(p.revenue_2024, 0) * 100, 2) AS revenue_change_pct,

    -- ROAS
    ROUND(p.revenue_2024 / NULLIF(p.cost_2024, 0), 2) AS roas_2024,
    ROUND(p.revenue_2025 / NULLIF(p.cost_2025, 0), 2) AS roas_2025,
    ROUND(
        ((p.revenue_2025 / NULLIF(p.cost_2025, 0)) - (p.revenue_2024 / NULLIF(p.cost_2024, 0)))
        / NULLIF(p.revenue_2024 / NULLIF(p.cost_2024, 0), 0) * 100, 
        2
    ) AS roas_change_pct,

    -- bookings per lead
    ROUND(p.bookings_2024 / NULLIF(p.leads_2024, 0), 4) AS conversion_rate_2024,
    ROUND(p.bookings_2025 / NULLIF(p.leads_2025, 0), 4) AS conversion_rate_2025,
    ROUND(
        ((p.bookings_2025 / NULLIF(p.leads_2025, 0)) - (p.bookings_2024 / NULLIF(p.leads_2024, 0)))
        / NULLIF(p.bookings_2024 / NULLIF(p.leads_2024, 0), 0) * 100, 
        2
    ) AS conversion_rate_change_pct

FROM pivoted p
LEFT JOIN hotel_information h
    ON p.hotel_id = h.hotel_id;
