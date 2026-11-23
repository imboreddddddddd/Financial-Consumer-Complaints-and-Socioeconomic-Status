"""
Download state-level ACS 5-year estimates from the Census API
and save the data to data/staging/acs_raw.csv.

Run from the repo root: python src/census_client.py
"""
import sys

import pandas as pd
import requests

import config

# Variables from the Census detailed tables (B tables)
DETAILED_VARIABLES = [
    "B01003_001E",  # total population
    "B19013_001E",  # median household income
    "B15003_001E",  # total adults age 25+
    "B15003_022E",  # bachelor's degree
    "B15003_023E",  # master's degree
    "B15003_024E",  # professional school degree
    "B15003_025E",  # doctorate degree
]

# Variables from the Census subject tables (S tables)
SUBJECT_VARIABLES = [
    "S1701_C03_001E",  # poverty rate
    "S2301_C04_001E",  # unemployment rate
]

BASE_URL = f"https://api.census.gov/data/{config.ACS_YEAR}/acs/acs5"
OUTPUT_FILE = config.STAGING_DIR / "acs_raw.csv"


def request_table(url: str, variables: list[str]) -> pd.DataFrame:
    """
    Request Census data and return it as a dataframe.
    """
    params = {
        "get": ",".join(["NAME"] + variables),
        "for": "state:*",
        "key": config.CENSUS_API_KEY,
    }
    try:
        response = requests.get(url, params=params, timeout=30)
        response.raise_for_status()
    except requests.RequestException as error:
        
        # Preferably don't print errors since the URL contains the API key.
        raise SystemExit(f"Census API request failed ({type(error).__name__}) for {url}")

    # The first row contains the column names; the remaining rows contain the data.
    rows = response.json()
    return pd.DataFrame(rows[1:], columns=rows[0])


def fetch_acs_states() -> pd.DataFrame:
    """
    Get all required Census variables for each state.
    """
    if not config.CENSUS_API_KEY:
        raise SystemExit("CENSUS_API_KEY is missing. Add it to your .env file.")

    detailed = request_table(BASE_URL, DETAILED_VARIABLES)
    subject = request_table(f"{BASE_URL}/subject", SUBJECT_VARIABLES)

    # Combine both tables using the state name and state code.
    combined = detailed.merge(subject, on=["NAME", "state"], how="inner", validate="one_to_one")

    if len(combined) != len(detailed) or len(combined) != len(subject):
        raise SystemExit("The two Census tables did not line up by state.")

    columns = ["state", "NAME"] + DETAILED_VARIABLES + SUBJECT_VARIABLES
    return combined[columns]


def main() -> None:
    table = fetch_acs_states()
    config.STAGING_DIR.mkdir(parents=True, exist_ok=True)
    table.to_csv(OUTPUT_FILE, index=False)
    print(f"Saved {len(table)} states to {OUTPUT_FILE}")


if __name__ == "__main__":
    main()
