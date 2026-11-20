module PayrollHelper
  def create_country(code: "US", name: "United States", currency_code: "USD")
    Country.create!(code: code, name: name, currency_code: currency_code)
  end

  def create_department(name: "Engineering")
    Department.create!(name: name)
  end

  def create_employee(country:, department:, **attrs)
    Employee.create!({
      employee_number: "ACME-#{SecureRandom.hex(4).upcase}",
      first_name: "Ada",
      last_name: "Lovelace",
      email: "ada-#{SecureRandom.hex(4)}@acme.test",
      country: country,
      department: department,
      job_title: "Engineer",
      job_level: "IC3",
      status: "active",
      hire_date: Date.new(2022, 1, 15)
    }.merge(attrs))
  end

  def create_salary(employee, amount_cents: 10_000_000, effective_on: employee.hire_date, reason: "hire", currency_code: employee.country.currency_code)
    employee.salary_records.create!(
      amount_cents: amount_cents,
      currency_code: currency_code,
      effective_on: effective_on,
      reason: reason
    )
  end
end
