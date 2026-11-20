module Api
  module V1
    class DashboardController < BaseController
      def show
        render json: Compensation::Snapshot.new.to_h
      end
    end
  end
end
