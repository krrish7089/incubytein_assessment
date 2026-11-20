require "test_helper"

class Api::V1::EmployeesTest < ActionDispatch::IntegrationTest
  setup do
    @country = create_country
    @department = create_department
    @account = HrAccount.create!(name: "Avery Chen", email: "hr@acme.test", password: "Acme-HR-2026")
    post "/api/v1/session", params: { email: @account.email, password: "Acme-HR-2026" }, as: :json
  end

  test "hires a person and records a later merit increase" do
    post "/api/v1/employees", params: {
      employee: {
        first_name: "Ada",
        last_name: "Lovelace",
        email: "ada@acme.test",
        country_id: @country.id,
        department_id: @department.id,
        job_title: "Engineer",
        job_level: "IC3",
        hire_date: "2024-01-15",
        salary_amount: "100000"
      }
    }, as: :json

    assert_response :created
    body = response.parsed_body.fetch("employee")
    assert_equal "USD", body.dig("current_salary", "currency_code")
    assert_equal 10_000_000, body.dig("current_salary", "amount_cents")

    post "/api/v1/employees/#{body.fetch("id")}/salary_records", params: {
      salary_record: { salary_amount: "110000", effective_on: "2025-01-01", reason: "merit" }
    }, as: :json
    assert_response :created

    get "/api/v1/employees/#{body.fetch("id")}", as: :json
    assert_response :success
    assert_equal 11_000_000, response.parsed_body.dig("employee", "current_salary", "amount_cents")
    assert_equal 2, response.parsed_body.dig("employee", "salary_history").length
  end

  test "export is a numeric csv of people on payroll" do
    Employees::Hire.new(
      first_name: "Ada",
      last_name: "Lovelace",
      email: "ada@acme.test",
      country_id: @country.id,
      department_id: @department.id,
      job_title: "Engineer",
      job_level: "IC3",
      hire_date: Date.new(2024, 1, 15),
      salary_amount: "100000"
    ).save

    get "/api/v1/exports/compensation"
    assert_response :success
    assert_includes response.body, "annual_salary"
    assert_includes response.body, "100000.00"
    assert_includes response.media_type, "text/csv"
  end
end
