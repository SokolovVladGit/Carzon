# Open vehicle data import (Manual Smart Fill)

Local / service_role tooling only. **Do not commit raw EEA/RDW dumps.**
**Do not put `SUPABASE_SERVICE_ROLE_KEY` in git or Flutter.**

Hosted catalog ingest is a separate authorized task. This README documents
the commands; it does not run them against production.

## Sources

| Source | Role | Official format | License |
|---|---|---|---|
| EEA CO2 cars | fuel / displacement / power / TVV | CSV / TSV / ZIP (`Mk`, `Cn`, `Year`/`r`, `Tan`, `T`, `Va`, `Ve`, `Ft`, `Fm`, `Ec`, `Ep`, `Status`) | CC-BY 4.0 (DG-CLIMA) |
| RDW Open Data | TVV body aggregates | CSV (`type`, `variant`, `uitvoering`, `typegoedkeuringsnummer`, `inrichting` / carrosserie) | CC0 |
| VehiclesDB open catalog | identity / aliases / nameplate body / TAN xref | free `models.json` only | CC-BY 4.0 |

Portal / export notes:

- EEA: https://www.eea.europa.eu/en/datahub/datahubitem-view/fa8b1229-3db6-495d-b18e-9c9b3267c02b
- RDW vehicles: `https://opendata.rdw.nl/resource/m9d7-ebf2.csv`
- RDW bodies: `https://opendata.rdw.nl/resource/vezc-m2t6.csv`
- VehiclesDB: place the **free** `models.json` (+ upstream `ATTRIBUTION.md`) on disk. Paid specs are ignored.

Attribution: [`docs/legal/open_vehicle_data_attribution.md`](../../docs/legal/open_vehicle_data_attribution.md).

## Pipeline

```
OFFICIAL SOURCE
  → streaming fetch/read
  → field projection
  → normalize + aggregate (bounded by configurations, not raw rows)
  → chunked service_role RPCs
  → complete import batch
```

Order:

1. VehiclesDB identity (aliases used by EEA upsert)
2. EEA configurations
3. RDW body merge (updates existing TVV rows)

Failed phase marks its batch `failed` and stops. Same `source` + dataset +
version + mapping is rerunnable (upsert / merge are idempotent). `--start-chunk`
resumes a later chunk of the current payload.

EEA `Status=F` wins. `P` is dropped for years `<= 2021` and for any year already
seen as `F`. Name a yearly file `*_f.csv` / `*_p.csv` so provenance is explicit.

Make include lists are CLI/config, not a permanent catalog. Preset `first`:
Skoda, Volkswagen, BMW, Mercedes-Benz, Hyundai, Kia, Toyota, Dacia, Tesla, BYD.

## Environment

```bash
export SUPABASE_URL=http://127.0.0.1:54321          # or hosted URL when authorized
export SUPABASE_SERVICE_ROLE_KEY=...               # never commit, never print
```

Flutter must never read the service role key.

## Commands

Scratch / cache stays gitignored (`tools/open_vehicle_data/.cache/`).

### EEA acquisition

```bash
# Official CSV/ZIP as downloaded. No JSONL conversion step.
python3 -m tools.open_vehicle_data.cli acquire \
  --input /tmp/CO2_passenger_cars.zip \
  --output tools/open_vehicle_data/.cache/eea.zip

# Optional hosted download (allowed EEA/RDW hosts only)
python3 -m tools.open_vehicle_data.cli acquire \
  --url 'https://sdi.eea.europa.eu/...' \
  --output tools/open_vehicle_data/.cache/eea.zip

python3 -m tools.open_vehicle_data.cli eea-aggregate \
  --input tools/open_vehicle_data/.cache/eea.zip \
  --output /tmp/carzon-open-data/eea.upsert.jsonl \
  --makes-preset first
```

Multiple year/status files:

```bash
python3 -m tools.open_vehicle_data.cli eea-aggregate \
  --inputs /tmp/co2_2020_f.csv /tmp/co2_2024_p.csv \
  --output /tmp/carzon-open-data/eea.upsert.jsonl \
  --makes Skoda,Volkswagen,BMW
```

### RDW acquisition

```bash
python3 -m tools.open_vehicle_data.cli acquire \
  --url 'https://opendata.rdw.nl/resource/m9d7-ebf2.csv?$select=kenteken,type,variant,uitvoering,typegoedkeuringsnummer,inrichting' \
  --output tools/open_vehicle_data/.cache/rdw_vehicles.csv

# Combined TVV+body file (preferred). Plate is dropped in the adapter.
python3 -m tools.open_vehicle_data.cli rdw-aggregate \
  --input tools/open_vehicle_data/.cache/rdw_vehicles.csv \
  --output /tmp/carzon-open-data/rdw.merge.jsonl

# Two-file official exports: plate is a transient join key only.
python3 -m tools.open_vehicle_data.cli rdw-aggregate \
  --input tools/open_vehicle_data/.cache/rdw_vehicles.csv \
  --bodies tools/open_vehicle_data/.cache/rdw_bodies.csv \
  --output /tmp/carzon-open-data/rdw.merge.jsonl
```

`kenteken` / VIN / owner never appear in aggregate output or RPC payloads.

### VehiclesDB acquisition (free layer)

```bash
python3 -m tools.open_vehicle_data.cli vehiclesdb-identity \
  --input /tmp/carzon-open-data/models.json \
  --output /tmp/carzon-open-data/vehiclesdb.json \
  --version 2026.09.1
```

### Dry-run (no hosted mutation)

```bash
python3 -m tools.open_vehicle_data.cli ingest \
  --dry-run \
  --eea tools/open_vehicle_data/fixtures/eea_official_sample.csv \
  --rdw tools/open_vehicle_data/fixtures/rdw_official_sample.csv \
  --vehiclesdb tools/open_vehicle_data/fixtures/vehiclesdb_sample.json \
  --source-version local-dry \
  --makes-preset first \
  --chunk-size 250
```

Reports source rows read/rejected, normalized configurations, aliases/nameplates,
body aggregates, and chunks that would be sent.

### Local ingest

```bash
export SUPABASE_URL=http://127.0.0.1:54321
export SUPABASE_SERVICE_ROLE_KEY=...   # local service_role

python3 -m tools.open_vehicle_data.cli ingest \
  --eea tools/open_vehicle_data/fixtures/eea_official_sample.csv \
  --rdw tools/open_vehicle_data/fixtures/rdw_official_sample.csv \
  --vehiclesdb tools/open_vehicle_data/fixtures/vehiclesdb_sample.json \
  --source-version local-smoke \
  --makes-preset first \
  --chunk-size 50
```

### Hosted ingest (DO NOT RUN until separately authorized)

```bash
export SUPABASE_URL=https://<project>.supabase.co
export SUPABASE_SERVICE_ROLE_KEY=...

python3 -m tools.open_vehicle_data.cli ingest \
  --eea /path/to/official/eea.zip \
  --rdw /path/to/official/rdw_vehicles.csv \
  --rdw-bodies /path/to/official/rdw_bodies.csv \
  --vehiclesdb /path/to/vehiclesdb/models.json \
  --source-version 2026.09.12 \
  --vehiclesdb-version 2026.09.1 \
  --makes-preset first \
  --chunk-size 250
```

## Tests

```bash
python3 -m unittest tools.open_vehicle_data.tests.test_open_vehicle_data \
  tools.open_vehicle_data.tests.test_production_ingest
```

No live internet. Fixtures only.
