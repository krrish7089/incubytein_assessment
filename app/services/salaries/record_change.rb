module Salaries
  class RecordChange
    include ActiveModel::Model

    attr_accessor :employee, :salary_amount, :effective_on, :reason, :note, :job_title, :job_level
    attr_reader :salary_record

    validates :employee, :salary_amount, :effective_on, :reason, presence: true
    validates :reason, inclusion: { in: SalaryRecord::CHANGE_REASONS }, allow_blank: true
    validates :job_level, presence: true, inclusion: { in: Employee::JOB_LEVELS }, if: :promotion?
    validates :job_title, length: { maximum: 120 }, allow_blank: true
    validates :note, length: { maximum: 500 }, allow_blank: true

    def save
      return false unless valid?

      ActiveRecord::Base.transaction do
        money = Money.from_major(salary_amount, employee.country.currency_code)
        @salary_record = employee.salary_records.create!(
          amount_cents: money.minor_units,
          currency_code: money.currency_code,
          effective_on: effective_on,
          reason: reason,
          note: note.presence
        )
        apply_promotion if promotion?
      end
      true
    rescue Money::Error => error
      errors.add(:salary_amount, error.message)
      false
    rescue ActiveRecord::RecordInvalid => error
      error.record.errors.each { |attr_error| errors.add(attr_error.attribute, attr_error.message) }
      false
    rescue ActiveRecord::RecordNotUnique
      errors.add(:effective_on, "already has a salary record")
      false
    end

    private

    def promotion?
      reason == "promotion"
    end

    def apply_promotion
      employee.job_level = job_level
      employee.job_title = job_title if job_title.present?
      employee.save!
    end
  end
end
