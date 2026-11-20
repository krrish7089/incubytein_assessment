# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.2].define(version: 2026_11_20_120000) do
  create_table "countries", force: :cascade do |t|
    t.string "code", null: false
    t.string "name", null: false
    t.string "currency_code", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_countries_on_code", unique: true
  end

  create_table "departments", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_departments_on_name", unique: true
  end

  create_table "employees", force: :cascade do |t|
    t.string "employee_number", null: false
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "email", null: false
    t.integer "country_id", null: false
    t.integer "department_id", null: false
    t.string "job_title", null: false
    t.string "job_level", null: false
    t.string "status", default: "active", null: false
    t.date "hire_date", null: false
    t.date "terminated_on"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["country_id"], name: "index_employees_on_country_id"
    t.index ["department_id"], name: "index_employees_on_department_id"
    t.index ["email"], name: "index_employees_on_email", unique: true
    t.index ["employee_number"], name: "index_employees_on_employee_number", unique: true
    t.index ["last_name", "first_name"], name: "index_employees_on_last_name_and_first_name"
    t.index ["status"], name: "index_employees_on_status"
    t.check_constraint "(status = 'terminated' AND terminated_on IS NOT NULL) OR (status <> 'terminated' AND terminated_on IS NULL)", name: "employees_termination_matches_status"
    t.check_constraint "job_level IN ('IC1', 'IC2', 'IC3', 'IC4', 'IC5', 'IC6', 'M1', 'M2', 'M3')", name: "employees_job_level_known"
    t.check_constraint "status IN ('active', 'on_leave', 'terminated')", name: "employees_status_known"
  end

  create_table "exchange_rates", force: :cascade do |t|
    t.string "currency_code", null: false
    t.decimal "units_per_usd", precision: 16, scale: 6, null: false
    t.date "as_of", null: false
    t.string "source", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["currency_code"], name: "index_exchange_rates_on_currency_code", unique: true
  end

  create_table "hr_accounts", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_hr_accounts_on_email", unique: true
  end

  create_table "salary_records", force: :cascade do |t|
    t.integer "employee_id", null: false
    t.integer "amount_cents", limit: 8, null: false
    t.string "currency_code", null: false
    t.date "effective_on", null: false
    t.string "reason", null: false
    t.text "note"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["effective_on"], name: "index_salary_records_on_effective_on"
    t.index ["employee_id", "effective_on"], name: "index_salary_records_on_employee_id_and_effective_on", unique: true
    t.check_constraint "amount_cents > 0", name: "salary_records_amount_positive"
    t.check_constraint "reason IN ('hire', 'merit', 'promotion', 'market_adjustment', 'correction')", name: "salary_records_reason_known"
  end

  add_foreign_key "employees", "countries"
  add_foreign_key "employees", "departments"
  add_foreign_key "salary_records", "employees"
end
