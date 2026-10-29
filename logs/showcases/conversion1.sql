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
		*,
		sum(is_new_session) OVER (
			PARTITION BY visitorid
			ORDER BY "timestamp"
			ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
		) AS session_id
	FROM start_flag
),
user_session AS (
	SELECT
		visitorid,
        session_id,
		count(*) AS count_events,
		count(*) FILTER (WHERE "event" = 'view') AS count_view,
		count(*) FILTER (WHERE "event" = 'addtocart') AS count_addtocart,
		count(*) FILTER (WHERE "event" = 'transaction') AS count_transactions	
	FROM events_session_id
	GROUP BY
		visitorid,
		session_id
),
conv AS (
	SELECT
		visitorid,
        session_id,
        CASE
        	WHEN count_view > 0 THEN 1.0
        	ELSE 0.0
        END AS is_view,
        CASE 
        	WHEN count_addtocart > 0 THEN 1.0
        	ELSE 0.0
        END AS is_addtocart,
        CASE
        	WHEN count_transactions > 0 THEN 1.0
        	ELSE 0.0
        END AS is_transactions
	FROM user_session
),
conv_per_user AS (
	SELECT
		sum(is_addtocart) / NULLIF(sum(is_view), 0) AS va_conv,
		sum(is_transactions) / NULLIF(sum(is_addtocart), 0) AS at_conv,
		sum(is_transactions) / NULLIF(sum(is_view), 0) AS vt_conv
	FROM conv
	GROUP BY visitorid
)
SELECT
	avg(va_conv),
	avg(at_conv),
	avg(vt_conv)
FROM conv_per_user;