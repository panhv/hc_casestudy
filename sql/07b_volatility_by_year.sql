-- Aufgabe 7: Top 5 Hotels mit höchsten Volatilität bei Leads und Beschreibung der Kundenbetreuung 
-- per year volatility 

-- aggregation of leads and costs per hotel and join with hotel information
WITH campaign_monthly AS (
    SELECT
        c.hotel_id,
        h.country,
        h.region,
        h.hotel_category,
        EXTRACT(YEAR FROM c.date)::INT AS year,
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
        year,
        month
),

-- calculating volatility as coefficient of variance for each hotel
volatility_by_year AS (
    SELECT
        hotel_id,
        country,
        region,
        hotel_category,
        year,
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
        hotel_category,
        year
),

-- ranking hotels by volatility 
-- high cv first 
ranked_hotels AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY year
            ORDER BY cv_leads DESC, sd_monthly_leads DESC
        ) AS volatility_rank
    FROM volatility_by_year
),

-- filtering 5 top volatile hotels by year
top_5_by_year AS (
    SELECT *
    FROM ranked_hotels
    WHERE volatility_rank <= 5
),


-- ranking monthly performance for volatile hotels by year to identify peak and trough lead months
-- rn_low  = 1 represents the month with the fewest leads
-- rn_high = 1 represents the month with the most leads
ranked_months AS (
    SELECT
        cm.hotel_id,
        cm.year,
        cm.month,
        cm.leads,
        cm.cost,
        ROW_NUMBER() OVER (
            PARTITION BY cm.hotel_id, cm.year
            ORDER BY cm.leads ASC, cm.month ASC
        ) AS rn_low,

        ROW_NUMBER() OVER (
            PARTITION BY cm.hotel_id, cm.year
            ORDER BY cm.leads DESC, cm.month ASC
        ) AS rn_high

    FROM campaign_monthly cm
    INNER JOIN top_5_by_year t
        ON cm.hotel_id = t.hotel_id
       AND cm.year = t.year
),


-- identifying the specific month with the lowest/highest number of leads and costs
extreme_months_by_year AS (
    SELECT
        hotel_id,
        year,

        MAX(CASE WHEN rn_low = 1 THEN month END) AS min_month,
        MAX(CASE WHEN rn_low = 1 THEN leads END) AS min_leads,
        MAX(CASE WHEN rn_low = 1 THEN cost END) AS cost_at_min,

        MAX(CASE WHEN rn_high = 1 THEN month END) AS max_month,
        MAX(CASE WHEN rn_high = 1 THEN leads END) AS max_leads,
        MAX(CASE WHEN rn_high = 1 THEN cost END) AS cost_at_max

    FROM ranked_months
    GROUP BY
        hotel_id,
        year
)

SELECT
    t.volatility_rank,
    t.hotel_id,
    t.country,
    t.region,
    t.hotel_category,
    t.year,
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

FROM top_5_by_year t
LEFT JOIN extreme_months_by_year e
    ON t.hotel_id = e.hotel_id
   AND t.year = e.year

ORDER BY
    t.year,
    t.volatility_rank;