require "csv"

module Compensation
  class CsvExport
    HEADERS = [
      "employee_number",
      "name",
      "email",
      "country",
      "department",
      "job_title",
      "job_level",
      "status",
      "currency",
      "annual_salary",
      "effective_on"
    ].freeze

    def initialize(as_of: Date.current)
      @as_of = as_of
    end

    def to_csv
      body = CSV.generate do |csv|
        csv << HEADERS
        current_records.each { |record| csv << line(record) }
      end
      "\uFEFF#{body}"
    end

    private

    attr_reader :as_of

    def current_records
      SalaryRecord
        .current_for_each_employee(as_of)
        .includes(employee: [ :country, :department ])
        .joins(:employee)
        .merge(Employee.paid)
        .order("employees.employee_number ASC")
        .to_a
    end

    def line(record)
      employee = record.employee
      [
        employee.employee_number,
        employee.full_name,
        employee.email,
        employee.country.name,
        employee.department.name,
        employee.job_title,
        employee.job_level,
        employee.status,
        record.currency_code,
        record.money.major_string,
        record.effective_on.iso8601
      ]
    end
  end
end
