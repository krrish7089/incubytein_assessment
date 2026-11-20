require "test_helper"

class Employees::UpdateProfileTest < ActiveSupport::TestCase
  setup do
    @country = create_country
    @other = create_country(code: "IN", name: "India", currency_code: "INR")
    @department = create_department
    @sales = create_department(name: "Sales")
    @employee = create_employee(
      country: @country,
      department: @department,
      status: "terminated",
      terminated_on: Date.new(2024, 1, 1)
    )
  end

  test "returning someone to active clears the termination date and ignores country" do
    form = Employees::UpdateProfile.new(
      employee: @employee,
      attributes: { status: "active", department_id: @sales.id, country_id: @other.id }
    )

    assert form.save, form.errors.full_messages
    @employee.reload
    assert_equal "active", @employee.status
    assert_nil @employee.terminated_on
    assert_equal @sales.id, @employee.department_id
    assert_equal @country.id, @employee.country_id
  end
end
