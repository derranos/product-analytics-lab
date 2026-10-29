SELECT 
	count(*) AS total_rows,
	count(*) FILTER (WHERE "timestamp" IS NULL) AS timestamp,
	count(*) FILTER (WHERE visitorid IS NULL) AS missing_visitorid,
	count(*) FILTER (WHERE "event" IS NULL) AS missing_event,
    count(*) FILTER (WHERE itemid IS NULL) AS missing_itemid,
    count(*) FILTER (WHERE transactionid IS NULL) AS missing_transactionid 
FROM raw.retailrocket_events re;

SELECT
	"event",
	count(*) FILTER (WHERE transactionid IS NOT NULL) AS count_transactionid 	
FROM raw.retailrocket_events re
GROUP BY "event"; 

SELECT
	"timestamp",
	visitorid,
	"event",
	itemid,
	transactionid,
	count(*) AS copies 
FROM raw.retailrocket_events re
--WHERE transactionid IS NOT NULL 
GROUP BY "timestamp", visitorid, "event", itemid, transactionid
HAVING count(*) > 1
ORDER BY copies DESC
LIMIT 10;

SELECT
	min("timestamp") AS start_timestamp_ms,
	max("timestamp") AS end_timestamp_ms,
	to_timestamp(min("timestamp") / 1000) AT time ZONE 'UTC' AS first_event_utc,
	to_timestamp(max("timestamp") / 1000) AT time ZONE 'UTC' AS last_event_utc,
	count(DISTINCT visitorid) AS unique_visitors,
	count(DISTINCT itemid) AS unique_items 
FROM raw.retailrocket_events re; 