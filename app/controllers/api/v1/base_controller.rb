module Api
  module V1
    class BaseController < ApplicationController
      before_action :require_hr_account

      rescue_from ActiveRecord::RecordNotFound do
        render json: { error: "Not found" }, status: :not_found
      end

      rescue_from ActionController::InvalidAuthenticityToken do
        render json: { error: "Session expired. Refresh the page and try again." }, status: :unprocessable_entity
      end

      private

      def require_hr_account
        @current_hr = HrAccount.find_by(id: session[:hr_account_id])
        return if @current_hr

        render json: { error: "Sign in required" }, status: :unauthorized
      end

      def hr_json(account)
        { id: account.id, name: account.name, email: account.email }
      end
    end
  end
end
