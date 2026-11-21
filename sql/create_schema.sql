-- Create all tables.
-- Dont run multiple times unless you want to reset all data!
--
-- Table groups:
--   states, state_demographics      State and Census demographic data
--   products, companies, complaints CFPB complaint data
--   stg_acs, stg_complaints         Data imported from the APIs

USE consumer_complaints;

-- Drop tables in reverse order to avoid foreign key errors.
DROP TABLE IF EXISTS complaints;
DROP TABLE IF EXISTS companies;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS state_demographics;
DROP TABLE IF EXISTS states;
DROP TABLE IF EXISTS stg_complaints;
DROP TABLE IF EXISTS stg_acs;


-- ----------------------------------------------------------------------
-- States
-- ----------------------------------------------------------------------

CREATE TABLE states (
    state_code         CHAR(2)      NOT NULL COMMENT 'Census state code (e.g. 06 for California)',
    state_abbreviation CHAR(2)      NOT NULL COMMENT 'Two-letter state abbreviation (e.g. CA)',
    state_name         VARCHAR(50)  NOT NULL COMMENT 'Full state name',
    census_region      VARCHAR(20)  NULL     COMMENT 'Census region (Northeast, Midwest, South or West)',
    census_division    VARCHAR(30)  NULL     COMMENT 'Census division within the region (e.g. Pacific, New England)',
    PRIMARY KEY (state_code),
    UNIQUE KEY uq_states_abbreviation (state_abbreviation)
) COMMENT = 'State names, codes and Census regions for the 50 states, DC and Puerto Rico';


-- ----------------------------------------------------------------------
-- State demographics from the Census ACS
-- ----------------------------------------------------------------------

CREATE TABLE state_demographics (
    state_code                     CHAR(2)       NOT NULL COMMENT 'State code linked to the states table',
    data_period                    VARCHAR(40)   NOT NULL COMMENT 'Years covered by the Census estimates',
    total_population               INT           NULL     COMMENT 'Total number of residents',
    median_household_income_usd    INT           NULL     COMMENT 'Median household income in US dollars',
    poverty_rate_pct               DECIMAL(5,2)  NULL     COMMENT 'Percent of residents living below the federal poverty line',
    bachelors_degree_or_higher_pct DECIMAL(5,2)  NULL     COMMENT 'Percent of adults age 25+ with a bachelor''s degree or higher',
    unemployment_rate_pct          DECIMAL(5,2)  NULL     COMMENT 'Percent of the labor force (age 16+) that is unemployed',
    PRIMARY KEY (state_code),
    CONSTRAINT fk_demographics_state FOREIGN KEY (state_code) REFERENCES states (state_code)
) COMMENT = 'Census data on population, income, poverty, education and unemployment by state';


-- ----------------------------------------------------------------------
-- CFPB complaints
-- Columns follow the CFPB Consumer Complaint Database field reference.
-- ----------------------------------------------------------------------

CREATE TABLE products (
    product_id        INT           NOT NULL AUTO_INCREMENT COMMENT 'Unique product ID',
    product_name      VARCHAR(150)  NOT NULL COMMENT 'Main financial product (e.g. Credit reporting, Debt collection, Mortgage)',
    sub_product_name  VARCHAR(150)  NOT NULL DEFAULT 'Not specified' COMMENT 'More specific product category',
    PRIMARY KEY (product_id),
    UNIQUE KEY uq_products (product_name, sub_product_name)
) COMMENT = 'Financial products associated with complaints';

CREATE TABLE companies (
    company_id    INT           NOT NULL AUTO_INCREMENT COMMENT 'Unique company ID',
    company_name  VARCHAR(255)  NOT NULL COMMENT 'Company the complaint was filed against',
    PRIMARY KEY (company_id),
    UNIQUE KEY uq_companies_name (company_name)
) COMMENT = 'Companies named in CFPB complaints';

CREATE TABLE complaints (
    complaint_id               BIGINT        NOT NULL COMMENT 'Unique CFPB complaint number',
    date_received              DATE          NOT NULL COMMENT 'Date the CFPB received the complaint',
    date_sent_to_company       DATE          NULL     COMMENT 'Date the CFPB sent the complaint to the company',
    product_id                 INT           NOT NULL COMMENT 'Product linked to the complaint',
    issue                      VARCHAR(255)  NULL     COMMENT 'Main issue reported by the consumer',
    sub_issue                  VARCHAR(255)  NULL     COMMENT 'More specific issue. Not every issue has one.',
    company_id                 INT           NOT NULL COMMENT 'Company linked to the complaint',
    state_abbreviation         CHAR(2)       NULL     COMMENT 'Consumer state abbreviation, if provided',
    zip_code                   VARCHAR(10)   NULL     COMMENT 'Consumer ZIP code, which may have masked digits',
    tags                       VARCHAR(100)  NULL     COMMENT 'CFPB label (e.g. Older American or Servicemember)',
    submitted_via              VARCHAR(50)   NULL     COMMENT 'How the complaint was submitted to the CFPB',
    company_public_response    VARCHAR(255)  NULL     COMMENT 'Optional public statement from the company',
    company_response_to_consumer VARCHAR(100) NULL    COMMENT 'Company response to the complaint',
    response_was_timely        TINYINT(1)    NULL     COMMENT '1 if the response was on time, 0 if it was late',
    PRIMARY KEY (complaint_id),
    KEY ix_complaints_state (state_abbreviation),
    KEY ix_complaints_product (product_id),
    KEY ix_complaints_date (date_received),
    CONSTRAINT fk_complaints_product FOREIGN KEY (product_id) REFERENCES products (product_id),
    CONSTRAINT fk_complaints_company FOREIGN KEY (company_id) REFERENCES companies (company_id)
) COMMENT = 'Consumer complaints filed with the CFPB';


-- ----------------------------------------------------------------------
-- Staging tables
-- Store received API data as text before cleaning and moving.
-- Yes, the column names are literally how they are in the API.
-- ----------------------------------------------------------------------

CREATE TABLE stg_acs (
    state          VARCHAR(2)   COMMENT 'Census state code',
    NAME           VARCHAR(60)  COMMENT 'State name',
    B01003_001E    VARCHAR(20)  COMMENT 'Total population',
    B19013_001E    VARCHAR(20)  COMMENT 'Median household income (USD)',
    S1701_C03_001E VARCHAR(20)  COMMENT 'Percent below poverty line',
    B15003_001E    VARCHAR(20)  COMMENT 'Adults 25+ (total)',
    B15003_022E    VARCHAR(20)  COMMENT 'Adults 25+ with bachelor''s degree',
    B15003_023E    VARCHAR(20)  COMMENT 'Adults 25+ with master''s degree',
    B15003_024E    VARCHAR(20)  COMMENT 'Adults 25+ with professional school degree',
    B15003_025E    VARCHAR(20)  COMMENT 'Adults 25+ with doctorate degree',
    S2301_C04_001E VARCHAR(20)  COMMENT 'Unemployment rate (percent)'
) COMMENT = 'Census API data before cleaning.';

CREATE TABLE stg_complaints (
    complaint_id               VARCHAR(20),
    date_received              VARCHAR(30),
    date_sent_to_company       VARCHAR(30),
    product                    VARCHAR(150),
    sub_product                VARCHAR(150),
    issue                      VARCHAR(255),
    sub_issue                  VARCHAR(255),
    company                    VARCHAR(255),
    state                      VARCHAR(10),
    zip_code                   VARCHAR(10),
    tags                       VARCHAR(100),
    submitted_via              VARCHAR(50),
    company_public_response    VARCHAR(255),
    company_response           VARCHAR(100),
    timely                     VARCHAR(10)
) COMMENT = 'CFPB complaint data before cleaning.';
