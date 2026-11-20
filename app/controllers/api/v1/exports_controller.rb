module Api
  module V1
    class ExportsController < BaseController
      def show
        send_data Compensation::CsvExport.new.to_csv,
          filename: "acme-compensation-#{Date.current.iso8601}.csv",
          type: "text/csv; charset=utf-8",
          disposition: "attachment"
      end
    end
  end
end
