require "test_helper"

class EmployeeTest < ActiveSupport::TestCase
  setup do
    @country = create_country
    @department = create_department
  end

  test "downcases email and requires a termination date only when terminated" do
    employee = create_employee(country: @country, department: @department, email: "  HR.Manager@Acme.Test ")

    assert_equal "hr.manager@acme.test", employee.email
    assert employee.on_payroll_status?

    employee.status = "terminated"
    assert_not employee.valid?
    assert_includes employee.errors[:terminated_on], "is required when status is terminated"

    employee.terminated_on = Date.new(2021, 1, 1)
    assert_not employee.valid?

    employee.terminated_on = Date.new(2024, 5, 1)
    assert employee.valid?
    assert_not employee.on_payroll_status?
  end

  test "current salary ignores a future effective date" do
    employee = create_employee(country: @country, department: @department)
    create_salary(employee, amount_cents: 9_000_000, effective_on: Date.new(2022, 1, 15))
    create_salary(employee, amount_cents: 11_000_000, effective_on: Date.new(2024, 4, 1), reason: "merit")
    create_salary(employee, amount_cents: 12_000_000, effective_on: Date.new(2026, 12, 1), reason: "merit")

    as_of = Date.new(2026, 6, 1)

    assert_equal 11_000_000, employee.current_salary(as_of).amount_cents
    assert_equal 12_000_000, employee.upcoming_salary(as_of).amount_cents
  end

  test "refuses to destroy an employee who has salary history" do
    employee = create_employee(country: @country, department: @department)
    create_salary(employee)

    assert_raises(ActiveRecord::DeleteRestrictionError) { employee.destroy! }
  end
end
