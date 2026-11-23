# sql/ -- Database Definition

The SQL files below are listed in the order they should be run.
../src/load_db.py runs them automatically and loads the raw API data into the stg_* (staging) tables where needed.

| File | Purpose |
|---|---|
| `create_database.sql` | Create the database |
| `create_schema.sql` | Creates the tables, keys, indexes, and column comments. Drops existing tables first. |
| `insert_states.sql` | Adds the 50 states, DC, and Puerto Rico |
| `insert_state_demographics.sql` | Cleans the Census data in `stg_acs` and loads it into `state_demographics` |
| `insert_complaints.sql` | Cleans the CFPB data in `stg_complaints` and loads it into `products`, `companies`, and `complaints`|
| `create_views.sql` | Creates views for analysis |

## Views for analysis

Use these views for analysis instead of querying the tables directly. They include state names and use readable column names.

Complaint counts cover all complaint dates currently loaded.
Complaints with a blank or unrecognised state code (such as military addresses) are excluded from the state-level views.

| View | One row per | Use it for |
|---|---|---|
| `v_state_complaint_rates` | state | Comparing complaint rates per 1,000 residents with income, poverty, education, and unemployment |
| `v_state_product_mix` | state and product | Comparing product complaint counts, percentages, and rates across states |
| `v_state_company_responses` | state and company response | Comparing company responses across states |
| `v_complaints_detail` | complaint | Looking up complaints with product, company, and state names |

Note:
The CFPB changed some product names during 2020–2024.
For example, the name of the credit reporting category changed during this period.
This means the same type of complaint may have different product_name values in different years.
Check the distinct product names before comparing years.

## Data dictionary

These descriptions are also saved as column comments in MySQL and can be viewed in MySQL Workbench.

### states (52 rows: 50 states, DC, Puerto Rico)
| Column | Meaning |
|---|---|
| `state_code` | Census state code (e.g. 06 for California) |
| `state_abbreviation` | Two-letter state abbreviation (e.g. CA) |
| `state_name` | Full state name |
| `census_region` | Census region (Northeast, Midwest, South or West) |
| `census_division` | Census division within the region (e.g. Pacific, New England) |

### state_demographics (one row per state, Census ACS 2020-2024 5-year)
| Column | Meaning |
|---|---|
| `state_code` | State code linked to the states table |
| `data_period` | Years covered by the Census estimates |
| `total_population` | Total number of residents |
| `median_household_income_usd` | Median household income in US dollars |
| `poverty_rate_pct` | Percent of residents living below the federal poverty line |
| `bachelors_degree_or_higher_pct` | Percent of adults age 25+ with a bachelor''s degree or higher |
| `unemployment_rate_pct` | Percent of the labor force (age 16+) that is unemployed |

### products, companies, complaints
These tables are defined in create_schema.sql. Their columns are documented with comments in MySQL.
The column names follow the CFPB API field reference. The exact API field mappings are listed below.

## API code -> friendly name

### Census ACS (`state_demographics`)
| Census variable | Meaning | Column |
|---|---|---|
| `B01003_001E` | Total population | `total_population` |
| `B19013_001E` | Median household income (USD) | `median_household_income_usd` |
| `S1701_C03_001E` | Percent below poverty line | `poverty_rate_pct` |
| `B15003_022E` + `023E` + `024E` + `025E`, divided by `B15003_001E` | Adults 25+ with bachelor's, master's, professional or doctorate degree, as a share of all adults 25+ | `bachelors_degree_or_higher_pct` |
| `S2301_C04_001E` | Unemployment rate (percent) | `unemployment_rate_pct` |

The Census reports an unavailable estimate as a large negative number; the transform stores these as NULL.

### CFPB API (`complaints`)
The `state` field may be blank or contain a full territory name.
Only 2-letter state codes are kept.

| CFPB API field | Column |
|---|---|
| `complaint_id` | `complaint_id` |
| `date_received` (timestamp) | `date_received` (date only) |
| `date_sent_to_company` (timestamp) | `date_sent_to_company` (date only) |
| `product`, `sub_product` | `products.product_name`, `products.sub_product_name` ("Not specified" if blank) |
| `issue`, `sub_issue` | `issue`, `sub_issue` |
| `company` | `companies.company_name` |
| `state` | `state_abbreviation` |
| `zip_code` | `zip_code` |
| `tags` | `tags` |
| `submitted_via` | `submitted_via` |
| `company_public_response` | `company_public_response` |
| `company_response` | `company_response_to_consumer` |
| `timely` ("Yes"/"No") | `response_was_timely` (1/0) |
