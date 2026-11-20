class ExchangeRate < ApplicationRecord
  normalizes :currency_code, with: ->(code) { code.strip.upcase }

  validates :currency_code, presence: true, uniqueness: true, inclusion: { in: Currencies::CODES }
  validates :units_per_usd, numericality: { greater_than: 0 }
  validates :as_of, :source, presence: true
end
