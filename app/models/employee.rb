class Employee < ApplicationRecord
  STATUSES = %w[active on_leave terminated].freeze
  PAID_STATUSES = %w[active on_leave].freeze
  JOB_LEVELS = %w[IC1 IC2 IC3 IC4 IC5 IC6 M1 M2 M3].freeze

  belongs_to :country
  belongs_to :department
  has_many :salary_records, dependent: :restrict_with_exception

  normalizes :email, with: ->(email) { email.strip.downcase }
  normalizes :employee_number, with: ->(value) { value.strip.upcase }
  normalizes :first_name, :last_name, :job_title, with: ->(value) { value.strip }

  validates :employee_number, :first_name, :last_name, :email, :job_title, :job_level, :status, :hire_date, presence: true
  validates :employee_number, :email, uniqueness: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :first_name, :last_name, length: { maximum: 80 }
  validates :job_title, length: { maximum: 120 }
  validates :status, inclusion: { in: STATUSES }
  validates :job_level, inclusion: { in: JOB_LEVELS }
  validate :termination_matches_status

  scope :paid, -> { where(status: PAID_STATUSES) }

  def on_payroll_status?
    PAID_STATUSES.include?(status)
  end

  def current_salary(as_of = Date.current)
    salary_records.where(effective_on: ..as_of).order(effective_on: :desc).first
  end

  def upcoming_salary(as_of = Date.current)
    salary_records.where("effective_on > ?", as_of).order(:effective_on).first
  end

  private

  def termination_matches_status
    if status == "terminated"
      if terminated_on.blank?
        errors.add(:terminated_on, "is required when status is terminated")
      elsif hire_date.present? && terminated_on < hire_date
        errors.add(:terminated_on, "cannot be before the hire date")
      end
    elsif terminated_on.present?
      errors.add(:terminated_on, "must be blank unless status is terminated")
    end
  end
end
