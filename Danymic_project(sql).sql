
-- 2) Analytics view
CREATE OR REPLACE VIEW analytics_pricing AS
SELECT
  product_id, date, category, brand, actual_price, units_sold,
  COALESCE(units_sold, 0) as units_sold_zero,
  actual_price * COALESCE(units_sold,0) as revenue,
  cost_price, (actual_price - cost_price) as margin, 
  ((actual_price - cost_price)/NULLIF(actual_price,0)) as gross_margin_pct,
  (actual_price - competitor_price) as price_gap,
  discount_percent, month, week_of_year, is_weekend, stock_bucket, is_promotional
FROM staging_pricing
WHERE date IS NOT NULL;

-- 3) Category monthly revenue
SELECT
  category,
  DATE_TRUNC('month', date) as month,
  SUM(actual_price * units_sold) as revenue,
  AVG(actual_price) as avg_price,
  SUM(units_sold) as units_sold
FROM staging_pricing
GROUP BY category, DATE_TRUNC('month', date)
ORDER BY month, category;

-- 4) Top SKUs by revenue (last 90 days)
SELECT product_id, brand, category,
 SUM(actual_price*units_sold) as revenue,
 SUM(units_sold) as total_units
FROM staging_pricing
WHERE date >= CURRENT_DATE - INTERVAL '90 days'
GROUP BY product_id, brand, category
ORDER BY revenue DESC
LIMIT 20;

-- 5) Competitor price gap summary
SELECT category, 
 COUNT(*) FILTER (WHERE competitor_price IS NULL) as missing_competitor_price,
 AVG(actual_price - competitor_price) as avg_price_gap
FROM staging_pricing
GROUP BY category;

-- 6) SKU-level profitability
SELECT product_id, category, brand,
 SUM(actual_price*units_sold) as revenue,
 SUM((actual_price - cost_price) * units_sold) as gross_profit,
 AVG((actual_price - cost_price)/NULLIF(actual_price,0)) as avg_margin_pct
FROM staging_pricing
GROUP BY product_id, category, brand
ORDER BY gross_profit DESC
LIMIT 50;

-- 7) Monthly average elasticity by category
SELECT category, DATE_TRUNC('month', date) as month,
 AVG(price_elasticity) as avg_elasticity
FROM staging_pricing
GROUP BY category, DATE_TRUNC('month', date)
ORDER BY month, category;

-- 8) Revenue by season and category
SELECT season, category, SUM(actual_price*units_sold) as revenue
FROM staging_pricing
GROUP BY season, category
ORDER BY revenue DESC;