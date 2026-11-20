module Workforce
  module Catalog
    COUNTRIES = [
      { code: "IN", name: "India", currency: "INR", weight: 3200 },
      { code: "US", name: "United States", currency: "USD", weight: 2500 },
      { code: "GB", name: "United Kingdom", currency: "GBP", weight: 800 },
      { code: "DE", name: "Germany", currency: "EUR", weight: 700 },
      { code: "CA", name: "Canada", currency: "CAD", weight: 600 },
      { code: "SG", name: "Singapore", currency: "SGD", weight: 500 },
      { code: "AU", name: "Australia", currency: "AUD", weight: 500 },
      { code: "AE", name: "United Arab Emirates", currency: "AED", weight: 400 },
      { code: "JP", name: "Japan", currency: "JPY", weight: 400 },
      { code: "BR", name: "Brazil", currency: "BRL", weight: 400 }
    ].freeze

    DEPARTMENTS = [
      [ "Engineering", 40 ],
      [ "Product", 8 ],
      [ "Design", 6 ],
      [ "Sales", 14 ],
      [ "Marketing", 7 ],
      [ "People", 5 ],
      [ "Finance", 6 ],
      [ "Operations", 8 ],
      [ "Customer Success", 4 ],
      [ "Legal", 2 ]
    ].freeze

    DEPARTMENT_FACTORS = {
      "Engineering" => 108,
      "Product" => 105,
      "Design" => 98,
      "Sales" => 102,
      "Marketing" => 92,
      "People" => 85,
      "Finance" => 95,
      "Operations" => 88,
      "Customer Success" => 84,
      "Legal" => 110
    }.freeze

    LEVELS = [
      [ "IC1", 8 ],
      [ "IC2", 16 ],
      [ "IC3", 18 ],
      [ "IC4", 16 ],
      [ "IC5", 8 ],
      [ "IC6", 4 ],
      [ "M1", 14 ],
      [ "M2", 10 ],
      [ "M3", 6 ]
    ].freeze

    LADDER = {
      "IC1" => "Associate",
      "IC2" => "Specialist",
      "IC3" => "Senior Specialist",
      "IC4" => "Staff Specialist",
      "IC5" => "Principal Specialist",
      "IC6" => "Distinguished Specialist",
      "M1" => "Manager",
      "M2" => "Senior Manager",
      "M3" => "Director"
    }.freeze

    # Annual base salary, major units, before the department factor.
    BANDS = {
      "US" => {
        "IC1" => [ 90_000, 115_000 ], "IC2" => [ 115_000, 145_000 ], "IC3" => [ 145_000, 175_000 ],
        "IC4" => [ 175_000, 210_000 ], "IC5" => [ 210_000, 260_000 ], "IC6" => [ 260_000, 320_000 ],
        "M1" => [ 160_000, 200_000 ], "M2" => [ 200_000, 260_000 ], "M3" => [ 260_000, 360_000 ]
      },
      "IN" => {
        "IC1" => [ 800_000, 1_400_000 ], "IC2" => [ 1_400_000, 2_200_000 ], "IC3" => [ 2_200_000, 3_500_000 ],
        "IC4" => [ 3_500_000, 5_000_000 ], "IC5" => [ 5_000_000, 7_500_000 ], "IC6" => [ 7_500_000, 11_000_000 ],
        "M1" => [ 3_500_000, 5_500_000 ], "M2" => [ 5_500_000, 8_000_000 ], "M3" => [ 8_000_000, 14_000_000 ]
      },
      "GB" => {
        "IC1" => [ 45_000, 60_000 ], "IC2" => [ 60_000, 80_000 ], "IC3" => [ 80_000, 100_000 ],
        "IC4" => [ 100_000, 125_000 ], "IC5" => [ 125_000, 155_000 ], "IC6" => [ 155_000, 190_000 ],
        "M1" => [ 90_000, 120_000 ], "M2" => [ 120_000, 155_000 ], "M3" => [ 155_000, 210_000 ]
      },
      "DE" => {
        "IC1" => [ 50_000, 65_000 ], "IC2" => [ 65_000, 82_000 ], "IC3" => [ 82_000, 100_000 ],
        "IC4" => [ 100_000, 125_000 ], "IC5" => [ 125_000, 150_000 ], "IC6" => [ 150_000, 185_000 ],
        "M1" => [ 95_000, 120_000 ], "M2" => [ 120_000, 155_000 ], "M3" => [ 155_000, 200_000 ]
      },
      "CA" => {
        "IC1" => [ 75_000, 95_000 ], "IC2" => [ 95_000, 120_000 ], "IC3" => [ 120_000, 145_000 ],
        "IC4" => [ 145_000, 175_000 ], "IC5" => [ 175_000, 210_000 ], "IC6" => [ 210_000, 260_000 ],
        "M1" => [ 140_000, 175_000 ], "M2" => [ 175_000, 220_000 ], "M3" => [ 220_000, 300_000 ]
      },
      "SG" => {
        "IC1" => [ 60_000, 80_000 ], "IC2" => [ 80_000, 110_000 ], "IC3" => [ 110_000, 140_000 ],
        "IC4" => [ 140_000, 180_000 ], "IC5" => [ 180_000, 230_000 ], "IC6" => [ 230_000, 300_000 ],
        "M1" => [ 140_000, 180_000 ], "M2" => [ 180_000, 240_000 ], "M3" => [ 240_000, 340_000 ]
      },
      "AU" => {
        "IC1" => [ 80_000, 100_000 ], "IC2" => [ 100_000, 125_000 ], "IC3" => [ 125_000, 155_000 ],
        "IC4" => [ 155_000, 185_000 ], "IC5" => [ 185_000, 230_000 ], "IC6" => [ 230_000, 290_000 ],
        "M1" => [ 150_000, 190_000 ], "M2" => [ 190_000, 240_000 ], "M3" => [ 240_000, 320_000 ]
      },
      "AE" => {
        "IC1" => [ 180_000, 240_000 ], "IC2" => [ 240_000, 320_000 ], "IC3" => [ 320_000, 400_000 ],
        "IC4" => [ 400_000, 500_000 ], "IC5" => [ 500_000, 650_000 ], "IC6" => [ 650_000, 850_000 ],
        "M1" => [ 400_000, 520_000 ], "M2" => [ 520_000, 700_000 ], "M3" => [ 700_000, 950_000 ]
      },
      "JP" => {
        "IC1" => [ 4_500_000, 6_000_000 ], "IC2" => [ 6_000_000, 8_000_000 ], "IC3" => [ 8_000_000, 10_000_000 ],
        "IC4" => [ 10_000_000, 13_000_000 ], "IC5" => [ 13_000_000, 16_000_000 ], "IC6" => [ 16_000_000, 20_000_000 ],
        "M1" => [ 10_000_000, 13_000_000 ], "M2" => [ 13_000_000, 17_000_000 ], "M3" => [ 17_000_000, 24_000_000 ]
      },
      "BR" => {
        "IC1" => [ 80_000, 120_000 ], "IC2" => [ 120_000, 180_000 ], "IC3" => [ 180_000, 250_000 ],
        "IC4" => [ 250_000, 340_000 ], "IC5" => [ 340_000, 450_000 ], "IC6" => [ 450_000, 600_000 ],
        "M1" => [ 250_000, 360_000 ], "M2" => [ 360_000, 500_000 ], "M3" => [ 500_000, 750_000 ]
      }
    }.freeze

    # Units of local currency for one US dollar. Static, not a market feed.
    EXCHANGE_RATES = {
      "USD" => "1",
      "INR" => "83.5",
      "GBP" => "0.78",
      "EUR" => "0.92",
      "CAD" => "1.36",
      "SGD" => "1.34",
      "AUD" => "1.53",
      "AED" => "3.6725",
      "JPY" => "155",
      "BRL" => "5.10"
    }.freeze

    RATE_AS_OF = Date.new(2026, 1, 1)
    RATE_SOURCE = "static table, not a market feed".freeze

    FIRST_NAMES = %w[
      Aarav Aisha Amira Anika Arjun Bianca Carlos Chen Chioma Daniel
      Diego Elena Esther Fatima Gabriel Grace Hannah Helena Hiro Ingrid
      Isha Jamal Jonah Kabir Kenji Laila Leila Lucia Marcos Mateo Mei
      Nadia Noor Olivia Omar Paula Priya Quinn Rafael Ravi Rosa Samir
      Sara Sofia Theo Tomas Uma Valentina Wei Yara Yasmin Zoe
    ].freeze

    LAST_NAMES = %w[
      Almeida Becker Bose Carvalho Costa Das Dutta Fernandez Garcia Gupta
      Hassan Ibrahim Iyer Johnson Khan Kim Kobayashi Lopez Martins Mensah
      Nguyen Okonkwo Oliveira Patel Rahman Rossi Santos Shah Silva Singh
      Sousa Tanaka Thomas Wagner Yamamoto
    ].freeze
  end
end
