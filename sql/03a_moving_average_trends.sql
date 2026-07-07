-- Drei-Monats-Moving-Average über einen Zeitraum von MINDESTENS drei Monaten

-- aggregation of monthly leads per hotel 
WITH campaign_monthly AS (
    SELECT
        hotel_id, 
        date_trunc('month', date)::DATE AS month, 
        SUM(leads) AS leads 
    FROM campaign_performance 
    GROUP BY hotel_id, month
),

-- ggregation of monthly revenue per hotel 
booking_monthly AS ( 
    SELECT 
        hotel_id, 
        date_trunc('month', booking_date)::DATE AS month,
        SUM(revenue) AS revenue
    FROM booking_data 
    GROUP BY hotel_id, month
), 

-- combine months from both campaign and booking data to ensure we have a complete timeline for each hotel
all_months_raw AS ( 
    SELECT month FROM campaign_monthly 
    UNION 
    SELECT month FROM booking_monthly
), 

-- identify start and end months
date_bounds AS (
    SELECT 
        MIN(month) AS start_month, 
        MAX(month) AS end_month 
    FROM all_months_raw 
),

--create a month spine to ensure all months are represented in case of missing data for some hotels
month_spine AS ( 
    SELECT 
        month::DATE AS month 
    FROM generate_series( 
        (SELECT start_month FROM date_bounds), 
        (SELECT end_month FROM date_bounds),
        INTERVAL '1 month' 
    ) AS t(month)
), 

-- create a cross join of all hotels with the month spine to ensure every hotel has an entry for each month
hotel_months AS ( 
    SELECT 
        hi.hotel_id, 
        hi.country, 
        hi.region, 
        hi.hotel_category, 
        ms.month 
    FROM hotel_information AS hi 
    CROSS JOIN month_spine AS ms 
), 

-- combine leads and revenue per hotel per month based on month_spine 
base_monthly AS ( 
    SELECT 
        hm.month,
        hm.hotel_id, 
        hm.country, 
        hm.region,
        hm.hotel_category,
        COALESCE(cm.leads, 0) AS leads, 
        COALESCE(bm.revenue, 0) AS revenue 
    FROM hotel_months AS hm 
    LEFT JOIN campaign_monthly AS cm 
        ON hm.hotel_id = cm.hotel_id 
       AND hm.month = cm.month
    LEFT JOIN booking_monthly AS bm 
        ON hm.hotel_id = bm.hotel_id 
       AND hm.month = bm.month 
), 

-- calculate 3-month moving averages for leads and revenue per hotel
moving_average AS ( 
    SELECT 
        *,
        AVG(leads) OVER hotel_window AS leads_3m_mov_av, 
        AVG(revenue) OVER hotel_window AS revenue_3m_mov_av,
        ROW_NUMBER() OVER (PARTITION BY hotel_id ORDER BY month) AS row_num
    FROM base_monthly
    WINDOW hotel_window AS ( 
        PARTITION BY hotel_id 
        ORDER BY month 
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW 
    ) 
),

-- calculate previous month's moving averages for leads and revenue per hotel 
with_previous AS (
    SELECT 
        *, 
        LAG(leads_3m_mov_av) OVER (PARTITION BY hotel_id ORDER BY month) AS prev_leads_3m_mov_av, 
        LAG(revenue_3m_mov_av) OVER (PARTITION BY hotel_id ORDER BY month) AS prev_revenue_3m_mov_av 
    FROM moving_average 
),

-- assigning trends 
monthly_trend AS (
    SELECT 
        *,
        CASE 
            WHEN row_num < 4 THEN 'Trend not possible' -- Die ersten 3 Monate bauen den gleitenden Durchschnitt erst auf
            WHEN leads_3m_mov_av > prev_leads_3m_mov_av AND revenue_3m_mov_av > prev_revenue_3m_mov_av THEN 'increasing'
            WHEN leads_3m_mov_av < prev_leads_3m_mov_av AND revenue_3m_mov_av < prev_revenue_3m_mov_av THEN 'decreasing'
            WHEN leads_3m_mov_av > prev_leads_3m_mov_av AND revenue_3m_mov_av < prev_revenue_3m_mov_av THEN 'leads increase, revenue decrease'
            WHEN leads_3m_mov_av < prev_leads_3m_mov_av AND revenue_3m_mov_av > prev_revenue_3m_mov_av THEN 'leads decrease, revenue increase'
            ELSE 'stable/mixed'
        END AS single_month_trend
    FROM with_previous
),

-- creating islands and gaps: 
-- unique group ids for same consecutive trends
trend_groups AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (PARTITION BY hotel_id ORDER BY month) - 
        ROW_NUMBER() OVER (PARTITION BY hotel_id, single_month_trend ORDER BY month) AS trend_group_id
    FROM monthly_trend
),

-- identifying total numbers of ongoing trend and current month in trend 
trend_duration AS (
    SELECT 
        *,
        COUNT(*) OVER (PARTITION BY hotel_id, single_month_trend, trend_group_id) AS total_months_in_trend,
        ROW_NUMBER() OVER (PARTITION BY hotel_id, single_month_trend, trend_group_id ORDER BY month) AS current_month_in_trend
    FROM trend_groups
)

SELECT 
    month, 
    hotel_id, 
    country, 
    region, 
    hotel_category, 
    leads, 
    ROUND(revenue, 2) AS revenue,

    ROUND(leads_3m_mov_av, 2) AS leads_3m_mov_av, 
    ROUND(revenue_3m_mov_av, 2) AS revenue_3m_mov_av,     

    -- difference between current and previous 3-month-moving average
    ROUND((leads_3m_mov_av - prev_leads_3m_mov_av), 2) AS leads_3m_diff_abs, 
    ROUND((revenue_3m_mov_av - prev_revenue_3m_mov_av), 2) AS revenue_3m_diff_abs,    

    -- difference between current and previous 3-month-moving average in pct
    ROUND((leads_3m_mov_av - prev_leads_3m_mov_av) / NULLIF(prev_leads_3m_mov_av, 0), 2) AS leads_3m_diff_pct, 
    ROUND((revenue_3m_mov_av - prev_revenue_3m_mov_av) / NULLIF(prev_revenue_3m_mov_av, 0), 2) AS revenue_3m_diff_pct, 

    total_months_in_trend AS total_months_in_current_trend,
    current_month_in_trend,

    CASE
        WHEN single_month_trend = 'Trend not possible' THEN 'Trend not possible'
        WHEN total_months_in_trend >= 3 THEN single_month_trend || ' (Phase of ' || total_months_in_trend || ' months)'
        ELSE 'No sustaining trend (< 3 months)'
    END AS consecutive_trend
    

FROM trend_duration 
ORDER BY hotel_id::INT, month;
