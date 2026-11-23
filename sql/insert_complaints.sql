-- Clean the staging data and load it into the final tables:
-- products, companies and complaints.
-- Run after src/load_cfpb.py. 
--
-- What changes along the way:
--   * Timestamps like 2024-06-03T00:00:54.000Z become plain dates.
--   * timely: 'Yes' becomes 1 and 'No' becomes 0.
--   * Blank sub-products become 'Not specified'.
--   * Only 2-letter state values are kept. Blank states and a few
--     spelled-out territory names become NULL.

USE consumer_complaints;

-- Clear the final tables before loading new data.
DELETE FROM complaints;
DELETE FROM products;
DELETE FROM companies;

-- Insert each unique product and sub-product combination.
INSERT INTO products (product_name, sub_product_name)
SELECT DISTINCT
    product,
    COALESCE(NULLIF(TRIM(sub_product), ''), 'Not specified')
FROM stg_complaints;

-- Insert each unique company.
INSERT INTO companies (company_name)
SELECT DISTINCT company
FROM stg_complaints;

-- Insert complaints and link them to their product and company.
INSERT INTO complaints (
    complaint_id,
    date_received,
    date_sent_to_company,
    product_id,
    issue,
    sub_issue,
    company_id,
    state_abbreviation,
    zip_code,
    tags,
    submitted_via,
    company_public_response,
    company_response_to_consumer,
    response_was_timely
)
SELECT
    CAST(s.complaint_id AS UNSIGNED),

    -- Convert timestamps to dates.
    STR_TO_DATE(LEFT(s.date_received, 10), '%Y-%m-%d'),
    STR_TO_DATE(LEFT(s.date_sent_to_company, 10), '%Y-%m-%d'),

    p.product_id,
    s.issue,
    s.sub_issue,
    c.company_id,

    -- Keep valid 2-letter state codes; set other values to NULL.
    CASE WHEN CHAR_LENGTH(TRIM(s.state)) = 2 THEN UPPER(TRIM(s.state)) END,

    s.zip_code,
    s.tags,
    s.submitted_via,
    s.company_public_response,
    s.company_response,

    -- Convert Yes/No values to 1/0.
    CASE s.timely WHEN 'Yes' THEN 1 WHEN 'No' THEN 0 END
FROM stg_complaints AS s
JOIN products  AS p ON p.product_name = s.product
                   AND p.sub_product_name = COALESCE(NULLIF(TRIM(s.sub_product), ''), 'Not specified')
JOIN companies AS c ON c.company_name = s.company;

-- Compare row counts to check the results.
SELECT
    (SELECT COUNT(*) FROM stg_complaints) AS staging_rows,
    (SELECT COUNT(*) FROM complaints)     AS complaint_rows,
    (SELECT COUNT(*) FROM products)       AS product_rows,
    (SELECT COUNT(*) FROM companies)      AS company_rows;
