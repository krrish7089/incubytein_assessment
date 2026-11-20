module Employees
  class Hire
    include ActiveModel::Model

    attr_accessor :first_name, :last_name, :email, :country_id, :department_id,
      :job_title, :job_level, :hire_date, :salary_amount
    attr_reader :employee

    validates :first_name, :last_name, :email, :country_id, :department_id,
      :job_title, :job_level, :hire_date, :salary_amount, presence: true
    validates :job_level, inclusion: { in: Employee::JOB_LEVELS }, allow_blank: true

    def save
      return false unless valid?

      country = Country.find_by(id: country_id)
      department = Department.find_by(id: department_id)
      errors.add(:country_id, "is not a known country") unless country
      errors.add(:department_id, "is not a known department") unless department
      return false if errors.any?

      ActiveRecord::Base.transaction do
        money = Money.from_major(salary_amount, country.currency_code)
        @employee = Employee.new(
          first_name: first_name,
          last_name: last_name,
          email: email,
          country: country,
          department: department,
          job_title: job_title,
          job_level: job_level,
          hire_date: hire_date,
          status: "active"
        )
        @employee.employee_number = next_employee_number
        @employee.save!
        @employee.salary_records.create!(
          amount_cents: money.minor_units,
          currency_code: money.currency_code,
          effective_on: @employee.hire_date,
          reason: "hire"
        )
      end
      true
    rescue Money::Error => error
      errors.add(:salary_amount, error.message)
      false
    rescue ActiveRecord::RecordInvalid => error
      error.record.errors.each { |attr_error| errors.add(attr_error.attribute, attr_error.message) }
      false
    end

    private

    def next_employee_number
      last = Employee.order(employee_number: :desc).pick(:employee_number)
      sequence = last.to_s[/\d+\z/].to_i + 1
      format("ACME-%06d", sequence)
    end
  end
end
