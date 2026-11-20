class Country < ApplicationRecord
  has_many :employees, dependent: :restrict_with_exception

  normalizes :code, with: ->(code) { code.strip.upcase }
  normalizes :currency_code, with: ->(code) { code.strip.upcase }

  validates :code, presence: true, uniqueness: true, length: { is: 2 }
  validates :name, presence: true
  validates :currency_code, presence: true, inclusion: { in: Currencies::CODES }
end
