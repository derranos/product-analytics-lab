WITH events_with_lag AS (
	SELECT
		visitorid,
		"timestamp",
		"event",
		itemid,
		transactionid,
		lag("timestamp") OVER (
			PARTITION BY visitorid
			ORDER BY "timestamp"
		) AS previous_timestamp		
	FROM raw.retailrocket_events re 
),
start_flag AS (
	SELECT
		*,
		CASE
			WHEN previous_timestamp IS NULL THEN 1
			WHEN ("timestamp" - previous_timestamp) > 1800000 THEN 1
			ELSE 0
		END	AS is_new_session	
	FROM events_with_lag
),
events_session_id AS (
	SELECT
		visitorid,
		EXTRACT(ISODOW FROM TO_TIMESTAMP("timestamp" / 1000.0)) AS day_of_week,
		"event",
		itemid,
		transactionid,
		sum(is_new_session) OVER (
			PARTITION BY visitorid
			ORDER BY "timestamp"
			ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
		) AS session_id
	FROM start_flag
),
start_session AS (
	SELECT
		visitorid,
		"event",
		itemid,
		transactionid,
		session_id,
		FIRST_VALUE(day_of_week) OVER (
			PARTITION BY visitorid, session_id
			ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
		) AS session_day
	FROM events_session_id
),
user_session AS (
	SELECT
		visitorid,
        session_id,
        session_day,
		count(*) AS count_events,
		count(*) FILTER (WHERE "event" = 'view') AS count_view,
		count(*) FILTER (WHERE "event" = 'addtocart') AS count_addtocart,
		count(*) FILTER (WHERE "event" = 'transaction') AS count_transactions	
	FROM start_session
	GROUP BY
		visitorid,
		session_id,
		session_day
)
SELECT
	session_day,
	avg(count_events) AS avg_count_events,
	avg(count_view) AS avg_view_per_session,
	avg(count_addtocart) AS avg_addtocart_per_session,
	avg(count_transactions) AS avg_count_transactions_per_session,
	avg(count_addtocart) / avg(count_view) AS abs_va_conversion,
	avg(count_transactions) / avg(count_addtocart) AS abs_at_conversion,
	avg(count_transactions) / avg(count_view) AS abs_vt_conversion,
	avg(count_addtocart * 1.0 / NULLIF(count_view, 0)) AS va_conversion,
    avg(count_transactions * 1.0 / NULLIF(count_addtocart, 0)) AS at_conversion,
    avg(count_transactions * 1.0 / NULLIF(count_view, 0)) AS vt_conversion	
FROM user_session
GROUP BY session_day
ORDER BY session_day;