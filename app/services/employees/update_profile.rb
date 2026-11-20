module Employees
  class UpdateProfile
    include ActiveModel::Model

    ALLOWED = %i[first_name last_name email job_title job_level department_id status terminated_on].freeze

    attr_reader :employee

    def initialize(employee:, attributes:)
      @employee = employee
      @attributes = attributes.to_h.symbolize_keys.slice(*ALLOWED)
      super()
    end

    def save
      employee.assign_attributes(attributes)
      employee.terminated_on = nil unless employee.status == "terminated"
      return true if employee.save

      errors.merge!(employee.errors)
      false
    end

    private

    attr_reader :attributes
  end
end
