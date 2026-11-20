class SalaryRecordPresenter
  REASON_LABELS = {
    "hire" => "Hire",
    "merit" => "Merit",
    "promotion" => "Promotion",
    "market_adjustment" => "Market adjustment",
    "correction" => "Correction"
  }.freeze

  def initialize(record)
    @record = record
  end

  def as_json
    money = record.money
    {
      id: record.id,
      amount_cents: record.amount_cents,
      currency_code: record.currency_code,
      formatted: money.formatted,
      major: money.major_string,
      effective_on: record.effective_on,
      reason: record.reason,
      reason_label: REASON_LABELS.fetch(record.reason),
      note: record.note
    }
  end

  private

  attr_reader :record
end
