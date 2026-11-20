module Currencies
  CATALOG = {
    "USD" => { exponent: 2, symbol: "$", name: "US Dollar" },
    "INR" => { exponent: 2, symbol: "₹", name: "Indian Rupee" },
    "GBP" => { exponent: 2, symbol: "£", name: "Pound Sterling" },
    "EUR" => { exponent: 2, symbol: "€", name: "Euro" },
    "SGD" => { exponent: 2, symbol: "S$", name: "Singapore Dollar" },
    "CAD" => { exponent: 2, symbol: "CA$", name: "Canadian Dollar" },
    "AUD" => { exponent: 2, symbol: "A$", name: "Australian Dollar" },
    "AED" => { exponent: 2, symbol: "AED ", name: "UAE Dirham" },
    "BRL" => { exponent: 2, symbol: "R$", name: "Brazilian Real" },
    "JPY" => { exponent: 0, symbol: "¥", name: "Japanese Yen" }
  }.freeze

  CODES = CATALOG.keys.freeze

  def self.known?(code)
    CATALOG.key?(code)
  end

  def self.exponent(code)
    CATALOG.fetch(code).fetch(:exponent)
  end

  def self.symbol(code)
    CATALOG.fetch(code).fetch(:symbol)
  end
end
