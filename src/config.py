"""
Settings for the data-retrieval scripts.
API keys and database credentials are loaded from the local .env file.
"""
import os
from pathlib import Path
from urllib.parse import quote_plus

from dotenv import load_dotenv

PROJECT_ROOT = Path(__file__).resolve().parent.parent
SQL_DIR = PROJECT_ROOT / "sql"
DATA_DIR = PROJECT_ROOT / "data"
STAGING_DIR = DATA_DIR / "staging"

load_dotenv(PROJECT_ROOT / ".env")

# Date range for CFPB complaints
COMPLAINT_START_DATE = "2020-01-01"
COMPLAINT_END_DATE = "2024-12-31"

# Census ACS data settings
ACS_YEAR = 2024
ACS_DATA_PERIOD_LABEL = "2020-2024 5-year average"
CENSUS_API_KEY = os.getenv("CENSUS_API_KEY", "")

# CFPB API endpoint
CFPB_API_URL = (
    "https://www.consumerfinance.gov/data-research/consumer-complaints/search/api/v1/"
)

# Database connection settings
DB_HOST     = os.getenv("DB_HOST", "localhost")
DB_PORT     = int(os.getenv("DB_PORT", "3306"))
DB_USER     = os.getenv("DB_USER", "root")
DB_PASSWORD = os.getenv("DB_PASSWORD", "")
DB_NAME     = os.getenv("DB_NAME", "consumer_complaints")


def database_url(include_database: bool = True) -> str:
    """
    Build the database connection URL.
    """
    base = f"mysql+pymysql://{DB_USER}:{quote_plus(DB_PASSWORD)}@{DB_HOST}:{DB_PORT}"
    return f"{base}/{DB_NAME}" if include_database else base