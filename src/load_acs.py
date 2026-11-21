"""
Load the Census data from acs_raw.csv into the stg_acs table.

Run from the repo root: python src/load_acs.py
"""
import pandas as pd
from sqlalchemy import create_engine, text

import config

INPUT_FILE = config.STAGING_DIR / "acs_raw.csv"


def main() -> None:
    # Read all columns as text to preserve the original values.
    table = pd.read_csv(INPUT_FILE, dtype=str)

    engine = create_engine(config.database_url())
    with engine.begin() as connection:
        connection.execute(text("TRUNCATE TABLE stg_acs"))
        table.to_sql("stg_acs", connection, if_exists="append", index=False)

    print(f"Loaded {len(table)} rows into stg_acs")


if __name__ == "__main__":
    main()
