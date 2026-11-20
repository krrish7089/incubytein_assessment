# Acme Compensation

Web application for Acme’s HR manager to keep base-salary data for 10,000 employees and answer how the organization pays people. It is not a payroll system. Scope, exclusions, and the reasons for them are in [docs/requirements.md](docs/requirements.md).

## Run it

Ruby 3.2.2 (see `.ruby-version`) and Bundler.

```bash
bundle install
bin/rails db:prepare db:seed
bin/rails server
```

Open http://localhost:3000.

Sign in as `hr@acme.test` / `Acme-HR-2026`. Override the password with `HR_PASSWORD` before seeding. The seed is idempotent: reference data and the HR account are ensured every time, and the 10,000 people are inserted only when the employee table is empty. `bin/rails db:seed:replant` starts that workforce over.

The React app is already built into `public/`, so the server above is enough. To change the UI:

```bash
cd frontend
npm install
npm run dev
```

Vite runs at http://localhost:5173 and proxies `/api` to Rails on port 3000. `npm run build` writes the production assets back into `public/`.

## What the HR manager can do

- Read payroll by currency, country, and department, plus a band chart and recent changes. Totals are never summed across currencies. The USD figure is indicative and labeled as not payroll.
- Search and filter people. Sorting by salary asks for a country first.
- Hire someone, record a merit, promotion, market adjustment, or correction, and see history. A future effective date is visible and is not “current” until that day.
- Mark someone on leave (still paid) or terminated (kept, not paid). Country does not change after hire.
- Export the current payroll as CSV. Amounts in the file are plain numbers.

## Tests

```bash
bin/rails test
bin/rubocop
bin/brakeman --no-pager
bin/rails runner scripts/benchmark_snapshot.rb
```

## Docker

```bash
docker compose up --build
```

The container migrates, seeds, and serves HTTP on port 3000. `RAILS_DISABLE_SSL` is set for that local run. A real deployment should leave SSL on and replace `SECRET_KEY_BASE`. The SQLite file lives in the `acme-sqlite` volume.

## Notes

- [docs/architecture.md](docs/architecture.md) — shape of the system
- [docs/decisions.md](docs/decisions.md) — trade-offs
- [docs/performance.md](docs/performance.md) — what 10,000 rows actually costs
- [docs/ai-usage.md](docs/ai-usage.md) — how the agent was used
