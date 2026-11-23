"""
Download CFPB complaints from the API and save them as monthly CSV files.

The API limits each request to 10,000 complaints, so this script:
  1. Splits the date range by month.
  2. Downloads each month in batches of up to 10,000 complaints.
  3. Saves each month to a separate CSV file.

Months with existing CSV files are skipped.

Run from the repo root:
    python src/cfpb_client.py
    python src/cfpb_client.py --start 2024-06-03 --end 2024-06-09 --out-dir data/staging/cfpb_test
"""
import argparse
import calendar
import time
from datetime import date, datetime
from pathlib import Path

import pandas as pd
import requests

import config

# Complaint fields to keep in the CSV files.
COLUMNS = [
    "complaint_id",
    "date_received",
    "date_sent_to_company",
    "product",
    "sub_product",
    "issue",
    "sub_issue",
    "company",
    "state",
    "zip_code",
    "tags",
    "submitted_via",
    "company_public_response",
    "company_response",
    "timely",
]

PAGE_SIZE = 10000   # Maximum number of complaints per request
MAX_ATTEMPTS = 6    # Maximum number of retries per request
PAUSE_SECONDS = 0.5 # Please dont spam the api
DEFAULT_OUT_DIR = config.STAGING_DIR / "cfpb"


def request_page(date_min: str, date_max: str, search_after: str | None) -> dict:
    """
    Get one page of complaints, retrying if the request fails.
    """
    params = {
        "size": PAGE_SIZE,
        "sort": "created_date_asc",      # Sort oldest first, then by complaint ID
        "no_aggs": "true",               # Skip summary counts
        "date_received_min": date_min,
        "date_received_max": date_max,   # both dates are inclusive
    }
    if search_after:
        params["search_after"] = search_after

    for attempt in range(1, MAX_ATTEMPTS + 1):
        try:
            response = requests.get(config.CFPB_API_URL, params=params, timeout=120)
            response.raise_for_status()
            data = response.json()
            if "hits" in data:
                return data
            # Treat API error responses as failed requests.
        except (requests.RequestException, ValueError):
            pass

        wait = 2 ** attempt
        print(f"  request failed (attempt {attempt}/{MAX_ATTEMPTS}); waiting {wait}s")
        time.sleep(wait)

    raise SystemExit(f"CFPB API kept failing for {date_min} to {date_max}. Run again to resume.")


def fetch_range(date_min: str, date_max: str) -> pd.DataFrame:
    """
    Get every complaint received between two dates (inclusive).
    """
    records = []
    search_after = None
    expected_total = None

    while True:
        data = request_page(date_min, date_max, search_after)
        hits = data["hits"]["hits"]

        if expected_total is None:
            total = data["hits"]["total"]
            if total["relation"] != "eq":
                raise SystemExit(f"CFPB gave only a lower bound for {date_min}..{date_max}.")
            expected_total = total["value"]

        if not hits:
            break

        records.extend(hit["_source"] for hit in hits)

        # Use the last complaint's sort values to get the next page.
        sort_values = hits[-1]["sort"]
        search_after = "_".join(str(value) for value in sort_values)

        if len(hits) < PAGE_SIZE:
            break
        time.sleep(PAUSE_SECONDS)

    table = pd.DataFrame(records, columns=COLUMNS)

    # Check for missing or duplicate complaints.
    if table["complaint_id"].duplicated().any():
        raise SystemExit(f"Duplicate complaint IDs found in {date_min}..{date_max}.")
    if len(table) != expected_total:
        raise SystemExit(
            f"{date_min}..{date_max}: API reported {expected_total} complaints but we got {len(table)}."
        )
    return table


def month_ranges(start: date, end: date):
    """
   Return date ranges split by calendar month.
    """
    current = start
    while current <= end:
        last_day_of_month = date(current.year, current.month, calendar.monthrange(current.year, current.month)[1])
        slice_end = min(last_day_of_month, end)
        yield current, slice_end
        current = date.fromordinal(slice_end.toordinal() + 1)


def main() -> None:
    parser = argparse.ArgumentParser(description="Download CFPB complaints to CSV files.")
    parser.add_argument("--start", default=config.COMPLAINT_START_DATE, help="first date, YYYY-MM-DD")
    parser.add_argument("--end", default=config.COMPLAINT_END_DATE, help="last date, YYYY-MM-DD")
    parser.add_argument("--out-dir", default=str(DEFAULT_OUT_DIR), help="folder for the CSV files")
    args = parser.parse_args()

    start = datetime.strptime(args.start, "%Y-%m-%d").date()
    end = datetime.strptime(args.end, "%Y-%m-%d").date()
    out_dir = Path(args.out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)

    grand_total = 0
    for slice_start, slice_end in month_ranges(start, end):
        out_file = out_dir / f"cfpb_{slice_start}_{slice_end}.csv"
        if out_file.exists():
            print(f"{slice_start} to {slice_end}: already downloaded, skipping")
            continue

        began = time.time()
        table = fetch_range(str(slice_start), str(slice_end))

        # Save to a temporary file before renaming it to the final CSV.
        temp_file = out_file.with_suffix(".csv.part")
        table.to_csv(temp_file, index=False)
        temp_file.replace(out_file)

        grand_total += len(table)
        print(f"{slice_start} to {slice_end}: {len(table):,} complaints in {time.time() - began:.0f}s")

    print(f"Done. Downloaded {grand_total:,} complaints this run.")


if __name__ == "__main__":
    main()
