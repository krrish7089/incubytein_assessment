require "test_helper"

class Employees::HireTest < ActiveSupport::TestCase
  setup do
    @country = create_country
    @japan = create_country(code: "JP", name: "Japan", currency_code: "JPY")
    @department = create_department
  end

  test "creates the person and an opening salary in the country currency" do
    form = hire(country: @country, salary_amount: "145000.50")

    assert form.save, form.errors.full_messages
    employee = form.employee
    salary = employee.current_salary

    assert_equal "ACME-000001", employee.employee_number
    assert_equal "hire", salary.reason
    assert_equal employee.hire_date, salary.effective_on
    assert_equal "USD", salary.currency_code
    assert_equal 14_500_050, salary.amount_cents

    second = hire(country: @country, email: "second@acme.test")
    assert second.save, second.errors.full_messages
    assert_equal "ACME-000002", second.employee.employee_number
  end

  test "does not create a person when the salary cannot be parsed" do
    form = hire(country: @japan, salary_amount: "5000000.5")

    assert_not form.save
    assert_includes form.errors[:salary_amount], "has too many decimal places for JPY"
    assert_equal 0, Employee.count
  end

  private

  def hire(country:, salary_amount: "100000", email: "ada@acme.test")
    Employees::Hire.new(
      first_name: "Ada",
      last_name: "Lovelace",
      email: email,
      country_id: country.id,
      department_id: @department.id,
      job_title: "Engineer",
      job_level: "IC3",
      hire_date: Date.new(2024, 3, 1),
      salary_amount: salary_amount
    )
  end
end
