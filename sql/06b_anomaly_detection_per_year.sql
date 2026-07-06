-- Aufgabe 6: Durchführung von Anomalie-Erkennung und mögliche Ursachenbeschreibung

-- aggregation of campaign_performance per hotel and per month
WITH campaign_monthly AS (
    SELECT
        hotel_id,
        date_trunc('month', date)::DATE AS month,
        EXTRACT(YEAR FROM date) AS year,
        SUM(impressions) AS impressions,
        SUM(clicks) AS clicks,
        SUM(leads) AS leads,
        SUM(cost) AS cost
    FROM campaign_performance
    GROUP BY hotel_id, month, year
),

-- aggregation of bookings and revenue per hotel and month
-- bookings = count of distinct booking_id
booking_monthly AS (
    SELECT
        hotel_id,
        date_trunc('month', booking_date)::DATE AS month,
        EXTRACT(YEAR FROM booking_date) AS year,
        COUNT(DISTINCT booking_id) AS bookings,
        SUM(revenue) AS revenue
    FROM booking_data
    GROUP BY hotel_id, month, year
),

-- combine campaign and booking metrics per month
monthly_hotel AS (
    SELECT
        c.hotel_id,
        c.year,
        h.country,
        h.region,
        h.hotel_category,
        c.month,
        c.impressions,
        c.clicks,
        c.leads,
        c.cost,
        COALESCE(b.bookings, 0) AS bookings,
        COALESCE(b.revenue, 0) AS revenue,

        -- click through rate
        c.clicks / NULLIF(c.impressions, 0) AS ctr,
        -- cost per click
        c.cost / NULLIF(c.clicks, 0) AS cpc,
        -- lead rate
        c.leads / NULLIF(c.clicks, 0) AS lr,
        -- cost per lead
        c.cost / NULLIF(c.leads, 0) AS cpl,
        -- return on ad spend
        COALESCE(b.revenue, 0) / NULLIF(c.cost, 0) AS roas,
        -- average order value
        COALESCE(b.revenue, 0) / NULLIF(b.bookings, 0) AS aov

    FROM campaign_monthly c
    LEFT JOIN booking_monthly b
        ON c.hotel_id = b.hotel_id
       AND c.month = b.month
    LEFT JOIN hotel_information h
        ON c.hotel_id = h.hotel_id
),

-- calculate average leads, cost, cost per lead per hotel
-- calculate standard deviation per hotel
stats AS (
    SELECT
        *,

        AVG(ctr) OVER (PARTITION BY hotel_id, year) AS avg_ctr,
        STDDEV_SAMP(ctr) OVER (PARTITION BY hotel_id, year) AS sd_ctr,

        AVG(cpc) OVER (PARTITION BY hotel_id, year) AS avg_cpc,
        STDDEV_SAMP(cpc) OVER (PARTITION BY hotel_id, year) AS sd_cpc,

        AVG(lr) OVER (PARTITION BY hotel_id, year) AS avg_lr,
        STDDEV_SAMP(lr) OVER (PARTITION BY hotel_id, year) AS sd_lr,

        AVG(cpl) OVER (PARTITION BY hotel_id, year) AS avg_cpl,
        STDDEV_SAMP(cpl) OVER (PARTITION BY hotel_id, year) AS sd_cpl,
        
        AVG(roas) OVER (PARTITION BY hotel_id, year) AS avg_roas,
        STDDEV_SAMP(roas) OVER (PARTITION BY hotel_id, year) AS sd_roas,
        
        AVG(aov) OVER (PARTITION BY hotel_id, year) AS avg_aov,
        STDDEV_SAMP(aov) OVER (PARTITION BY hotel_id, year) AS sd_aov

    FROM monthly_hotel
    WHERE impressions > 0 AND clicks > 0 AND leads > 0 AND cost > 0
),

-- calculate z-scores (current month - average) / stdev
zscores AS (
    SELECT
         *,

        ROUND((ctr - avg_ctr) / NULLIF(sd_ctr, 0), 2) AS z_ctr,
        ROUND((cpc - avg_cpc) / NULLIF(sd_cpc, 0), 2) AS z_cpc,
        ROUND((lr - avg_lr) / NULLIF(sd_lr, 0), 2) AS z_lr,
        ROUND((cpl - avg_cpl) / NULLIF(sd_cpl, 0), 2) AS z_cpl,
        ROUND((roas - avg_roas) / NULLIF(sd_roas, 0), 2) AS z_roas,
        ROUND((aov - avg_aov) / NULLIF(sd_aov, 0), 2) AS z_aov

    FROM stats
),

scored AS (
    SELECT
        *,
        ROUND(GREATEST(0, -z_ctr)
            + GREATEST(0, z_cpc)
            + GREATEST(0, -z_lr)
            + GREATEST(0, z_cpl)
            + GREATEST(0, -z_roas)
            + GREATEST(0, -z_aov),
            2
        ) AS anomaly_score,

        CASE
            WHEN z_roas <= -2 AND z_cpl >= 2 
                THEN 'ROAS drop, high CPL'
            WHEN z_ctr <= -2 AND z_cpc >= 2
                THEN 'low CTR, high CPC'
            WHEN z_roas <= -2 
                THEN 'poor ROAS'
            WHEN z_aov <= -2 
                THEN 'AOV drop'
            WHEN z_cpl >= 2 
                THEN 'high CPL'
            WHEN z_cpc >= 2 
                THEN 'high CPC'
            WHEN z_ctr <= -2 
                THEN 'low CTR'
            WHEN z_lr <= -2 
                THEN 'low lead rate'
            ELSE 'Anomalous combination in performance metrics'
        END AS anomaly,

        CASE
            WHEN z_roas <= -2 AND z_cpl >= 2 
                THEN 'Efficiency Collapse'
            WHEN z_ctr <= -2 AND z_cpc >= 2
                THEN 'Ad Crisis'
            WHEN z_roas <= -2 
                THEN 'Unprofitable campaigns'
            WHEN z_aov <= -2 
                THEN 'Very low revenue per booking (customer value sinking)'
            WHEN z_cpl >= 2 
                THEN 'Expensive customer acquisition'
            WHEN z_cpc >= 2 
                THEN 'High CPC'
            WHEN z_ctr <= -2 
                THEN 'Interest Drop'
            WHEN z_lr <= -2 
                THEN 'Lead Conversion Crisis'
            ELSE 'Anomalous Combination in Performance Metrics'
        END AS reason

    FROM zscores
    WHERE
        z_ctr <= -2 
        OR z_cpc >= 2 
        OR z_lr <= -2 
        OR z_cpl >= 2 
        OR z_roas <= -2 
        OR z_aov <= -2
        OR (z_roas <= -1.5 AND z_cpl >= 1.5)
),

-- rank within each year for output
ranked_anomalies AS (
    SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY year ORDER BY anomaly_score DESC, month) as rank
    FROM scored
)

SELECT
    year,
    hotel_id,
    country,
    region,
    hotel_category,
    month,

    leads,
    ROUND(cost, 2) AS cost,
    bookings,
    ROUND(revenue, 2) AS revenue,

    ROUND(ctr, 4) AS ctr,
    ROUND(cpc, 2) AS cpc,
    ROUND(lr, 4) AS lr,
    ROUND(cpl, 2) AS cpl,
    ROUND(roas, 2) AS roas,
    ROUND(aov, 2) AS aov,
    
    z_ctr,
    z_cpc,
    z_lr,
    z_cpl,
    z_roas,
    z_aov,
    anomaly_score,
    anomaly,
    reason,

FROM ranked_anomalies
WHERE rank <=15
ORDER BY 
    year DESC, 
    rank ASC, 
    month