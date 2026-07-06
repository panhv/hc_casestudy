-- Hotel 18: KPI-Summary (Juni - August 2025) incl. delta-calculation
-- showing of KPIs during critical period 
WITH campaign_monthly AS (
    SELECT
        hotel_id,
        DATE_TRUNC('month', date) AS month,
        SUM(impressions) AS impressions,
        SUM(clicks) AS clicks,
        SUM(leads) AS leads,
        SUM(cost) AS cost
    FROM campaign_performance
    WHERE hotel_id = '18'
      AND date >= DATE '2025-06-01'
      AND date < DATE '2025-09-01'
    GROUP BY hotel_id, month
),

booking_monthly AS (
    SELECT
        hotel_id,
        DATE_TRUNC('month', booking_date) AS month,
        COUNT(DISTINCT booking_id) AS bookings,
        SUM(revenue) AS revenue
    FROM booking_data
    WHERE hotel_id = '18'
      AND booking_date >= DATE '2025-06-01'
      AND booking_date < DATE '2025-09-01'
    GROUP BY hotel_id, month
),

monthly_kpis AS (
    SELECT
        c.hotel_id,
        h.region,
        h.country,
        c.month,
        -- Basiszahlen
        c.impressions,
        c.clicks,
        c.leads,
        c.cost,
        b.bookings,
        b.revenue,
        -- Berechnete Raten
        c.clicks / NULLIF(c.impressions, 0) AS ctr,
        c.cost / NULLIF(c.clicks, 0) AS cpc,
        c.leads / NULLIF(c.clicks, 0) AS lead_rate,
        c.cost / NULLIF(c.leads, 0) AS cost_per_lead,
        COALESCE(b.revenue, 0) / NULLIF(c.cost, 0) AS roas,
        COALESCE(b.bookings, 0) / NULLIF(c.leads, 0) AS conversion_rate
    FROM campaign_monthly c
    LEFT JOIN booking_monthly b ON c.hotel_id = b.hotel_id AND c.month = b.month
    LEFT JOIN hotel_information h ON c.hotel_id = h.hotel_id
),

-- pivoting for delta calculation
pivoted AS (
    SELECT
        hotel_id,
        MAX(region) AS region,
        MAX(country) AS country,
        -- june
        MAX(CASE WHEN month = DATE '2025-06-01' THEN impressions END) AS imp_june,
        MAX(CASE WHEN month = DATE '2025-06-01' THEN clicks END) AS clicks_june,
        MAX(CASE WHEN month = DATE '2025-06-01' THEN leads END) AS leads_june,
        MAX(CASE WHEN month = DATE '2025-06-01' THEN cost END) AS cost_june,
        MAX(CASE WHEN month = DATE '2025-06-01' THEN bookings END) AS bookings_june,
        MAX(CASE WHEN month = DATE '2025-06-01' THEN revenue END) AS revenue_june,
        -- august
        MAX(CASE WHEN month = DATE '2025-08-01' THEN impressions END) AS imp_aug,
        MAX(CASE WHEN month = DATE '2025-08-01' THEN clicks END) AS clicks_aug,
        MAX(CASE WHEN month = DATE '2025-08-01' THEN leads END) AS leads_aug,
        MAX(CASE WHEN month = DATE '2025-08-01' THEN cost END) AS cost_aug,
        MAX(CASE WHEN month = DATE '2025-08-01' THEN bookings END) AS bookings_aug,
        MAX(CASE WHEN month = DATE '2025-08-01' THEN revenue END) AS revenue_aug
    FROM monthly_kpis
    GROUP BY hotel_id
)

-- true monthly values
SELECT
    hotel_id,
    region,
    country,
    STRFTIME(month, '%B %Y') AS zeitraum, -- Zeigt z.B. "June 2025"
    impressions,
    clicks,
    leads,
    ROUND(cost, 2) AS cost,
    ROUND(ctr * 100, 2) AS ctr_pct,
    ROUND(cpc, 2) AS cpc,
    ROUND(lead_rate * 100, 2) AS lead_rate_pct,
    ROUND(cost_per_lead, 2) AS cost_per_lead,
    bookings,
    ROUND(revenue, 2) AS revenue,
    ROUND(roas, 2) AS roas,
    ROUND(conversion_rate, 4) AS conversion_rate,
    1 AS sort_order -- Sorgt dafür, dass die Monatsdaten oben stehen
FROM monthly_kpis

UNION ALL

-- add delta values
SELECT
    hotel_id,
    region,
    country,
    'CHANGE (June vs August %)' AS period,
    ROUND((imp_aug - imp_june) / NULLIF(imp_june, 0) * 100, 2) AS impressions,
    ROUND((clicks_aug - clicks_june) / NULLIF(clicks_june, 0) * 100, 2) AS clicks,
    ROUND((leads_aug - leads_june) / NULLIF(leads_june, 0) * 100, 2) AS leads,
    ROUND((cost_aug - cost_june) / NULLIF(cost_june, 0) * 100, 2) AS cost,
    -- ctr delta
    ROUND(((clicks_aug / NULLIF(imp_aug, 0)) - (clicks_june / NULLIF(imp_june, 0))) / NULLIF(clicks_june / NULLIF(imp_june, 0), 0) * 100, 2) AS ctr_pct,
    -- cpc delta
    ROUND(((cost_aug / NULLIF(clicks_aug, 0)) - (cost_june / NULLIF(clicks_june, 0))) / NULLIF(cost_june / NULLIF(clicks_june, 0), 0) * 100, 2) AS cpc,
    -- lead rate delta
    ROUND(((leads_aug / NULLIF(clicks_aug, 0)) - (leads_june / NULLIF(clicks_june, 0))) / NULLIF(leads_june / NULLIF(clicks_june, 0), 0) * 100, 2) AS lead_rate_pct,
    -- cpl delta
    ROUND(((cost_aug / NULLIF(leads_aug, 0)) - (cost_june / NULLIF(leads_june, 0))) / NULLIF(cost_june / NULLIF(leads_june, 0), 0) * 100, 2) AS cost_per_lead,
    ROUND((bookings_aug - bookings_june) / NULLIF(bookings_june, 0) * 100, 2) AS bookings,
    ROUND((revenue_aug - revenue_june) / NULLIF(revenue_june, 0) * 100, 2) AS revenue,
    -- ROAS delta
    ROUND(((revenue_aug / NULLIF(cost_aug, 0)) - (revenue_june / NULLIF(cost_june, 0))) / NULLIF(revenue_june / NULLIF(cost_june, 0), 0) * 100, 2) AS roas,
    -- conversion rate delta
    ROUND(((bookings_aug / NULLIF(leads_aug, 0)) - (bookings_june / NULLIF(leads_june, 0))) / NULLIF(bookings_june / NULLIF(leads_june, 0), 0) * 100, 2) AS conversion_rate,
    2 AS sort_order 
FROM pivoted

ORDER BY sort_order, period;
