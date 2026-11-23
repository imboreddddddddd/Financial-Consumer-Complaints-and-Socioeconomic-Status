-- Analysis views. Use these instead of querying the raw tables.
-- Column names are written in plain English, and state names are included.
-- These views can be created or updated more than once.
--
-- Complaint counts reflect the dates currently in the dataset.
-- Complaints without a valid state, including military addresses, are
-- excluded from the state-level views.

USE consumer_complaints;


-- ----------------------------------------------------------------------
-- State demographics and complaint counts and rates.
-- ----------------------------------------------------------------------
CREATE OR REPLACE VIEW v_state_complaint_rates AS
SELECT
    s.state_name,
    s.state_abbreviation,
    s.census_region,
    d.total_population,
    d.median_household_income_usd,
    d.poverty_rate_pct,
    d.bachelors_degree_or_higher_pct,
    d.unemployment_rate_pct,
    COUNT(c.complaint_id) AS complaint_count,
    ROUND(1000 * COUNT(c.complaint_id) / d.total_population, 3) AS complaints_per_1000_residents
FROM states AS s
JOIN state_demographics AS d ON d.state_code = s.state_code
LEFT JOIN complaints AS c ON c.state_abbreviation = s.state_abbreviation
GROUP BY
    s.state_name, s.state_abbreviation, s.census_region,
    d.total_population, d.median_household_income_usd, d.poverty_rate_pct,
    d.bachelors_degree_or_higher_pct, d.unemployment_rate_pct;


-- ----------------------------------------------------------------------
-- Complaint counts and percentages for each product in each state.
-- ----------------------------------------------------------------------
CREATE OR REPLACE VIEW v_state_product_mix AS
SELECT
    s.state_name,
    s.state_abbreviation,
    p.product_name,
    COUNT(*) AS complaint_count,
    ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY s.state_abbreviation), 2) AS pct_of_state_complaints,
    ROUND(1000 * COUNT(*) / d.total_population, 3) AS complaints_per_1000_residents
FROM complaints AS c
JOIN states AS s ON s.state_abbreviation = c.state_abbreviation
JOIN state_demographics AS d ON d.state_code = s.state_code
JOIN products AS p ON p.product_id = c.product_id
GROUP BY s.state_name, s.state_abbreviation, p.product_name, d.total_population;


-- ----------------------------------------------------------------------
-- Company response counts and percentages for each state.
-- ----------------------------------------------------------------------
CREATE OR REPLACE VIEW v_state_company_responses AS
SELECT
    s.state_name,
    s.state_abbreviation,
    COALESCE(c.company_response_to_consumer, 'Not recorded') AS company_response_to_consumer,
    COUNT(*) AS complaint_count,
    ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY s.state_abbreviation), 2) AS pct_of_state_complaints
FROM complaints AS c
JOIN states AS s ON s.state_abbreviation = c.state_abbreviation
GROUP BY s.state_name, s.state_abbreviation, COALESCE(c.company_response_to_consumer, 'Not recorded');


-- ----------------------------------------------------------------------
-- Complaint details, including product, company and state names.
-- State information is blank when a complaint has no recognised state.
-- ----------------------------------------------------------------------
CREATE OR REPLACE VIEW v_complaints_detail AS
SELECT
    c.complaint_id,
    c.date_received,
    p.product_name,
    p.sub_product_name,
    c.issue,
    c.sub_issue,
    co.company_name,
    s.state_name,
    c.state_abbreviation,
    s.census_region,
    c.zip_code,
    c.tags,
    c.submitted_via,
    c.company_response_to_consumer,
    c.response_was_timely
FROM complaints AS c
JOIN products  AS p  ON p.product_id = c.product_id
JOIN companies AS co ON co.company_id = c.company_id
LEFT JOIN states AS s ON s.state_abbreviation = c.state_abbreviation;
