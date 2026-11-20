module Api
  module V1
    class SalaryRecordsController < BaseController
      def create
        employee = Employee.find(params[:employee_id])
        form = Salaries::RecordChange.new(salary_params.merge(employee: employee))
        if form.save
          render json: { salary_record: SalaryRecordPresenter.new(form.salary_record).as_json }, status: :created
        else
          render json: { errors: form.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def salary_params
        params.require(:salary_record).permit(
          :salary_amount, :effective_on, :reason, :note, :job_title, :job_level
        ).to_h
      end
    end
  end
end
