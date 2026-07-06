-- Aufgabe 4: Hotels nach Performance anhand von Revenue, Leads und Conversion Rate in mindestens 4 Gruppen segmentieren.
-- total

-- aggregation of campaign metrics per hotel 
WITH campaign_hotel AS (
    SELECT
        hotel_id,
        SUM(COALESCE(impressions, 0)) AS total_impressions,
        SUM(COALESCE(clicks, 0)) AS total_clicks,
        SUM(COALESCE(leads, 0)) AS total_leads,
        SUM(COALESCE(cost, 0)) AS total_cost
    FROM campaign_performance
    GROUP BY hotel_id
),

-- aggregation of booking metrics per hotel
booking_hotel AS (
    SELECT
        hotel_id,
        COUNT(DISTINCT booking_id) AS total_bookings,
        SUM(COALESCE(revenue, 0)) AS total_revenue
    FROM booking_data
    GROUP BY hotel_id
),

hotel_metrics AS (
    SELECT
        hi.hotel_id,
        hi.country,
        hi.region,
        hi.hotel_category,

        COALESCE(ch.total_impressions, 0) AS total_impressions,
        COALESCE(ch.total_clicks, 0) AS total_clicks,
        COALESCE(ch.total_leads, 0) AS total_leads,
        COALESCE(ch.total_cost, 0) AS total_cost,

        COALESCE(bh.total_bookings, 0) AS total_bookings,
        COALESCE(bh.total_revenue, 0) AS total_revenue,

        CASE
            WHEN COALESCE(ch.total_leads, 0) = 0 THEN NULL
            ELSE CAST(COALESCE(bh.total_bookings, 0) AS DOUBLE)
                 / COALESCE(ch.total_leads, 0)
        END AS conversion_rate

    FROM hotel_information AS hi
    LEFT JOIN campaign_hotel AS ch
        ON hi.hotel_id = ch.hotel_id 
    LEFT JOIN booking_hotel AS bh
        ON hi.hotel_id = bh.hotel_id 
    WHERE hi.hotel_id IS NOT NULL
),

-- rank hotels into quartiles based on revenue, leads, and conversion rate
ranked_hotels AS (
    SELECT
        *,
        NTILE(4) OVER (ORDER BY total_revenue, hotel_id) AS revenue_q,
        NTILE(4) OVER (ORDER BY total_leads, hotel_id) AS leads_q,
        NTILE(4) OVER (ORDER BY conversion_rate, hotel_id) AS conversion_q
    FROM hotel_metrics
    WHERE total_leads > 0
),

-- calculate a performance score based on the quartiles of revenue, leads, and conversion rate
scored_hotels AS (
    SELECT
        *,
        revenue_q + leads_q + conversion_q AS performance_score
    FROM ranked_hotels
),

-- combine scored hotels with those that have no leads to create final segments
final_segments AS (
    SELECT
        hotel_id,
        country,
        region,
        hotel_category,

        total_impressions,
        total_clicks,
        total_leads,
        total_cost,

        total_bookings,
        total_revenue,
        conversion_rate,

        revenue_q,
        leads_q,
        conversion_q,
        performance_score,

        CASE
            WHEN performance_score >= 10 THEN '1 Top Performer'
            WHEN performance_score >= 8 THEN '2 High Performer'
            WHEN performance_score >= 6 THEN '3 Potential / Optimize'
            ELSE '4 Weak Performer'
        END AS segment_category

    FROM scored_hotels

    UNION ALL

    SELECT
        hotel_id,
        country,
        region,
        hotel_category,

        total_impressions,
        total_clicks,
        total_leads,
        total_cost,

        total_bookings,
        total_revenue,
        conversion_rate,

        NULL AS revenue_q,
        NULL AS leads_q,
        NULL AS conversion_q,
        NULL AS performance_score,

        '5 Gap' AS segment_category

    FROM hotel_metrics
    WHERE total_leads = 0
)

SELECT
    hotel_id,
    country,
    region,
    hotel_category,

    total_impressions,
    total_clicks,
    total_leads,
    ROUND(total_cost, 2) AS total_cost,
    total_bookings,
    ROUND(total_revenue, 2) AS total_revenue,
    ROUND(conversion_rate, 4) AS conversion_rate,

    revenue_q,
    leads_q,
    conversion_q,
    performance_score,

    segment_category

FROM final_segments

ORDER BY
    CASE segment_category
        WHEN '1 Top Performer' THEN 1
        WHEN '2 High Performer' THEN 2
        WHEN '3 Potential / Optimize' THEN 3
        WHEN '4 Weak Performer' THEN 4
        WHEN '5 Gap' THEN 5
    END,
    performance_score DESC,
    total_revenue DESC;