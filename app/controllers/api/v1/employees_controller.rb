module Api
  module V1
    class EmployeesController < BaseController
      def index
        result = Employees::Directory.new(directory_params).call
        if result.error
          render json: { error: result.error }, status: :unprocessable_entity
          return
        end

        render json: {
          employees: result.records.map { |record|
            EmployeePresenter.new(record.employee, salary: record.salary).as_list_json
          },
          meta: {
            page: result.page,
            per_page: result.per_page,
            total: result.total,
            total_pages: (result.total.to_f / result.per_page).ceil
          }
        }
      end

      def show
        employee = Employee.includes(:country, :department, :salary_records).find(params[:id])
        render json: { employee: EmployeePresenter.new(employee).as_detail_json }
      end

      def create
        form = Employees::Hire.new(hire_params)
        if form.save
          render json: { employee: EmployeePresenter.new(form.employee).as_detail_json }, status: :created
        else
          render json: { errors: form.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        employee = Employee.find(params[:id])
        form = Employees::UpdateProfile.new(employee: employee, attributes: profile_params)
        if form.save
          render json: { employee: EmployeePresenter.new(employee).as_detail_json }
        else
          render json: { errors: form.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def directory_params
        params.permit(:q, :country_id, :department_id, :status, :sort, :direction, :page, :per_page).to_h
      end

      def hire_params
        params.require(:employee).permit(
          :first_name, :last_name, :email, :country_id, :department_id,
          :job_title, :job_level, :hire_date, :salary_amount
        ).to_h
      end

      def profile_params
        params.require(:employee).permit(
          :first_name, :last_name, :email, :job_title, :job_level, :department_id, :status, :terminated_on
        ).to_h
      end
    end
  end
end
