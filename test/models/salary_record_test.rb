require "test_helper"

class SalaryRecordTest < ActiveSupport::TestCase
  setup do
    @country = create_country
    @india = create_country(code: "IN", name: "India", currency_code: "INR")
    @department = create_department
    @employee = create_employee(country: @country, department: @department)
  end

  test "requires a positive amount in the country currency on or after the hire date" do
    record = @employee.salary_records.build(
      amount_cents: 0,
      currency_code: "INR",
      effective_on: Date.new(2020, 1, 1),
      reason: "hire"
    )

    assert_not record.valid?
    assert_includes record.errors[:amount_cents], "must be greater than 0"
    assert_includes record.errors[:currency_code], "must match the employee's country currency"
    assert_includes record.errors[:effective_on], "cannot be before the hire date"
  end

  test "allows one record per effective date and resolves the current row for each person" do
    create_salary(@employee, amount_cents: 8_000_000, effective_on: Date.new(2022, 1, 15))
    create_salary(@employee, amount_cents: 9_500_000, effective_on: Date.new(2024, 1, 1), reason: "merit")
    other = create_employee(country: @india, department: @department)
    create_salary(other, amount_cents: 2_400_000_00, effective_on: Date.new(2023, 6, 1))

    duplicate = @employee.salary_records.build(
      amount_cents: 9_600_000,
      currency_code: "USD",
      effective_on: Date.new(2024, 1, 1),
      reason: "correction"
    )
    assert_not duplicate.valid?

    current = SalaryRecord.current_for_each_employee(Date.new(2026, 6, 1)).order(:employee_id)

    assert_equal [ 9_500_000, 240_000_000 ], current.map(&:amount_cents).sort
    assert_equal [ "INR", "USD" ], current.map(&:currency_code).sort
  end
end
