module Compensation
  module Bands
    THRESHOLDS = {
      "USD" => [ 80_000, 120_000, 160_000, 220_000, 300_000 ],
      "INR" => [ 1_500_000, 3_000_000, 5_000_000, 8_000_000, 12_000_000 ],
      "GBP" => [ 50_000, 80_000, 110_000, 150_000, 200_000 ],
      "EUR" => [ 55_000, 85_000, 115_000, 150_000, 200_000 ],
      "CAD" => [ 80_000, 120_000, 160_000, 210_000, 280_000 ],
      "SGD" => [ 70_000, 110_000, 150_000, 200_000, 280_000 ],
      "AUD" => [ 90_000, 130_000, 170_000, 220_000, 300_000 ],
      "AED" => [ 200_000, 320_000, 450_000, 650_000, 900_000 ],
      "BRL" => [ 100_000, 180_000, 280_000, 400_000, 600_000 ],
      "JPY" => [ 5_000_000, 8_000_000, 11_000_000, 15_000_000, 20_000_000 ]
    }.freeze

    def self.distribution(currency_code, major_amounts)
      edges = THRESHOLDS.fetch(currency_code)
      labels = labels_for(edges)
      counts = Array.new(labels.length, 0)

      major_amounts.each do |amount|
        index = edges.index { |edge| amount < edge } || (edges.length)
        counts[index] += 1
      end

      labels.each_with_index.map { |label, index| { label: label, count: counts[index] } }
    end

    def self.labels_for(edges)
      formatted = edges.map { |edge| group(edge) }
      labels = [ "Under #{formatted.first}" ]
      formatted.each_cons(2) { |lower, upper| labels << "#{lower} to #{upper}" }
      labels << "#{formatted.last} and above"
      labels
    end

    def self.group(number)
      number.to_s.reverse.gsub(/(\d{3})(?=\d)/, "\\1,").reverse
    end
    private_class_method :labels_for, :group
  end
end
