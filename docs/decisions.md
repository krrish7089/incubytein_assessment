# Decisions and trade-offs

## Rails API plus React, one deployable app

The brief asks for Rails and React. Splitting them into two deployed services would add CORS, a second auth story, and an operational burden this product does not earn. Vite builds into `public/`. Development uses a proxy so cookies and CSRF behave the way they will in production.

Hotwire shipped with the Rails generator. It is a good fit for this UI, and it was still the wrong choice: the assessment requires React, and maintaining both would be noise.

## SQLite

Ten thousand employees and their salary history fit in a single file, the test suite stays free of a database service, and the generated app was already on SQLite. Rails 7.2 turns on WAL, foreign keys, and a modest cache. That is enough. The schema uses ordinary foreign keys and indexes, so a move to Postgres later is a change of adapter, not of model.

The production database path is `storage/production.sqlite3`. Anything that runs this in a container must keep that directory on a volume. `db:seed` is idempotent: reference data and the HR account are ensured every time, and the 10,000 people are inserted only when the table is empty.

## Minor units, one currency per country

Floats will eventually mis-state a salary. The column is a 64-bit integer because an Indian salary in paise does not fit in 32 bits. JPY is a zero-decimal currency, and the parser tests that specifically.

Forcing the country’s currency is a product rule, not an accident. Mixed currency on one person makes “current salary” and the country rollup ambiguous. Expats and transfers are out of scope until HR writes that rule down.

Salary sort in the directory is refused until a country is selected. Sorting 80,000 dollars next to 8,000,000 rupees looks precise and is meaningless. The indicative USD total exists for the dashboard only, and the copy says it is not payroll.

## Effective dating instead of an overwrite

The spreadsheet overwrites a cell. That destroys the question “what did we pay, and why did it change?”. A new row per change is the smallest model that answers it. Uniqueness of `(employee, effective_on)` keeps a day unambiguous. Corrections are new rows with reason `correction`, including decreases.

Current pay is computed, not stored. A cached column would be faster to type and easier to get wrong the moment a future-dated raise lands. The snapshot loads the current rows once and aggregates in Ruby. See `docs/performance.md` for why that is acceptable here.

## Who counts as paid

Headcount and payroll are different numbers, and the screen shows both.

- Active and on leave, with a salary effective today, are on payroll.
- Terminated people keep history and drop out of totals.
- A hire dated in the future counts as a person and not as payroll.

Integer average and median use half-up rounding into minor units. The tests lock the rounding so the UI cannot drift from a silent float.

## Auth is one account, not an identity product

`HrAccount` uses `has_secure_password`. The session is a cookie, reset on sign-in, and JSON posts require the Rails CSRF token. That is the right weight for a single HR manager. Role matrices and SSO are out of scope for the same reason approval chains are.

The demo password is `Acme-HR-2026` unless `HR_PASSWORD` is set. It is a seeded local credential, not a secret management design.

## Seeded data instead of Faker

The seed is deterministic (`Random.new(42)`), uses `insert_all` in batches, and builds salaries from country bands. A faker gem would add a dependency and make the workforce look random in a way that hides bad currency handling. Tests exercise a small generated workforce plus hand-built cases. They do not insert 10,000 rows on every run. The default count is asserted so the plan cannot silently shrink.

## Tests

Minitest, because the app already used it. Coverage sits on the rules that would corrupt pay: parsing, currency match, effective dates, payroll membership, directory salary sort, auth, and the CSV. The React layer is a client of that API. A browser pass checks the flows; a component test suite would mostly restate the same contract.

## Deployment shape

`docker compose up` builds the Rails image, migrates, seeds, and serves HTTP with SSL disabled for local use. Real production still forces SSL unless `RAILS_DISABLE_SSL` is set. There is no hosted URL in this submission: the runnable artifact is the repository plus that compose file. A video is not included; the README is the runbook, and the UI is what a recording would show.
