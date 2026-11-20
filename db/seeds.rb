# Idempotent. Reference data and the HR account are ensured every time.
# The 10,000 employees are inserted only when the table is empty.
# Reset with `bin/rails db:seed:replant` if you need a fresh workforce.
Workforce::Seeder.new.call
