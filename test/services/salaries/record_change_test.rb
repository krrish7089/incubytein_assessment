require "test_helper"

class Salaries::RecordChangeTest < ActiveSupport::TestCase
  setup do
    @country = create_country
    @department = create_department
    @employee = create_employee(country: @country, department: @department, job_level: "IC3", job_title: "Engineer")
    create_salary(@employee, amount_cents: 10_000_000, effective_on: Date.new(2022, 1, 15))
  end

  test "a merit increase is current and a future change is not" do
    assert change(salary_amount: "120000", effective_on: Date.new(2025, 1, 1), reason: "merit")

    as_of = Date.new(2026, 6, 1)
    assert_equal 12_000_000, @employee.current_salary(as_of).amount_cents

    assert change(salary_amount: "130000", effective_on: Date.new(2026, 12, 1), reason: "market_adjustment")
    assert_equal 12_000_000, @employee.current_salary(as_of).amount_cents
    assert_equal 13_000_000, @employee.upcoming_salary(as_of).amount_cents
  end

  test "a promotion updates level and title with the salary row" do
    assert change(
      salary_amount: "160000",
      effective_on: Date.new(2025, 6, 1),
      reason: "promotion",
      job_level: "IC4",
      job_title: "Staff Engineer"
    )

    @employee.reload
    assert_equal "IC4", @employee.job_level
    assert_equal "Staff Engineer", @employee.job_title
    assert_equal "promotion", @employee.current_salary(Date.new(2026, 1, 1)).reason
  end

  test "a correction may lower pay and a second change on the same day is rejected" do
    assert change(salary_amount: "90000", effective_on: Date.new(2025, 2, 1), reason: "correction")
    assert_equal 9_000_000, @employee.current_salary(Date.new(2026, 1, 1)).amount_cents

    duplicate = Salaries::RecordChange.new(
      employee: @employee,
      salary_amount: "91000",
      effective_on: Date.new(2025, 2, 1),
      reason: "merit"
    )
    assert_not duplicate.save
    assert_includes duplicate.errors.full_messages.join(" "), "Effective on"
  end

  test "opening hire is not a valid reason for a later change" do
    form = Salaries::RecordChange.new(
      employee: @employee,
      salary_amount: "110000",
      effective_on: Date.new(2025, 3, 1),
      reason: "hire"
    )

    assert_not form.save
  end

  private

  def change(**attrs)
    form = Salaries::RecordChange.new({ employee: @employee }.merge(attrs))
    assert form.save, form.errors.full_messages
    true
  end
end
