require "test_helper"

class Api::V1::DashboardTest < ActionDispatch::IntegrationTest
  test "dashboard keeps each currency's payroll separate" do
    HrAccount.create!(name: "Avery Chen", email: "hr@acme.test", password: "Acme-HR-2026")
    post "/api/v1/session", params: { email: "hr@acme.test", password: "Acme-HR-2026" }, as: :json

    us = create_country
    india = create_country(code: "IN", name: "India", currency_code: "INR")
    department = create_department
    hire(us, "ada@acme.test", "100000")
    hire(india, "riya@acme.test", "835000")
    ExchangeRate.create!(currency_code: "USD", units_per_usd: 1, as_of: Date.new(2026, 1, 1), source: "static table")
    ExchangeRate.create!(currency_code: "INR", units_per_usd: "83.5", as_of: Date.new(2026, 1, 1), source: "static table")

    get "/api/v1/dashboard", as: :json
    assert_response :success
    body = response.parsed_body
    totals = body.fetch("payroll_by_currency").to_h { |row| [ row.fetch("currency_code"), row.fetch("total_cents") ] }

    assert_equal 10_000_000, totals["USD"]
    assert_equal 83_500_000, totals["INR"]
    assert_equal 11_000_000, body.dig("indicative_usd", "total_cents")
    assert_match "not a payroll", body.dig("indicative_usd", "disclaimer")
  end

  private

  def hire(country, email, amount)
    Employees::Hire.new(
      first_name: "Ada",
      last_name: "Lovelace",
      email: email,
      country_id: country.id,
      department_id: Department.first.id,
      job_title: "Engineer",
      job_level: "IC3",
      hire_date: Date.new(2024, 1, 15),
      salary_amount: amount
    ).save
  end
end
