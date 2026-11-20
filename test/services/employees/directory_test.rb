require "test_helper"

class Employees::DirectoryTest < ActiveSupport::TestCase
  setup do
    @us = create_country
    @india = create_country(code: "IN", name: "India", currency_code: "INR")
    @engineering = create_department
    @ada = create_employee(country: @us, department: @engineering, last_name: "Lovelace", first_name: "Ada")
    @grace = create_employee(country: @us, department: @engineering, last_name: "Hopper", first_name: "Grace", status: "on_leave")
    @gone = create_employee(
      country: @us,
      department: @engineering,
      last_name: "Gone",
      first_name: "Greta",
      status: "terminated",
      terminated_on: Date.new(2024, 1, 1)
    )
    create_salary(@ada, amount_cents: 12_000_000)
    create_salary(@grace, amount_cents: 8_000_000)
    create_salary(@gone, amount_cents: 20_000_000)
  end

  test "defaults to active people and matches a name regardless of case" do
    result = Employees::Directory.new(q: "lovelace").call

    assert_nil result.error
    assert_equal [ @ada.id ], result.records.map { |record| record.employee.id }
    assert_equal 12_000_000, result.records.first.salary.amount_cents
  end

  test "refuses a salary sort until a country is chosen" do
    result = Employees::Directory.new(sort: "salary").call

    assert_match "country", result.error
    assert_empty result.records
  end

  test "sorts salary within one country and paginates" do
    result = Employees::Directory.new(
      country_id: @us.id,
      status: "all",
      sort: "salary",
      direction: "asc",
      per_page: 2,
      page: 1
    ).call

    assert_equal [ 8_000_000, 12_000_000 ], result.records.map { |record| record.salary.amount_cents }
    assert_equal 3, result.total

    page_two = Employees::Directory.new(
      country_id: @us.id,
      status: "all",
      sort: "salary",
      direction: "asc",
      per_page: 2,
      page: 2
    ).call
    assert_equal [ 20_000_000 ], page_two.records.map { |record| record.salary.amount_cents }
  end
end
