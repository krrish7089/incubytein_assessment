class Money
  class Error < StandardError; end

  attr_reader :minor_units, :currency_code

  def initialize(minor_units, currency_code)
    raise Error, "is not a supported currency" unless Currencies.known?(currency_code)

    @minor_units = Integer(minor_units)
    @currency_code = currency_code
  end

  def self.from_major(value, currency_code)
    raise Error, "is not a supported currency" unless Currencies.known?(currency_code)

    text = value.to_s.strip
    raise Error, "must be a positive number" unless text.match?(/\A\d+(\.\d+)?\z/)

    decimal = BigDecimal(text)
    raise Error, "must be greater than zero" unless decimal.positive?

    exponent = Currencies.exponent(currency_code)
    scaled = decimal * (10**exponent)
    raise Error, "has too many decimal places for #{currency_code}" unless scaled.frac.zero?

    new(scaled.to_i, currency_code)
  end

  def formatted
    sign = minor_units.negative? ? "-" : ""
    absolute = minor_units.abs
    exponent = Currencies.exponent(currency_code)
    factor = 10**exponent
    whole = absolute / factor
    body = group_thousands(whole)
    symbol = Currencies.symbol(currency_code)
    return "#{sign}#{symbol}#{body}" if exponent.zero?

    fraction = (absolute % factor).to_s.rjust(exponent, "0")
    "#{sign}#{symbol}#{body}.#{fraction}"
  end

  def major_string
    exponent = Currencies.exponent(currency_code)
    factor = 10**exponent
    return minor_units.to_s if exponent.zero?

    sprintf("%d.%0#{exponent}d", minor_units / factor, minor_units.abs % factor)
  end

  def to_usd_cents(units_per_usd)
    rate = BigDecimal(units_per_usd.to_s)
    raise Error, "exchange rate must be positive" unless rate.positive?

    major = BigDecimal(minor_units) / (10**Currencies.exponent(currency_code))
    usd = major / rate
    (usd * 100).round(0, BigDecimal::ROUND_HALF_UP).to_i
  end

  private

  def group_thousands(whole)
    whole.to_s.reverse.gsub(/(\d{3})(?=\d)/, "\\1,").reverse
  end
end
