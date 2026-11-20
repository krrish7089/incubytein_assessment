require "test_helper"

class Workforce::SeederTest < ActiveSupport::TestCase
  test "plans ten thousand employees across the country weights" do
    assert_equal 10_000, Workforce::Seeder::DEFAULT_COUNT
    assert_equal 10_000, Workforce::Catalog::COUNTRIES.sum { |row| row[:weight] }
  end

  test "builds a coherent workforce once" do
    seeder = Workforce::Seeder.new(employee_count: 40, random: Random.new(1), as_of: Date.new(2026, 11, 1))
    seeder.call

    assert_equal 40, Employee.count
    assert_equal 1, HrAccount.where(email: "hr@acme.test").count
    assert_equal Currencies::CODES.sort, ExchangeRate.pluck(:currency_code).sort

    Employee.includes(:country, :salary_records).find_each do |employee|
      assert employee.salary_records.any?
      dates = employee.salary_records.map(&:effective_on)
      assert_equal dates.uniq, dates
      employee.salary_records.each do |salary|
        assert_equal employee.country.currency_code, salary.currency_code
        assert_operator salary.effective_on, :>=, employee.hire_date
        assert_operator salary.effective_on, :<=, Date.new(2026, 11, 1)
        assert salary.amount_cents.positive?
      end
      if employee.status == "terminated"
        assert employee.terminated_on
      else
        assert_nil employee.terminated_on
      end
    end

    seeder.call
    assert_equal 40, Employee.count
  end
end
