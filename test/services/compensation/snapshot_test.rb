require "test_helper"

class Compensation::SnapshotTest < ActiveSupport::TestCase
  setup do
    @as_of = Date.new(2026, 6, 1)
    @us = create_country
    @india = create_country(code: "IN", name: "India", currency_code: "INR")
    @engineering = create_department
    @ada = create_employee(country: @us, department: @engineering, last_name: "Lovelace")
    @grace = create_employee(country: @us, department: @engineering, last_name: "Hopper", status: "on_leave")
    @gone = create_employee(
      country: @us,
      department: @engineering,
      last_name: "Gone",
      status: "terminated",
      terminated_on: Date.new(2024, 1, 1)
    )
    @future = create_employee(country: @us, department: @engineering, last_name: "Future", hire_date: Date.new(2026, 12, 1))
    @riya = create_employee(country: @india, department: @engineering, last_name: "Shah")

    create_salary(@ada, amount_cents: 10_000_000, effective_on: Date.new(2022, 1, 15))
    create_salary(@ada, amount_cents: 12_000_000, effective_on: Date.new(2025, 1, 1), reason: "merit")
    create_salary(@ada, amount_cents: 15_000_000, effective_on: Date.new(2026, 12, 1), reason: "merit")
    create_salary(@grace, amount_cents: 8_000_000)
    create_salary(@gone, amount_cents: 20_000_000)
    create_salary(@future, amount_cents: 9_000_000, effective_on: Date.new(2026, 12, 1))
    create_salary(@riya, amount_cents: 83_500_000)

    ExchangeRate.create!(currency_code: "USD", units_per_usd: 1, as_of: Date.new(2026, 1, 1), source: "static table")
    ExchangeRate.create!(currency_code: "INR", units_per_usd: "83.5", as_of: Date.new(2026, 1, 1), source: "static table")
  end

  test "reports payroll in native currency and keeps indicative usd separate" do
    snapshot = Compensation::Snapshot.new(as_of: @as_of).to_h
    usd = snapshot[:payroll_by_currency].find { |row| row[:currency_code] == "USD" }
    inr = snapshot[:payroll_by_currency].find { |row| row[:currency_code] == "INR" }

    assert_equal 2, usd[:headcount]
    assert_equal 20_000_000, usd[:total_cents]
    assert_equal 10_000_000, usd[:average_cents]
    assert_equal 10_000_000, usd[:median_cents]
    assert_equal 1, inr[:headcount]
    assert_equal 83_500_000, inr[:total_cents]
    assert_not_equal usd[:total_cents] + inr[:total_cents], snapshot[:indicative_usd][:total_cents]

    assert_equal 21_000_000, snapshot[:indicative_usd][:total_cents]
    assert_match "not a payroll", snapshot[:indicative_usd][:disclaimer]
    assert_equal 3, snapshot[:payroll_headcount]
    assert_equal 3, snapshot[:headcount]["active"]
    assert_equal 1, snapshot[:headcount]["on_leave"]
    assert_equal 1, snapshot[:headcount]["terminated"]

    recent = snapshot[:recent_changes]
    assert_equal [ Date.new(2025, 1, 1) ], recent.map { |row| row[:effective_on] }
    assert_equal "Merit", recent.first[:reason_label]
  end

  test "csv export is numeric and limited to people on payroll" do
    csv = Compensation::CsvExport.new(as_of: @as_of).to_csv

    assert csv.start_with?("\uFEFF")
    assert_includes csv, "annual_salary"
    assert_includes csv, @ada.employee_number
    assert_includes csv, "120000.00"
    assert_includes csv, @grace.employee_number
    assert_not_includes csv, @gone.employee_number
    assert_not_includes csv, @future.employee_number
  end
end
