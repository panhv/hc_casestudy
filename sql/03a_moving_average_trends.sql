-- Aufgabe 3: Drei-Monats-Moving-Average für Leads und Revenue plus Trendlabel

-- aggregation of leads per hotel per month from campaign data
WITH campaign_monthly AS (
    SELECT
        hotel_id, 
        date_trunc('month', date)::DATE AS month, 
        SUM(leads) AS leads 
    FROM campaign_performance 
    GROUP BY hotel_id, month
),

-- aggregation of revenue per hotel per month from booking data
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

-- create a month spine to ensure all months are represented in case of missing data for some hotels
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

-- combine leads and revenue per hotel per month
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
        COUNT(*) OVER hotel_window AS months_in_window 
    FROM base_monthly
    WINDOW hotel_window AS ( 
        PARTITION BY hotel_id 
        ORDER BY month 
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW 
    ) 
),
-- calculate previous month's moving averages for leads and revenue per hotel
with_prev_mov_av AS (
    SELECT 
        *, 
        LAG(leads_3m_mov_av) OVER (PARTITION BY hotel_id ORDER BY month) AS prev_leads_3m_mov_av, 
        LAG(revenue_3m_mov_av) OVER (PARTITION BY hotel_id ORDER BY month) AS prev_revenue_3m_mov_av 
    FROM moving_average 
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
    ROUND(leads_3m_mov_av - prev_leads_3m_mov_av, 2) AS leads_3m_diff_abs, 
    ROUND(revenue_3m_mov_av - prev_revenue_3m_mov_av, 2) AS revenue_3m_diff_abs, 

    ROUND((leads_3m_mov_av - prev_leads_3m_mov_av) / NULLIF(prev_leads_3m_mov_av, 0), 2) AS leads_3m_diff_pct, 
    ROUND((revenue_3m_mov_av - prev_revenue_3m_mov_av) / NULLIF(prev_revenue_3m_mov_av, 0), 2) AS revenue_3m_diff_pct, 

    CASE
        WHEN months_in_window < 3 THEN 'Trend not possible'
        WHEN leads_3m_diff_abs > 0 AND revenue_3m_diff_abs > 0 THEN 'increasing'
        WHEN leads_3m_diff_abs < 0 AND revenue_3m_diff_abs < 0 THEN 'decreasing'

        WHEN leads_3m_diff_abs > 0 AND revenue_3m_diff_abs < 0 THEN 'leads increase, revenue decrease'
        WHEN leads_3m_diff_abs < 0 AND revenue_3m_diff_abs > 0 THEN 'leads decrease, revenue increase'
        ELSE 'stable/mixed'

        /*WHEN leads_3m_diff_abs = 0 AND revenue_3m_diff_abs = 0 THEN 'leads and revenue stable'
        WHEN leads_3m_diff_abs = 0 AND revenue_3m_diff_abs > 0 THEN 'leads stable, revenue increase'
        WHEN leads_3m_diff_abs = 0 AND revenue_3m_diff_abs < 0 THEN 'leads stable, revenue decrease'
        WHEN leads_3m_diff_abs > 0 AND revenue_3m_diff_abs = 0 THEN 'leads increase, revenue stable'
        WHEN leads_3m_diff_abs < 0 AND revenue_3m_diff_abs = 0 THEN 'leads decrease, revenue stable' */


    END AS trend_3M_mov_av

FROM with_prev_mov_av 
ORDER BY hotel_id::INT, month;
