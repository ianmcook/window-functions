-- SQL Window Functions

-- Ian Cook
-- ianmcook@gmail.com

-- see the data
SELECT * FROM daylight;

-- how many hours of daylight on a particular day (for example March 11)?
SELECT light FROM daylight WHERE month=3 AND day=11;

-- for a visualization of this data, see:
-- https://gist.github.com/ianmcook/41468bb4d1e8b6d94c9f8261dd402788

-- standard aggregation example: max daylight for each month 
SELECT month, MAX(light)
	FROM daylight 
	GROUP BY month
	ORDER BY month;
-- groups sets of rows together into single rows
-- individual row values are not included in the output

-- which day in each month does the max occur on?

-- simple window function example: max daylight for each month 
SELECT month, day,
		MAX(light) OVER(PARTITION BY month) AS month_max
	FROM daylight
	ORDER BY month, day;
-- window functions (aka analytic functions) are applied over sets of rows without combining them
-- individual row values can be included in the output

-- return only the row for the day with the max daylight in each month

-- doesn't work; window expressions not allowed in WHERE clause
-- SELECT month, day, light
--  	FROM daylight
-- 	WHERE light = MAX(light) OVER(PARTITION BY month);

-- workaround: put it in the SELECT list
SELECT month, day, light,
		light = MAX(light) OVER(PARTITION BY month) AS is_max
	FROM daylight
	ORDER BY month, day;

-- doesn't work; can't use column created with window function in WHERE clause 
-- SELECT month, day, light,
-- 		light = MAX(light) OVER(PARTITION BY month) AS is_max
-- 	FROM daylight
-- 	WHERE is_max
-- 	ORDER BY month;

-- workaround: use a subquery
SELECT * FROM (
	SELECT month, day, light,
			light = MAX(light) OVER(PARTITION BY month) AS is_max
		FROM daylight) x 
	WHERE is_max
	ORDER BY month;
-- this demonstrates the partitioning part of a window specification 

-- instead of finding the max for each month, find the max for the whole year
SELECT month, day, light,
		light = MAX(light) OVER() AS is_max
	FROM daylight
	ORDER BY month, day;
-- empty OVER() expression makes one partition from whole dataset

-- use a subquery to get the day with the most daylight
SELECT * FROM (
		SELECT month, day, light,
			light = MAX(light) OVER() AS is_max
		FROM daylight) x 
	WHERE is_max;

-- same but with MIN instead of MAX
SELECT * FROM (
		SELECT month, day, light,
			light = MIN(light) OVER() AS is_min
		FROM daylight) x 
	WHERE is_min;

-- difference between daylight each day vs. day with least daylight 
SELECT month, day, light,
		light - MIN(light) OVER() AS diff
	FROM daylight;

-- what is the day in June with the second most daylight?
SELECT month, day, light,
		RANK() OVER(PARTITION BY month ORDER BY light DESC) AS rank
	FROM daylight
	WHERE month = 6;
-- this demonstrates the ordering part of a window specification
-- and demonstrates the window function RANK()

-- try some other window functions besides RANK()

-- in the above example, try changing light to round(light * 60) to create ties
-- in the rank column

-- then try using DENSE_RANK() instead of RANK() and observe the difference:
-- RANK() skips values after ties whereas DENSE_RANK() returns consecutive values

-- also try ROW_NUMBER() which is similar to RANK() but numbers all rows
-- sequentially in the case of ties (the numbering is arbitrary within ties)

-- try using PERCENT_RANK() which returns the proportion of values in the partition
-- that are smaller than the value in the current row, excluding the highest value

-- try using CUME_DIST() which is similar to PERCENT_RANK(); it returns the
-- cumulative distribution of a value, in other words the proportion of values in
-- the partition that is less than or equal to the value in the current row

-- try using `NTILE()` which returns the n-tile (n-quantile) within the window that the
-- current value is in; this places the values as evenly as possible into n divisions
-- for example: quartile (n=4), quintile (n=5), decile (n=10), percentile (n=100)
-- use this to answer questions like:
-- which days in June are in the fourth quartile of days with the most daylight?

-- now use the above in a subquery to directly answer the question posed above
-- (what is the day in June with the second most daylight?)
SELECT * FROM (
		SELECT month, day, light,
			RANK() OVER(PARTITION BY month ORDER BY light DESC) AS rank
		FROM daylight
		WHERE month = 6) x
	WHERE rank = 2;

-- how much more or less light was there today compared to yesterday?
SELECT month, day, light, 
		LAG(light, 1) OVER(ORDER BY month, day) AS light_yesterday
	FROM daylight;
-- this demonstrates the offset function LAG()

-- try some other offset functions besides LAG()

-- try using LEAD() to find the hours of light tomorrow

-- try changing the offset to something other than 1

-- try using the third argument to LEAD() or LAG() to specify a default value,
-- used when the lead or lag extends past the end of the window (default is NULL)

-- try using FIRST_VALUE() and LAST_VALUE() which return the first and last
-- values of the specified column in the window, and NTH_VALUE() which generalizes
-- this to the nth value in the window

-- calculate difference from yesterday in minutes
SELECT month, day,
		(light - LAG(light, 1) OVER(ORDER BY month, day)) * 60 AS daylight_diff_mins
	FROM daylight;

-- how much more or less light was there today compared to the same day last month?
SELECT month, day,
		(light - LAG(light, 1) OVER(PARTITION BY day ORDER BY month)) * 60 AS daylight_diff_mins
	FROM daylight
	ORDER BY month, day;

-- for the 11th day of each month
SELECT * FROM (
		SELECT month, day,
			(light - LAG(light, 1) OVER(PARTITION BY day ORDER BY month)) * 60 AS daylight_diff_mins
		FROM daylight) x
	WHERE day = 11;

-- what's the weekly moving average hours of light?
SELECT month, day, light, 
		AVG(light) OVER(ORDER BY month, day ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS weekly_moving_avg
	FROM daylight
	ORDER BY month, day;
-- this demonstrates the frame boundaries part of a window specification 

-- what's the annual cumulative hours of daylight each day?
SELECT month, day, light, 
		SUM(light) OVER(ORDER BY month, day ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_daylight
	FROM daylight
	ORDER BY month, day;

-- what's the monthly cumulative hours of daylight each day?
SELECT month, day, light, 
		SUM(light) OVER(PARTITION BY month ORDER BY day ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_daylight
	FROM daylight
	ORDER BY month, day;

-- difference between ROWS and RANGE:
-- ROWS limits rows within a partition by specifying a fixed number of rows preceding and/or following the current row
-- RANGE limits rows within a partition by specifying a range of values with respect to the value in the current row
-- Preceding and following rows are defined based on the ordering specified with ORDER BY

-- need to use data with ties to demonstrate the difference between ROWS and RANGE
SELECT month, COUNT(day) AS days FROM daylight GROUP BY month ORDER BY month;

-- first demonstrate ROWS

-- how many days in this month and all preceding months in the year?
SELECT month, days, 
		SUM(days) OVER(ORDER BY month ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS days_in_this_and_preceding_months
	FROM (SELECT month, COUNT(day) AS days FROM daylight GROUP BY month) AS day_counts ORDER BY month;
-- this is a cumulative sum from top to bottom

-- how many days in this month and all following months in the year?
SELECT month, days, 
		SUM(days) OVER(ORDER BY month ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING) AS days_in_this_and_following_months
	FROM (SELECT month, COUNT(day) AS days FROM daylight GROUP BY month) AS day_counts ORDER BY month;
-- this is a cumulative sum from bottom to top

-- now demonstrate RANGE

-- order the data by days instead of month
SELECT month, COUNT(day) AS days FROM daylight GROUP BY month ORDER BY days, month;

-- how many days in this month and all other months that have the same number of days or fewer?
SELECT month, days, 
		SUM(days) OVER(ORDER BY days RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_months
	FROM (SELECT month, COUNT(day) AS days FROM daylight GROUP BY month) AS day_counts ORDER BY days, month;

-- how many days in this month and all other months that have the same number of days or more?
SELECT month, days, 
		SUM(days) OVER(ORDER BY days RANGE BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING) AS cumulative_months
	FROM (SELECT month, COUNT(day) AS days FROM daylight GROUP BY month) AS day_counts ORDER BY days, month;

-- some query engines implement even more windowing techniques, including:
--   WINDOW clause (named windows)
--   GROUPS frame type
--   EXCLUDE clause
--   FILTER clause
--   window chaining (defining one window in terms of another)

-- for more information about these, see:
--   https://duckdb.org/docs/sql/window_functions
--   https://www.sqlite.org/windowfunctions.html
