"""
Load CFPB CSV files into the stg_complaints table.

Run from the repo root:
    python src/load_cfpb.py
    python src/load_cfpb.py --in-dir data/staging/cfpb_test
"""
import argparse
from pathlib import Path

import pandas as pd
from sqlalchemy import create_engine, text

import config

DEFAULT_IN_DIR = config.STAGING_DIR / "cfpb"
ROWS_PER_INSERT = 5000


def main() -> None:
    parser = argparse.ArgumentParser(description="Load CFPB CSV files into stg_complaints.")
    parser.add_argument("--in-dir", default=str(DEFAULT_IN_DIR), help="folder with the CSV files")
    args = parser.parse_args()

    files = sorted(Path(args.in_dir).glob("cfpb_*.csv"))
    if not files:
        raise SystemExit(f"No cfpb_*.csv files found in {args.in_dir}")

    engine = create_engine(config.database_url())
    
    # Clear the staging table before loading new data.
    with engine.begin() as connection:
        connection.execute(text("TRUNCATE TABLE stg_complaints"))

    total = 0
    for file in files:
        # Read all columns as strings to preserve the original values.
        table = pd.read_csv(file, dtype=str)
        
        with engine.begin() as connection:
            table.to_sql(
                "stg_complaints", connection,
                if_exists="append", index=False,
                chunksize=ROWS_PER_INSERT, method="multi",
            )
        total += len(table)
        print(f"{file.name}: loaded {len(table):,} rows")

    print(f"Loaded {total:,} rows into stg_complaints")


if __name__ == "__main__":
    main()
