module Api
  module V1
    class SessionsController < BaseController
      skip_before_action :require_hr_account

      def show
        account = HrAccount.find_by(id: session[:hr_account_id])
        render json: { hr: account && hr_json(account), csrf_token: form_authenticity_token }
      end

      def create
        account = HrAccount.find_by(email: params[:email].to_s.strip.downcase)
        if account&.authenticate(params[:password].to_s)
          reset_session
          session[:hr_account_id] = account.id
          render json: { hr: hr_json(account), csrf_token: form_authenticity_token }
        else
          render json: { error: "Email or password is incorrect" }, status: :unauthorized
        end
      end

      def destroy
        reset_session
        head :no_content
      end
    end
  end
end
