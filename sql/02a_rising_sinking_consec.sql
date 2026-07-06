-- Aufgabe 2: Hotels mit steigenden Kosten und sinkenden Leads über mindestens drei Monate

-- aggregation of cost and leads per hotel per month
WITH monthly_campaign AS (
    SELECT 
        date_trunc('month', date)::DATE AS month,
        hotel_id,
        SUM(cost) AS cost,
        SUM(leads) AS leads
    FROM campaign_performance
    GROUP BY 
        date_trunc('month', date)::DATE,
        hotel_id
),

-- calculate lagged values for cost and leads to compare over three months
with_lags AS (
    -- calculate lagged values for cost and leads to compare over three months
    SELECT 
        month,
        hotel_id,
        cost,
        leads,

        LAG(month, 1) OVER hotel_month_window AS month_prev_1,
        LAG(month, 2) OVER hotel_month_window AS month_prev_2,

        LAG(cost, 1) OVER hotel_month_window AS cost_prev_1,
        LAG(cost, 2) OVER hotel_month_window AS cost_prev_2,

        LAG(leads, 1) OVER hotel_month_window AS leads_prev_1,
        LAG(leads, 2) OVER hotel_month_window AS leads_prev_2

    FROM monthly_campaign

    WINDOW hotel_month_window AS (
        PARTITION BY hotel_id 
        ORDER BY month
    )
),

-- filter for hotels with rising costs and sinking leads over three months
flagged AS (
    SELECT
        *,
        -- calculate absolute cost increase and leads drop
        cost - cost_prev_2 AS abs_cost_increase,
        leads_prev_2 - leads AS abs_leads_drop,

        -- calculate percentage cost increase and leads drop
        (cost - cost_prev_2) / NULLIF(cost_prev_2, 0) AS pct_cost_increase,
        (leads_prev_2 - leads) / NULLIF(leads_prev_2, 0) AS pct_leads_drop,

        -- calculate anomaly score based on cost increase and leads drop   
        COALESCE((cost - cost_prev_2) / NULLIF(cost_prev_2, 0), 0)
        +
        COALESCE((leads_prev_2 - leads) / NULLIF(leads_prev_2, 0), 0)
        AS ano_score_pct -- anomaly score based on cost increase and leads drop, the higher the score, the more severe the anomaly

    FROM with_lags
    -- filtering for specific conditions: rising costs and sinking leads over three months
    WHERE 
        -- checking for consecutive months
        month_prev_1 = month - INTERVAL '1 month'
        AND month_prev_2 = month - INTERVAL '2 month'

        -- checking for consecutive increasing costs over three months
        -- Month 1 < Month 2 < Month 3
        AND cost_prev_2 < cost_prev_1
        AND cost_prev_1 < cost

        -- checking for consecutive sinking leads over three months
        -- Month 1 > Month 2 > Month 3
        AND leads_prev_2 > leads_prev_1
        AND leads_prev_1 > leads

),

-- rank the flagged hotels based on the severity of the anomaly score
ranked_windows AS (
    SELECT
        f.month_prev_2 AS month_1, 
        f.month_prev_1 AS month_2,
        f.month AS month_3,


        f.hotel_id,
        hi.country,
        hi.region,
        hi.hotel_category,

        f.cost_prev_2,
        f.cost_prev_1,
        f.cost,

        f.leads_prev_2,
        f.leads_prev_1,
        f.leads,

        f.abs_cost_increase,
        f.abs_leads_drop,
        f.pct_cost_increase,
        f.pct_leads_drop,
        f.ano_score_pct,

        ROW_NUMBER() OVER (
            PARTITION BY f.hotel_id
            ORDER BY f.ano_score_pct DESC
        ) AS hotel_rank

    FROM flagged AS f

    LEFT JOIN hotel_information AS hi
        ON f.hotel_id = hi.hotel_id
)

SELECT
    hotel_id,
    country,
    region,
    hotel_category,

    month_1,
    month_2,
    month_3,
    ROUND(cost_prev_2, 2) AS cost_month_1,
    ROUND(cost_prev_1, 2) AS cost_month_2,
    ROUND(cost, 2) AS cost_month_3,

    leads_prev_2 AS leads_month_1,
    leads_prev_1 AS leads_month_2,
    leads AS leads_month_3,

    ROUND(abs_cost_increase, 2) AS abs_cost_increase,
    abs_leads_drop,

    ROUND(pct_cost_increase, 4) AS pct_cost_increase,
    ROUND(pct_leads_drop, 4) AS pct_leads_drop,

    ROUND(ano_score_pct, 4) AS ano_score_pct

FROM ranked_windows

-- show only the most anomalous three-month pattern for each hotel
WHERE hotel_rank = 1

ORDER BY ano_score_pct DESC

LIMIT 10;