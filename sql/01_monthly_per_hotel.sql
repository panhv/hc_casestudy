-- Aufgabe 1: Berechne monatlich pro Hotel Impressions, Clicks, Leads, Kosten, CTR, CPC und Conversion Rate

WITH monthly_campaign AS ( 
    SELECT 
        date_trunc('month', cp.date)::DATE AS month_date, -- truncate data to month to make grouping easier as campaign performance was collected every 7 days
        strftime(cp.date, '%B %Y') AS month_text,
        cp.hotel_id, 
        hi.country, 
        hi.region, 
        hi.hotel_category,
        SUM(cp.impressions) AS impressions, 
        SUM(cp.clicks) AS clicks, 
        SUM(cp.leads) AS leads, 
        SUM(cp.cost) AS cost 
    FROM campaign_performance AS cp 
    LEFT JOIN hotel_information AS hi 
        ON cp.hotel_id = hi.hotel_id
    GROUP BY month_date, cp.hotel_id, hi.country, hi.region, hi.hotel_category, month_text 
) 

SELECT 
    --month_date,
    month_text AS month,
    hotel_id,
    country,
    region,
    hotel_category,
    impressions,
    clicks,
    leads,
    ROUND(cost, 2) AS cost,
    ROUND(clicks / NULLIF(impressions, 0), 4) AS ctr,
    ROUND(cost / NULLIF(clicks, 0), 2) AS cpc, -- CPC = Cost / Clicks; NULLIF avoids dvision by 0 
    ROUND(leads / NULLIF(clicks, 0), 4) AS conversion_rate -- Conversion Rate = Leads / Clicks; NULLIF avoids dvision by 0
FROM monthly_campaign
ORDER BY month_date DESC, hotel_id::INT; 
