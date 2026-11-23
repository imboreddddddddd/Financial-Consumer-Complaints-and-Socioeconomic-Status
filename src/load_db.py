"""
Rebuild the database from scratch:
  1. Create the database and tables, and add the state records.
  2. Download Census data, load it, and prepare state demographics.
  3. Download CFPB complaints, load them, and prepare the complaints table.
  4. Create the analysis views.

WARNING: This deletes and rebuilds all tables in the database.

Run from the repo root:
    python src/load_db.py                    full rebuild, downloads missing files
    python src/load_db.py --skip-download    rebuild using existing files in data/staging
"""
import argparse
import subprocess
import sys
from pathlib import Path

from sqlalchemy import create_engine
from pymysql.constants import CLIENT

import config

SRC_DIR = Path(__file__).resolve().parent


def run_sql_file(file_name: str, with_database: bool = True) -> None:
    """Run every statement in a file from the sql folder and print any results."""
    print(f"\n--- sql/{file_name}")
    sql = (config.SQL_DIR / file_name).read_text(encoding="utf-8")

    # MULTI_STATEMENTS lets MySQL run the whole file at once and handle comments itself.
    engine = create_engine(
        config.database_url(include_database=with_database),
        connect_args={"client_flag": CLIENT.MULTI_STATEMENTS},
    )
    connection = engine.raw_connection()
    try:
        cursor = connection.cursor()
        cursor.execute(sql)
        while True:
            if cursor.description:
                columns = [column[0] for column in cursor.description]
                print(" | ".join(columns))
                for row in cursor.fetchall():
                    print(" | ".join(str(value) for value in row))
            if not cursor.nextset():
                break
        connection.commit()
    finally:
        connection.close()
        engine.dispose()


def run_script(file_name: str) -> None:
    """Run one of the Python scripts in this folder."""
    print(f"\n--- src/{file_name}")
    subprocess.run([sys.executable, str(SRC_DIR / file_name)], check=True)


def main() -> None:
    parser = argparse.ArgumentParser(description="Rebuild the database from scratch.")
    parser.add_argument(
        "--skip-download", action="store_true",
        help="do not call the Census or CFPB APIs; use the files already in data/staging",
    )
    args = parser.parse_args()

    run_sql_file("create_database.sql", with_database=False)
    run_sql_file("create_schema.sql")
    run_sql_file("insert_states.sql")

    if not args.skip_download:
        run_script("census_client.py")
    run_script("load_acs.py")
    run_sql_file("insert_state_demographics.sql")

    if not args.skip_download:
        run_script("cfpb_client.py")
    run_script("load_cfpb.py")
    run_sql_file("insert_complaints.sql")

    run_sql_file("create_views.sql")


if __name__ == "__main__":
    main()
