module Compensation
  module Stats
    module_function

    def median(values)
      sorted = values.sort
      length = sorted.length
      return nil if length.zero?
      return sorted[length / 2] if length.odd?

      half_up(sorted[(length / 2) - 1] + sorted[length / 2], 2)
    end

    def average(values)
      return nil if values.empty?

      half_up(values.sum, values.length)
    end

    def half_up(numerator, denominator)
      (numerator + (denominator / 2)) / denominator
    end
  end
end
