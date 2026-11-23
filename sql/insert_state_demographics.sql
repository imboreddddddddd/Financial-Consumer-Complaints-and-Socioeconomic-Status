-- Clean the raw Census data and load it into state_demographics.
-- Run after src/load_acs.py has loaded stg_acs.
--
-- Negative Census values indicate missing or unavailable estimates.
-- Those are converted to NULL.
-- The education percentage is calculated from four degree categories.

USE consumer_complaints;

DELETE FROM state_demographics;

INSERT INTO state_demographics (
    state_code,
    data_period,
    total_population,
    median_household_income_usd,
    poverty_rate_pct,
    bachelors_degree_or_higher_pct,
    unemployment_rate_pct
)
SELECT
    state,
    '2020-2024 5-year average',

    -- Population: convert to a number, or NULL if unavailable.
    CASE WHEN CAST(B01003_001E AS SIGNED) >= 0
         THEN CAST(B01003_001E AS SIGNED) END,

    -- Median household income: convert to a blah blah...
    CASE WHEN CAST(B19013_001E AS SIGNED) >= 0
         THEN CAST(B19013_001E AS SIGNED) END,

    -- Poverty rate.
    CASE WHEN CAST(S1701_C03_001E AS DECIMAL(8,2)) >= 0
         THEN CAST(S1701_C03_001E AS DECIMAL(8,2)) END,

    -- Calculate the percentage of adults 25+ with a bachelor's degree or higher.
    -- Includes bachelor's, master's, professional and doctorate degrees.
    -- Return NULL if any degree count is unavailable.
    CASE
        WHEN CAST(B15003_001E AS SIGNED) > 0
         AND CAST(B15003_022E AS SIGNED) >= 0
         AND CAST(B15003_023E AS SIGNED) >= 0
         AND CAST(B15003_024E AS SIGNED) >= 0
         AND CAST(B15003_025E AS SIGNED) >= 0
        THEN ROUND(
            100 * (
                CAST(B15003_022E AS SIGNED)
                + CAST(B15003_023E AS SIGNED)
                + CAST(B15003_024E AS SIGNED)
                + CAST(B15003_025E AS SIGNED)
            ) / CAST(B15003_001E AS SIGNED), 2
        )
    END,

    -- Unemployment rate: Its a percentage this time.
    CASE WHEN CAST(S2301_C04_001E AS DECIMAL(8,2)) >= 0
         THEN CAST(S2301_C04_001E AS DECIMAL(8,2)) END
FROM stg_acs;

-- Check the number of rows and look for missing values.
SELECT
    COUNT(*)                            AS state_rows,
    SUM(total_population IS NULL)       AS missing_population,
    SUM(median_household_income_usd IS NULL) AS missing_income,
    SUM(poverty_rate_pct IS NULL)       AS missing_poverty,
    SUM(bachelors_degree_or_higher_pct IS NULL) AS missing_education,
    SUM(unemployment_rate_pct IS NULL)  AS missing_unemployment
FROM state_demographics;
