# Open vehicle data attribution

Required notices for Manual Smart Fill M1. Production UI Credits screen is **M1B**
(not implemented here — no new navigation).

Keep this file in sync with imported dataset versions.

## H2 controlled ingest (hosted, 2026-09-12)

Hosted project `zypqfwktvzfnfvihxhbd`. Import version `2026.09.12-h2-first`.
Mapping version `m1.0`. Approved make preset `first` only.

User-visible Credits UI is still **not** implemented. Public release remains
blocked until those notices appear in the app.

## EEA / DG-CLIMA

Contains data from the European Environment Agency monitoring of CO2 emissions
from passenger cars (Regulation (EU) 2019/631), licensed under
[CC BY 4.0](https://creativecommons.org/licenses/by/4.0/).
Copyright: Directorate-General for Climate Action (DG-CLIMA).

H2 source (official Discodata SQL REST `https://discodata.eea.europa.eu/sql`):

- `[CO2Emission].[latest].[co2cars]` Status=F, registration years 2010–2021
- `co2cars_2022Fv26` F 2022
- `co2cars_2023Fv28` F 2023
- `co2cars_2024Fv30` F 2024
- `co2cars_2025Pv31` P 2025 only (no finalized table)
- Acquired 2026-09-12. Grouped server-side; raw dump not committed.

Changes: CARZON normalizes and aggregates registration rows to configuration
facts (make/model keys, fuel taxonomy, TVV identity). Errors in normalization
are ours, not the EEA's.

## RDW Open Data

Contains public data from the Dutch vehicle register (RDW / data.overheid.nl),
licensed under CC0 1.0 / Public Domain.

H2 source: official Socrata `https://opendata.rdw.nl/resource/m9d7-ebf2.json`
(`Open Data RDW: Gekentekende_voertuigen`). Grouped SoQL only
(`type/variant/uitvoering/typegoedkeuringsnummer/inrichting/merk`).
Acquired 2026-09-12, 194025 grouped rows. No plates/VIN/owner persisted.

CARZON stores **configuration aggregates only**. License plates, VINs, and
owner/registration-person fields are discarded during ingest and are never
persisted.

## VehiclesDB

Vehicle data by [VehiclesDB](https://vehiclesdb.com) (CC BY 4.0).

H2 used VehiclesDB free layer `2026.09.1` (`manifest.json`, built
2026-09-12T13:58:20Z) from `vehiclesdb/vehiclesdb@main`
(`catalog/car/models.json`, `makes.json`). Paid specs not imported.

The VehiclesDB open dataset is reconciled from official registers. Upstream
notices from VehiclesDB `ATTRIBUTION.md` apply to every consumer, including
commercial use. Reproduce those notices when a VehiclesDB release is imported.
They typically include (non-exhaustive; copy verbatim from the imported
release):

- DNRPA / Argentina — CC BY 4.0
- Natural Resources Canada fuel ratings — Open Government Licence – Canada
- KBA FZ10 — Datenlizenz Deutschland – Namensnennung – 2.0
- DGT / Spain — public-sector reuse terms
- Traficom Finland — CC BY 4.0
- CSO Ireland TEM20 — CC BY 4.0
- SNCA Luxembourg — CC0
- RDW Netherlands — CC0
- DfT / DVLA VEH0120 — Open Government Licence v3.0
- US EPA/DOE fueleconomy.gov — US Government work

VehiclesDB identity fields only (makes, models, aliases, nameplate body types,
TAN crosswalks). Paid configuration specs are out of scope.

## Not used in M1

- UK VCA car fuel data (reuse/download unclear)
- NHTSA / EPA as EU configuration truth
