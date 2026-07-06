-- Aufgabe 7: Top 5 Hotels mit höchsten Volatilität bei Leads und Beschreibung der Kundenbetreuung 
-- total volatibility

-- aggregation of leads and costs per hotel and join with hotel information
WITH campaign_monthly AS (
    SELECT
        c.hotel_id,
        h.country,
        h.region,
        h.hotel_category,
        date_trunc('month', c.date)::DATE AS month,
        SUM(c.leads) AS leads,
        ROUND(SUM(c.cost), 2) AS cost
    FROM campaign_performance c
    LEFT JOIN hotel_information h
        ON c.hotel_id = h.hotel_id
    GROUP BY
        c.hotel_id,
        h.country,
        h.region,
        h.hotel_category,
        month
),

-- calculating volatility as coefficient of variance for each hotel
volatility_total AS (
    SELECT
        hotel_id,
        country,
        region,
        hotel_category,
        COUNT(*) AS months,
        SUM(leads) AS total_leads,
        ROUND(AVG(leads), 2) AS avg_monthly_leads,
        ROUND(STDDEV_SAMP(leads), 2) AS sd_monthly_leads,
        ROUND(STDDEV_SAMP(leads) / NULLIF(AVG(leads), 0), 4) AS cv_leads,
        MIN(leads) AS min_monthly_leads,
        MAX(leads) AS max_monthly_leads,
        MAX(leads) - MIN(leads) AS range_leads
    FROM campaign_monthly
    GROUP BY
        hotel_id,
        country,
        region,
        hotel_category
),

-- ranking hotels by volatility 
-- high cv first 
ranked_hotels AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            ORDER BY cv_leads DESC, sd_monthly_leads DESC
        ) AS volatility_rank
    FROM volatility_total
),

-- filtering 5 top volatile hotels
top_5_hotels AS (
    SELECT *
    FROM ranked_hotels
    WHERE volatility_rank <= 5
),

ranked_months AS (
    SELECT
        cm.hotel_id,
        cm.month,
        cm.leads,
        cm.cost,

        ROW_NUMBER() OVER (
            PARTITION BY cm.hotel_id
            ORDER BY cm.leads ASC, cm.month ASC
        ) AS rn_low,

        ROW_NUMBER() OVER (
            PARTITION BY cm.hotel_id
            ORDER BY cm.leads DESC, cm.month ASC
        ) AS rn_high

    FROM campaign_monthly cm
    INNER JOIN top_5_hotels t
        ON cm.hotel_id = t.hotel_id
),

-- ranking (total) monthly performance for volatile hotels to identify peak and trough lead months
-- rn_low  = 1 represents the month with the fewest leads.
-- rn_high = 1 represents the month with the most leads.
extreme_months AS (
    SELECT
        hotel_id,

        MAX(CASE WHEN rn_low = 1 THEN month END) AS min_month,
        MAX(CASE WHEN rn_low = 1 THEN leads END) AS min_leads,
        MAX(CASE WHEN rn_low = 1 THEN cost END) AS cost_at_min,

        MAX(CASE WHEN rn_high = 1 THEN month END) AS max_month,
        MAX(CASE WHEN rn_high = 1 THEN leads END) AS max_leads,
        MAX(CASE WHEN rn_high = 1 THEN cost END) AS cost_at_max

    FROM ranked_months
    GROUP BY hotel_id
)

SELECT
    t.volatility_rank,
    t.hotel_id,
    t.country,
    t.region,
    t.hotel_category,
    t.months,
    t.total_leads,
    t.avg_monthly_leads,
    t.sd_monthly_leads,
    t.cv_leads,
    t.min_monthly_leads,
    t.max_monthly_leads,
    t.range_leads,

    e.min_month,
    e.min_leads,
    e.cost_at_min,

    e.max_month,
    e.max_leads,
    e.cost_at_max

FROM top_5_hotels t
LEFT JOIN extreme_months e
    ON t.hotel_id = e.hotel_id

ORDER BY t.volatility_rank;