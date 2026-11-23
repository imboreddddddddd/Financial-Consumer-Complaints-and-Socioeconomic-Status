# src/ -- Data retrieval

Python scripts that download data from public APIs, prepare it, and load it into MySQL.
Database tables and views are defined in ../sql/.

## Setup (uses the project's `.venv`)

```powershell
#create venv
python -m venv .venv

# from the repo root
.venv\Scripts\Activate.ps1
pip install -r requirements.txt
copy .env.example .env      # then fill in CENSUS_API_KEY and DB_* values
```

A free Census API key is available at https://api.census.gov/data/key_signup.html.
You also need a local MySQL 8.x server.

## Files

| File | Purpose |
|---|---|---|
| `config.py` | Stores the date range (2020-01-01 to 2024-12-31), ACS release, API URLs, and database settings from `.env` |
| `census_client.py` | Fetch state-level ACS 5-year estimates from the Census API, save to `data/staging/acs_raw.csv` |
| `load_acs.py` | Load `acs_raw.csv` into the `stg_acs` table |
| `cfpb_client.py` | Downloads CFPB complaints by month and saves them to `data/staging/cfpb/`. Skips months that have already been downloaded. Supports `--start`, `--end`, and `--out-dir` |
| `load_cfpb.py` | 	Loads the downloaded CSV files into `stg_complaints`. Supports `--in-dir`. |
| `load_db.py` | 	Rebuilds the database by running the SQL files and Python scripts in order. Use `--skip-download` to reuse files in `data/staging`. **Deletes all existing tables.** |

## Data flow

```
APIs -> data/staging/ (gitignored) -> MySQL stg_* tables -> SQL Cleanup  ->  Final tables & views
```

Each team member downloads and loads the data by running the scripts.
PLEASE DONT COMMIT THE DATA, ITS 1.8 GIGABYTES.