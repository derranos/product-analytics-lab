SELECT COUNT(*) AS row_count
FROM raw.retailrocket_events;

SELECT "event", count(*) AS event_count
FROM raw.retailrocket_events re
GROUP BY "event"
ORDER BY event_count DESC;

SELECT *
FROM  raw.retailrocket_events re 
LIMIT 10;