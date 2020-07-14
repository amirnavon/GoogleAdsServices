USE GoogleAdsServices
GO

SELECT*
FROM advertiser_stats

SELECT TOP 100 *
FROM creative_stats

-------------------------------------------------
------------------------1------------------------
-------------------------------------------------
; WITH "CTE" AS
(
SELECT regions, advertiser_id, advertiser_name, 
		COUNT(ad_id) AS 'num_of_ads'
FROM creative_stats
WHERE regions='US'
GROUP BY regions, advertiser_id, advertiser_name
HAVING  COUNT(ad_id) > 100
)
SELECT COUNT(*) AS "num_of_advertisers_morethan100cre"
FROM CTE

-------------------------------------------------
------------------------2------------------------
-------------------------------------------------
; WITH "in_us" AS
(
SELECT	regions, advertiser_id, advertiser_name, 
		COUNT(ad_id) AS 'num_of_ads'
FROM creative_stats
WHERE regions='US'
GROUP BY regions, advertiser_id, advertiser_name
), "in_us_more100ads" AS
(
SELECT COUNT(*) AS "total_in_us_more100ads"
FROM in_us
WHERE num_of_ads>100
)
SELECT	total_in_us_more100ads, 
		(SELECT COUNT(*) FROM in_us) AS "total_in_us",
		CAST(ROUND(CAST(total_in_us_more100ads AS float) / 
			CAST((SELECT COUNT(*) FROM in_us) AS float), 4)*100 AS NVARCHAR(10)) + '%' AS "precentage"
FROM in_us_more100ads

-------------------------------------------------
------------------------3------------------------
-------------------------------------------------
SELECT advertiser_id, advertiser_name, COUNT(*) AS 'dated_video_ads'
FROM creative_stats
WHERE ad_type='Video' AND date_range_start='2018-10-04'
GROUP BY advertiser_id, advertiser_name
HAVING COUNT(*)=2

-------------------------------------------------
------------------------4a-----------------------
-------------------------------------------------
;WITH "CTE" AS
(
SELECT TOP 1 advertiser_id, advertiser_name, spend_range_min_usd, 
	DATENAME(MONTH, date_range_start) 'start_month',
	SUM(spend_range_min_usd) OVER (PARTITION BY DATENAME(MONTH, date_range_start)) AS 'total_start_month_video_2019'
FROM creative_stats
WHERE YEAR(date_range_start)=2019 AND ad_type='Video'
ORDER BY SUM(spend_range_min_usd) OVER (PARTITION BY DATENAME(MONTH, date_range_start))
)
SELECT start_month AS '2019_min_spend_month', total_start_month_video_2019
FROM CTE

-------------------------------------------------
------------------------4b-----------------------
-------------------------------------------------
;WITH "CTE" AS
(
SELECT spend_range_min_usd,
	CASE	
		WHEN YEAR(date_range_start)=2019 THEN DATENAME(MONTH, date_range_start)
		WHEN YEAR(date_range_end)=2019 THEN DATENAME(MONTH, date_range_end) 
	END AS 'month_StartOrEnd_2019'
FROM creative_stats
WHERE	ad_type='Video' AND
		(YEAR(date_range_start)=2019 
		OR YEAR(date_range_end)=2019)
)
SELECT TOP 1 SUM(spend_range_min_usd) 'total_min_spend_monthly', 
			Month_StartOrEnd_2019
FROM CTE
GROUP BY Month_StartOrEnd_2019
ORDER BY SUM(spend_range_min_usd)

-------------------------------------------------
------------------------5------------------------
-------------------------------------------------
SELECT TOP 1 C.advertiser_id, C.advertiser_name,A.elections, 
		COUNT(*) 'total_video_2019_UsFed'
FROM creative_stats C JOIN advertiser_stats A ON C.advertiser_id=A.advertiser_id
WHERE	YEAR(date_range_start)=2019 
		AND ad_type='Video' 
		AND A.elections='US-Federal'
GROUP BY C.advertiser_id, C.advertiser_name,A.elections
ORDER BY COUNT(*) DESC

-------------------------------------------------
------------------------6------------------------
-------------------------------------------------
SELECT	COUNT(*) 'total_count', 
		MONTH(date_range_start) 'Month',
		SUM(COUNT(*)) OVER (ORDER BY MONTH(date_range_start)) AS 'cml_cnt_month_vid2019'
FROM	creative_stats
WHERE	YEAR(date_range_start)=2019 AND ad_type='Video' 
GROUP BY MONTH(date_range_start)
ORDER BY MONTH(date_range_start)

-------------------------------------------------
------------------------7------------------------
-------------------------------------------------
;WITH "CTE1" AS
(
SELECT advertiser_id, date_range_start,
	LAG(date_range_start) OVER (PARTITION BY advertiser_id ORDER BY date_range_start) AS 'lag_day_of_same_user',
	DATEDIFF(DAY,LAG(date_range_start) OVER (PARTITION BY advertiser_id ORDER BY date_range_start),date_range_start) AS 'diff_days'
FROM creative_stats
WHERE date_range_start BETWEEN '2019-01-01' AND '2019-01-08'
), "CTE2" AS
(
SELECT COUNT(DISTINCT advertiser_id) AS 'total_in_period',
	(SELECT COUNT(DISTINCT advertiser_id) FROM CTE1 WHERE diff_days=1) AS 'total_1day_follow'
FROM CTE1
)
SELECT total_1day_follow, total_in_period,
	CAST(CAST(total_1day_follow AS float) / CAST(total_in_period AS float)*100 AS NVARCHAR(10)) + '%' AS 'precentage'
FROM CTE2
