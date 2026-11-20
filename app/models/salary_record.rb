class SalaryRecord < ApplicationRecord
  REASONS = %w[hire merit promotion market_adjustment correction].freeze
  CHANGE_REASONS = %w[merit promotion market_adjustment correction].freeze

  belongs_to :employee

  validates :amount_cents, numericality: { only_integer: true, greater_than: 0 }
  validates :currency_code, :effective_on, :reason, presence: true
  validates :reason, inclusion: { in: REASONS }
  validates :currency_code, inclusion: { in: Currencies::CODES }
  validates :note, length: { maximum: 500 }, allow_blank: true
  validates :effective_on, uniqueness: { scope: :employee_id }
  validate :currency_matches_country
  validate :not_before_hire

  def self.current_for_each_employee(as_of = Date.current)
    latest = SalaryRecord
      .select("salary_records.employee_id, MAX(salary_records.effective_on) AS effective_on")
      .where(effective_on: ..as_of)
      .group("salary_records.employee_id")

    joins(<<~SQL.squish)
      INNER JOIN (#{latest.to_sql}) current_salary
        ON current_salary.employee_id = salary_records.employee_id
       AND current_salary.effective_on = salary_records.effective_on
    SQL
  end

  def money
    Money.new(amount_cents, currency_code)
  end

  private

  def currency_matches_country
    return if employee.nil? || currency_code.blank?
    return if employee.country&.currency_code == currency_code

    errors.add(:currency_code, "must match the employee's country currency")
  end

  def not_before_hire
    return if employee.nil? || effective_on.blank? || employee.hire_date.blank?
    return if effective_on >= employee.hire_date

    errors.add(:effective_on, "cannot be before the hire date")
  end
end
