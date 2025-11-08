COPY online_shoppers_intention
FROM 'C:\\Program Files\\PostgreSQL\\17\\data\\online_shoppers_intention.csv'
DELIMITER ',' CSV HEADER ENCODING 'UTF8';

-- ======================================================
-- Diagnostic & Robust ETL for online_shoppers_intention
-- Run this whole block in pgAdmin → Query Tool
-- It will: detect/clean month/visitor/weekend/revenue -> fill dims -> check matches -> fill fact
-- ======================================================

-- --------- A. basic sanity checks ----------
SELECT 'raw_count' AS what, COUNT(*) AS how_many FROM online_shoppers_intention;

-- show distinct raw months (with length and hex) to detect hidden chars
SELECT DISTINCT month,
       length(coalesce(month,'')) AS len,
       octet_length(coalesce(month,'')) AS oct_len,
       encode(convert_to(coalesce(month,''),'UTF8'),'hex') AS hex
FROM online_shoppers_intention
ORDER BY month NULLS LAST
LIMIT 200;

-- --------- B. build temporary normalized-month map ----------
DROP TABLE IF EXISTS tmp_month_map;
CREATE TEMP TABLE tmp_month_map AS
SELECT DISTINCT
    month AS raw_month,
    LOWER(TRIM(REGEXP_REPLACE(COALESCE(month,''), '[^A-Za-z]', '', 'g'))) AS raw_clean,
    CASE
      WHEN LOWER(TRIM(REGEXP_REPLACE(COALESCE(month,''), '[^A-Za-z]', '', 'g'))) LIKE 'jan%' THEN 'jan'
      WHEN LOWER(TRIM(REGEXP_REPLACE(COALESCE(month,''), '[^A-Za-z]', '', 'g'))) LIKE 'feb%' THEN 'feb'
      WHEN LOWER(TRIM(REGEXP_REPLACE(COALESCE(month,''), '[^A-Za-z]', '', 'g'))) LIKE 'mar%' THEN 'mar'
      WHEN LOWER(TRIM(REGEXP_REPLACE(COALESCE(month,''), '[^A-Za-z]', '', 'g'))) LIKE 'apr%' THEN 'apr'
      WHEN LOWER(TRIM(REGEXP_REPLACE(COALESCE(month,''), '[^A-Za-z]', '', 'g'))) LIKE 'may%' THEN 'may'
      WHEN LOWER(TRIM(REGEXP_REPLACE(COALESCE(month,''), '[^A-Za-z]', '', 'g'))) LIKE 'jun%' THEN 'jun'
      WHEN LOWER(TRIM(REGEXP_REPLACE(COALESCE(month,''), '[^A-Za-z]', '', 'g'))) LIKE 'jul%' THEN 'jul'
      WHEN LOWER(TRIM(REGEXP_REPLACE(COALESCE(month,''), '[^A-Za-z]', '', 'g'))) LIKE 'aug%' THEN 'aug'
      WHEN LOWER(TRIM(REGEXP_REPLACE(COALESCE(month,''), '[^A-Za-z]', '', 'g'))) LIKE 'sep%' OR LOWER(TRIM(REGEXP_REPLACE(COALESCE(month,''), '[^A-Za-z]', '', 'g'))) LIKE 'sept%' THEN 'sep'
      WHEN LOWER(TRIM(REGEXP_REPLACE(COALESCE(month,''), '[^A-Za-z]', '', 'g'))) LIKE 'oct%' THEN 'oct'
      WHEN LOWER(TRIM(REGEXP_REPLACE(COALESCE(month,''), '[^A-Za-z]', '', 'g'))) LIKE 'nov%' THEN 'nov'
      WHEN LOWER(TRIM(REGEXP_REPLACE(COALESCE(month,''), '[^A-Za-z]', '', 'g'))) LIKE 'dec%' THEN 'dec'
      ELSE NULL
    END AS month_code
FROM online_shoppers_intention
ORDER BY raw_clean;

-- show the mapping (what raw looks like -> cleaned)
SELECT * FROM tmp_month_map ORDER BY raw_clean LIMIT 200;

-- count unmatched raw months
SELECT COUNT(*) AS unmatched_month_rows FROM tmp_month_map WHERE month_code IS NULL;
SELECT * FROM tmp_month_map WHERE month_code IS NULL LIMIT 200;

-- --------- C. Build (or refresh) dim_month using mapped month_code ----------
-- If you prefer fixed canonical months, we insert them explicitly (safe).
TRUNCATE dim_month RESTART IDENTITY CASCADE;
INSERT INTO dim_month (month_name)
VALUES ('jan'),('feb'),('mar'),('apr'),('may'),('jun'),('jul'),('aug'),('sep'),('oct'),('nov'),('dec');

SELECT * FROM dim_month ORDER BY month_name;

-- --------- D. normalize visitor_type into temp then dim ----------
DROP TABLE IF EXISTS tmp_visitor_map;
CREATE TEMP TABLE tmp_visitor_map AS
SELECT DISTINCT visitortype AS raw_visitor,
       LOWER(TRIM(REGEXP_REPLACE(COALESCE(visitortype,''), '[^A-Za-z0-9_]', '', 'g'))) AS visitor_clean
FROM online_shoppers_intention
ORDER BY visitor_clean;

SELECT * FROM tmp_visitor_map LIMIT 200;

TRUNCATE dim_visitor_type RESTART IDENTITY CASCADE;
INSERT INTO dim_visitor_type (visitor_type)
SELECT DISTINCT visitor_clean FROM tmp_visitor_map WHERE visitor_clean <> '' ORDER BY visitor_clean;

SELECT * FROM dim_visitor_type;

-- --------- E. normalize weekend & revenue -> dim ----------
DROP TABLE IF EXISTS tmp_bool_map;
CREATE TEMP TABLE tmp_bool_map AS
SELECT DISTINCT
  LOWER(TRIM(COALESCE(CAST(weekend AS TEXT), ''))) AS raw_weekend_text,
  CASE WHEN LOWER(TRIM(COALESCE(CAST(weekend AS TEXT), ''))) IN ('t','true','1','yes') THEN true
       WHEN LOWER(TRIM(COALESCE(CAST(weekend AS TEXT), ''))) IN ('f','false','0','no') THEN false
       ELSE NULL END AS weekend_bool,
  LOWER(TRIM(COALESCE(CAST(revenue AS TEXT), ''))) AS raw_revenue_text,
  CASE WHEN LOWER(TRIM(COALESCE(CAST(revenue AS TEXT), ''))) IN ('t','true','1','yes') THEN true
       WHEN LOWER(TRIM(COALESCE(CAST(revenue AS TEXT), ''))) IN ('f','false','0','no') THEN false
       ELSE NULL END AS revenue_bool
FROM online_shoppers_intention;

SELECT * FROM tmp_bool_map;

TRUNCATE dim_weekend RESTART IDENTITY CASCADE;
TRUNCATE dim_revenue RESTART IDENTITY CASCADE;

INSERT INTO dim_weekend (weekend)
SELECT DISTINCT weekend_bool FROM tmp_bool_map WHERE weekend_bool IS NOT NULL;

INSERT INTO dim_revenue (revenue)
SELECT DISTINCT revenue_bool FROM tmp_bool_map WHERE revenue_bool IS NOT NULL;

SELECT * FROM dim_weekend;
SELECT * FROM dim_revenue;

-- --------- F. Before inserting facts: check how many rows WOULD match all dims ----------
-- join using the same normalizations we used above (month via tmp_month_map.raw_clean)
SELECT COUNT(*) AS full_match_count
FROM online_shoppers_intention t
JOIN tmp_month_map tm ON LOWER(TRIM(REGEXP_REPLACE(COALESCE(t.month,''), '[^A-Za-z]', '', 'g'))) = tm.raw_clean
JOIN dim_month m ON tm.month_code = m.month_name
JOIN dim_visitor_type v ON LOWER(TRIM(REGEXP_REPLACE(COALESCE(t.visitortype,''), '[^A-Za-z0-9_]', '', 'g'))) = v.visitor_type
JOIN dim_weekend w ON (CASE WHEN LOWER(TRIM(COALESCE(CAST(t.weekend AS TEXT),''))) IN ('t','true','1','yes') THEN true WHEN LOWER(TRIM(COALESCE(CAST(t.weekend AS TEXT),''))) IN ('f','false','0','no') THEN false ELSE NULL END) = w.weekend
JOIN dim_revenue r ON (CASE WHEN LOWER(TRIM(COALESCE(CAST(t.revenue AS TEXT),''))) IN ('t','true','1','yes') THEN true WHEN LOWER(TRIM(COALESCE(CAST(t.revenue AS TEXT),''))) IN ('f','false','0','no') THEN false ELSE NULL END) = r.revenue;

-- If full_match_count < total raw, show where the breaks are:
SELECT COUNT(*) AS total_raw FROM online_shoppers_intention;

-- show top problematic raw month values (that fail mapping)
SELECT t.month, COUNT(*) AS cnt
FROM online_shoppers_intention t
LEFT JOIN tmp_month_map tm ON LOWER(TRIM(REGEXP_REPLACE(COALESCE(t.month,''), '[^A-Za-z]', '', 'g'))) = tm.raw_clean
WHERE tm.month_code IS NULL
GROUP BY t.month
ORDER BY cnt DESC
LIMIT 50;

-- show problematic visitor types (not matched)
SELECT t.visitortype, COUNT(*) AS cnt
FROM online_shoppers_intention t
LEFT JOIN tmp_visitor_map tv ON LOWER(TRIM(REGEXP_REPLACE(COALESCE(t.visitortype,''), '[^A-Za-z0-9_]', '', 'g'))) = tv.visitor_clean
LEFT JOIN dim_visitor_type v ON tv.visitor_clean = v.visitor_type
WHERE v.visitor_type_id IS NULL
GROUP BY t.visitortype
ORDER BY cnt DESC
LIMIT 50;

-- show problematic weekend values
SELECT t.weekend, COUNT(*) AS cnt
FROM online_shoppers_intention t
LEFT JOIN tmp_bool_map b ON LOWER(TRIM(COALESCE(CAST(t.weekend AS TEXT),''))) = b.raw_weekend_text
LEFT JOIN dim_weekend w ON b.weekend_bool = w.weekend
WHERE w.weekend_id IS NULL
GROUP BY t.weekend
ORDER BY cnt DESC
LIMIT 50;

-- show problematic revenue values
SELECT t.revenue, COUNT(*) AS cnt
FROM online_shoppers_intention t
LEFT JOIN tmp_bool_map b ON LOWER(TRIM(COALESCE(CAST(t.revenue AS TEXT),''))) = b.raw_revenue_text
LEFT JOIN dim_revenue r ON b.revenue_bool = r.revenue
WHERE r.revenue_id IS NULL
GROUP BY t.revenue
ORDER BY cnt DESC
LIMIT 50;

-- --------- G. If full_match_count == total_raw: insert into fact safely ----------
-- (If full_match_count < total_raw, look at above outputs and fix the few unmatched rows, then run the insert.)
-- truncate fact first (safe)
TRUNCATE fact_online_shoppers RESTART IDENTITY CASCADE;

-- safe insert using the same normalization & tmp_month_map
INSERT INTO fact_online_shoppers (
    administrative, administrative_duration,
    informational, informational_duration,
    product_related, product_related_duration,
    bounce_rates, exit_rates, page_values, special_day,
    operating_system, browser, region, traffic_type,
    month_id, visitor_type_id, weekend_id, revenue_id
)
SELECT
    t.administrative, t.administrative_duration,
    t.informational, t.informational_duration,
    t.productrelated, t.productrelated_duration,
    t.bouncerates, t.exitrates, t.pagevalues, t.specialday,
    t.operatingsystems, t.browser, t.region, t.traffictype,
    m.month_id, v.visitor_type_id, w.weekend_id, r.revenue_id
FROM online_shoppers_intention t
JOIN tmp_month_map tm ON LOWER(TRIM(REGEXP_REPLACE(COALESCE(t.month,''), '[^A-Za-z]', '', 'g'))) = tm.raw_clean
JOIN dim_month m ON tm.month_code = m.month_name
JOIN dim_visitor_type v ON LOWER(TRIM(REGEXP_REPLACE(COALESCE(t.visitortype,''), '[^A-Za-z0-9_]', '', 'g'))) = v.visitor_type
JOIN dim_weekend w ON (CASE WHEN LOWER(TRIM(COALESCE(CAST(t.weekend AS TEXT),''))) IN ('t','true','1','yes') THEN true WHEN LOWER(TRIM(COALESCE(CAST(t.weekend AS TEXT),''))) IN ('f','false','0','no') THEN false ELSE NULL END) = w.weekend
JOIN dim_revenue r ON (CASE WHEN LOWER(TRIM(COALESCE(CAST(t.revenue AS TEXT),''))) IN ('t','true','1','yes') THEN true WHEN LOWER(TRIM(COALESCE(CAST(t.revenue AS TEXT),''))) IN ('f','false','0','no') THEN false ELSE NULL END) = r.revenue;

-- final checks
SELECT COUNT(*) AS fact_rows FROM fact_online_shoppers;
SELECT * FROM fact_online_shoppers LIMIT 10;
--========================================================================
