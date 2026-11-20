Create database incident_analytics;
use incident_analytics

select * from raw_events;

USE incident_analytics;

DROP TABLE IF EXISTS clean_incidents;

CREATE TABLE clean_incidents AS
WITH case_summary AS (
    SELECT 
        `Case ID` AS case_id,
        MIN(STR_TO_DATE(`Timestamp`, '%d/%m/%Y %H:%i')) AS created_at,
        MAX(STR_TO_DATE(`Timestamp`, '%d/%m/%Y %H:%i')) AS resolved_at,
        COUNT(*) AS event_steps,
        MAX(`Variant`) AS variant,
        MAX(`Priority`) AS priority,
        MAX(`Issue Type`) AS issue_type,
        MAX(`Resolver`) AS resolver,
        MAX(`Report Channel`) AS report_channel,
        MAX(`Short Description`) AS short_description,
        MAX(`Customer Satisfaction`) AS csat_score
    FROM raw_events
    GROUP BY `Case ID`
)
SELECT 
    case_id,
    created_at,
    resolved_at,
    event_steps,
    variant,
    priority,
    issue_type,
    resolver,
    report_channel,
    short_description,
    csat_score,
    TIMESTAMPDIFF(HOUR, created_at, resolved_at) AS mttr_hours,
    CASE 
        WHEN priority IN ('Critical', 'High') AND TIMESTAMPDIFF(HOUR, created_at, resolved_at) > 8 THEN 1
        WHEN priority = 'Medium' AND TIMESTAMPDIFF(HOUR, created_at, resolved_at) > 24 THEN 1
        WHEN TIMESTAMPDIFF(HOUR, created_at, resolved_at) > 48 THEN 1
        ELSE 0 
    END AS sla_breached,
    HOUR(created_at) AS created_hour,
    DAYNAME(created_at) AS created_day
FROM case_summary
WHERE resolved_at > created_at;

SELECT COUNT(*) AS total_tickets, AVG(mttr_hours) AS avg_mttr, AVG(sla_breached) AS breach_rate 
FROM clean_incidents;

select * from clean_incidents;