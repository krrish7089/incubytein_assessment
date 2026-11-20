module Employees
  class Directory
    SORTS = %w[name hire_date salary].freeze
    DEFAULT_PER_PAGE = 25
    MAX_PER_PAGE = 100

    Result = Struct.new(:records, :page, :per_page, :total, :error, keyword_init: true)
    Record = Struct.new(:employee, :salary, keyword_init: true)

    def initialize(params = {})
      data = params.to_h.symbolize_keys
      @q = data[:q].to_s.strip.first(80)
      @country_id = data[:country_id].presence
      @department_id = data[:department_id].presence
      @status = data[:status].presence || "active"
      @sort = data[:sort].presence || "name"
      @direction = data[:direction].to_s == "desc" ? "desc" : "asc"
      @page = [ data[:page].to_i, 1 ].max
      @per_page = data[:per_page].to_i
      @per_page = DEFAULT_PER_PAGE if @per_page <= 0
      @per_page = MAX_PER_PAGE if @per_page > MAX_PER_PAGE
    end

    def call
      return failure("Status must be active, on leave, terminated, or all.") unless known_status?
      return failure("Sort must be name, hire date, or salary.") unless SORTS.include?(sort)
      if sort == "salary" && country_id.blank?
        return failure("Choose a country before sorting by salary so every amount shares one currency.")
      end

      scope = ordered(filtered)
      total = scope.except(:order).distinct.count(:id)
      employees = scope.offset((page - 1) * per_page).limit(per_page).includes(:country, :department).to_a
      salaries = SalaryRecord.current_for_each_employee.where(employee_id: employees.map(&:id)).index_by(&:employee_id)
      records = employees.map { |employee| Record.new(employee: employee, salary: salaries[employee.id]) }

      Result.new(records: records, page: page, per_page: per_page, total: total, error: nil)
    end

    private

    attr_reader :q, :country_id, :department_id, :status, :sort, :direction, :page, :per_page

    def known_status?
      status == "all" || Employee::STATUSES.include?(status)
    end

    def failure(message)
      Result.new(records: [], page: page, per_page: per_page, total: 0, error: message)
    end

    def filtered
      scope = Employee.all
      scope = scope.where(status: status) unless status == "all"
      scope = scope.where(country_id: country_id) if country_id.present?
      scope = scope.where(department_id: department_id) if department_id.present?
      return scope if q.blank?

      like = "%#{ActiveRecord::Base.sanitize_sql_like(q)}%"
      scope.where(
        "employees.first_name LIKE :q OR employees.last_name LIKE :q OR employees.email LIKE :q OR employees.employee_number LIKE :q OR (employees.first_name || ' ' || employees.last_name) LIKE :q",
        q: like
      )
    end

    def ordered(scope)
      case sort
      when "hire_date"
        scope.order(hire_date: direction, id: :asc)
      when "salary"
        scope.joins(current_pay_join).order(salary_order)
      else
        scope.order(last_name: direction, first_name: direction, id: :asc)
      end
    end

    def current_pay_join
      subquery = SalaryRecord.current_for_each_employee.select(
        "salary_records.employee_id, salary_records.amount_cents"
      ).to_sql

      "INNER JOIN (#{subquery}) current_pay ON current_pay.employee_id = employees.id"
    end

    def salary_order
      Arel.sql("current_pay.amount_cents #{direction == "desc" ? "DESC" : "ASC"}")
    end
  end
end
