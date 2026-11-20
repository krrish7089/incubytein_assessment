class EmployeePresenter
  def initialize(employee, salary: :unloaded, as_of: Date.current)
    @employee = employee
    @salary = salary
    @as_of = as_of
  end

  def as_list_json
    base.merge(current_salary: salary_json(resolved_salary))
  end

  def as_detail_json
    as_list_json.merge(
      upcoming_salary: salary_json(employee.upcoming_salary(as_of)),
      salary_history: employee.salary_records.order(effective_on: :desc, id: :desc).map { |record|
        SalaryRecordPresenter.new(record).as_json
      }
    )
  end

  private

  attr_reader :employee, :salary, :as_of

  def resolved_salary
    return employee.current_salary(as_of) if salary == :unloaded

    salary
  end

  def salary_json(record)
    return nil unless record

    SalaryRecordPresenter.new(record).as_json
  end

  def base
    {
      id: employee.id,
      employee_number: employee.employee_number,
      first_name: employee.first_name,
      last_name: employee.last_name,
      full_name: employee.full_name,
      email: employee.email,
      country: {
        id: employee.country_id,
        code: employee.country.code,
        name: employee.country.name,
        currency_code: employee.country.currency_code
      },
      department: {
        id: employee.department_id,
        name: employee.department.name
      },
      job_title: employee.job_title,
      job_level: employee.job_level,
      status: employee.status,
      hire_date: employee.hire_date,
      terminated_on: employee.terminated_on
    }
  end
end
