module Api
  module V1
    class ReferenceController < BaseController
      def show
        render json: {
          countries: Country.order(:name).map { |country|
            { id: country.id, code: country.code, name: country.name, currency_code: country.currency_code }
          },
          departments: Department.order(:name).map { |department| { id: department.id, name: department.name } },
          job_levels: Employee::JOB_LEVELS,
          statuses: Employee::STATUSES,
          salary_reasons: SalaryRecord::CHANGE_REASONS.map { |reason|
            { value: reason, label: SalaryRecordPresenter::REASON_LABELS.fetch(reason) }
          }
        }
      end
    end
  end
end
