module Compensation
  class Snapshot
    DISCLAIMER = "Indicative USD is a rough comparison using static rates. It is not a payroll figure and is not used to pay anyone.".freeze

    def initialize(as_of: Date.current)
      @as_of = as_of
    end

    def to_h
      records = current_records
      by_currency = records.group_by(&:currency_code)
      rates = ExchangeRate.all.index_by(&:currency_code)
      indicative_cents, missing = indicative_usd(by_currency, rates)

      {
        as_of: as_of,
        headcount: headcount,
        payroll_headcount: records.size,
        payroll_by_currency: currency_rows(by_currency),
        by_country: country_rows(records),
        by_department: department_rows(records),
        bands: band_rows(by_currency),
        recent_changes: recent_changes,
        indicative_usd: {
          total_cents: indicative_cents,
          formatted: Money.new(indicative_cents, "USD").formatted,
          as_of: rates.values.map(&:as_of).min,
          source: rates.values.map(&:source).uniq.first,
          missing_currencies: missing,
          disclaimer: DISCLAIMER
        }
      }
    end

    private

    attr_reader :as_of

    def current_records
      SalaryRecord
        .current_for_each_employee(as_of)
        .includes(employee: [ :country, :department ])
        .joins(:employee)
        .merge(Employee.paid)
        .to_a
    end

    def headcount
      counts = Employee.group(:status).count
      Employee::STATUSES.index_with { |status| counts[status] || 0 }
    end

    def currency_rows(by_currency)
      by_currency.map { |currency, rows|
        summarize(currency, rows).merge(currency_code: currency)
      }.sort_by { |row| row[:currency_code] }
    end

    def country_rows(records)
      records.group_by { |record| [ record.employee.country, record.currency_code ] }.map { |(country, currency), rows|
        summarize(currency, rows).merge(
          country_id: country.id,
          country_code: country.code,
          country_name: country.name,
          currency_code: currency
        )
      }.sort_by { |row| [ row[:country_name], row[:currency_code] ] }
    end

    def department_rows(records)
      records.group_by { |record| [ record.employee.department, record.currency_code ] }.map { |(department, currency), rows|
        summarize(currency, rows).merge(
          department_id: department.id,
          department_name: department.name,
          currency_code: currency
        )
      }.sort_by { |row| [ row[:currency_code], row[:department_name] ] }
    end

    def band_rows(by_currency)
      by_currency.map { |currency, rows|
        majors = rows.map { |record| record.amount_cents / (10**Currencies.exponent(currency)) }
        { currency_code: currency, bands: Bands.distribution(currency, majors) }
      }.sort_by { |row| row[:currency_code] }
    end

    def summarize(currency, rows)
      amounts = rows.map(&:amount_cents)
      total = amounts.sum
      average = Stats.average(amounts)
      median = Stats.median(amounts)
      {
        headcount: amounts.length,
        total_cents: total,
        average_cents: average,
        median_cents: median,
        formatted_total: Money.new(total, currency).formatted,
        formatted_average: Money.new(average, currency).formatted,
        formatted_median: Money.new(median, currency).formatted
      }
    end

    def indicative_usd(by_currency, rates)
      total = 0
      missing = []
      by_currency.each do |currency, rows|
        rate = rates[currency]
        if rate.nil?
          missing << currency
          next
        end

        rows.each { |record| total += record.money.to_usd_cents(rate.units_per_usd) }
      end
      [ total, missing.sort ]
    end

    def recent_changes
      SalaryRecord
        .where.not(reason: "hire")
        .where(effective_on: ..as_of)
        .includes(:employee)
        .order(effective_on: :desc, id: :desc)
        .limit(12)
        .map { |record|
          SalaryRecordPresenter.new(record).as_json.merge(
            employee_id: record.employee_id,
            employee_name: record.employee.full_name,
            employee_number: record.employee.employee_number
          )
        }
    end
  end
end
