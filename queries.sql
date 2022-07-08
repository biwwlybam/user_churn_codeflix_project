SELECT *
FROM subscriptions
LIMIT 100;

--

SELECT
  MIN(subscription_start) AS earliest_start,
  MAX(subscription_end) AS latest_end
FROM subscriptions;

--earliest start: 2016-12-01
--latest end: 2017-03-31
--contains data from 12/2016 to 3/2017, four months

--

SELECT
  segment,
  COUNT(*) AS count
FROM subscriptions
GROUP BY segment;

--

WITH months AS
  (SELECT
    '2017-01-01' AS first_day,
    '2017-01-31' AS last_day
  UNION
  SELECT
    '2017-02-01' AS first_day,
    '2017-02-31' AS last_day
  UNION
  SELECT
    '2017-03-01' AS first_day,
    '2017-03-31' AS last_day
  ),
cross_join AS
  (SELECT *
  FROM subscriptions
  CROSS JOIN months
  ),
status AS
(SELECT
  id,
  first_day AS 'month',
  CASE
    WHEN (subscription_start < first_day)
      AND (
        subscription_end > first_day
        OR subscription_end IS NULL
      ) AND (
        segment IS 87
      ) THEN 1
      ELSE 0
    END AS is_active_87,
    CASE
    WHEN (subscription_start < first_day)
      AND (
        subscription_end > first_day
        OR subscription_end IS NULL
      ) AND (
        segment IS 30
      ) THEN 1
      ELSE 0
    END AS is_active_30,
    CASE
      WHEN subscription_end BETWEEN first_day AND last_day AND segment IS 87 THEN 1
      ELSE 0
    END AS is_canceled_87,
    CASE
      WHEN subscription_end BETWEEN first_day AND last_day AND segment IS 30 THEN 1
      ELSE 0
    END AS is_canceled_30
  FROM cross_join
),
status_aggregate AS
(SELECT 
    month, 
    SUM(is_active_87) AS sum_active_87,
    SUM(is_active_30) AS sum_active_30,
    SUM(is_canceled_87) AS sum_canceled_87,
    SUM(is_canceled_30) AS sum_canceled_30
  FROM status 
  GROUP BY month
)
SELECT
  month, 
  100.0 * sum_canceled_87 / sum_active_87 AS churn_rate_87,
  100.0 * sum_canceled_30 / sum_active_30 AS churn_rate_30
FROM status_aggregate;
