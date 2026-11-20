# Performance

The working set is about 10,000 employees and roughly 15,000 salary rows. That is small for SQLite and small enough that a clever cache would cost more than it saves.

## What the queries do

Current salary is one grouped query: max `effective_on` per employee where the date is on or before today, joined back to the row. The supporting index is unique on `(employee_id, effective_on)`. Directory filters use indexes on status, country, department, employee number, and email. Search is a `LIKE` on name, email, and employee number. At this size a leading-wildcard search is a scan of 10,000 narrow rows, which is fine. A trigram index is the next step if search ever feels slow, not before.

The snapshot loads those current rows with country and department and aggregates in Ruby: totals, half-up average, half-up median, bands. Doing the median in SQL across SQLite and a future Postgres would be two dialects for a number we already hold in memory.

Pagination is offset/limit, capped at 100 rows. Offset into 10,000 is cheap. Keyset pagination is unnecessary until the directory grows by an order of magnitude or the sort becomes unstable.

## What we measured

Local run after `bin/rails db:seed` on Ruby 3.2.2, SQLite, development cache off. Re-run `bin/rails runner scripts/benchmark_snapshot.rb` if the machine changes.

| Step | Result |
| --- | --- |
| Seed of 10,000 employees and 15,326 salary rows | 2.4 seconds |
| People on payroll | 9,621 (active and on leave with a salary effective today) |
| One dashboard snapshot | about 420 ms |
| One directory page of 25 | about 10 ms |
| Salary sort inside the United States | about 12 ms |

The snapshot time is Active Record turning those current rows, with country and department, into objects, then summing them in Ruby. It is one HR manager, not a public page. A pluck of the four columns we actually aggregate would be the next cut if 420 ms ever showed up in the UI. It is not worth a cache.

Rails 7.2’s SQLite defaults are already the ones this app wants: WAL, `synchronous = NORMAL`, foreign keys, 128MB mmap. No extra pragma layer was added.

## What we did not do

- No materialized payroll table. Invalidation on every salary write is a bug farm at this scale.
- No page cache on the dashboard. The HR manager is one user.
- No background job to build the snapshot. The request is the job.
- Seed uses `insert_all` in slices of 500 so SQLite’s variable limit is not the bottleneck. Validations are skipped on that path; check constraints in the migration are the backstop.

If the workforce grew toward a million, or if the dashboard were hit by a company-wide audience, the next change would be a payroll snapshot table rebuilt when salary rows change, plus Postgres. The service object is the place that swap would happen. Controllers would not change.
