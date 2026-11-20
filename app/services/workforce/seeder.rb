module Workforce
  class Seeder
    DEFAULT_COUNT = 10_000
    SEED = 42
    BATCH = 500
    DEMO_EMAIL = "hr@acme.test".freeze
    DEMO_PASSWORD = "Acme-HR-2026".freeze

    def initialize(employee_count: DEFAULT_COUNT, random: Random.new(SEED), as_of: Date.current, password: ENV.fetch("HR_PASSWORD", DEMO_PASSWORD))
      @employee_count = employee_count
      @random = random
      @as_of = as_of
      @password = password
    end

    def call
      countries = upsert_countries
      departments = upsert_departments
      upsert_rates
      ensure_hr_account
      return if Employee.exists?

      insert_workforce(countries, departments)
    end

    private

    attr_reader :employee_count, :random, :as_of, :password

    def upsert_countries
      Catalog::COUNTRIES.to_h do |row|
        country = Country.find_or_create_by!(code: row[:code]) do |record|
          record.name = row[:name]
          record.currency_code = row[:currency]
        end
        [ row[:code], country ]
      end
    end

    def upsert_departments
      Catalog::DEPARTMENTS.to_h do |name, _weight|
        [ name, Department.find_or_create_by!(name: name) ]
      end
    end

    def upsert_rates
      Catalog::EXCHANGE_RATES.each do |currency, units|
        ExchangeRate.find_or_create_by!(currency_code: currency) do |rate|
          rate.units_per_usd = units
          rate.as_of = Catalog::RATE_AS_OF
          rate.source = Catalog::RATE_SOURCE
        end
      end
    end

    def ensure_hr_account
      HrAccount.find_or_create_by!(email: DEMO_EMAIL) do |account|
        account.name = "Avery Chen"
        account.password = password
      end
    end

    def insert_workforce(countries, departments)
      people = []
      plans = []
      country_sequence(countries).each_with_index do |country, index|
        person, records = build_person(index, country, departments)
        people << person
        plans << { employee_number: person[:employee_number], records: records }
      end

      people.each_slice(BATCH) { |slice| Employee.insert_all!(slice) }
      ids = Employee.pluck(:employee_number, :id).to_h
      salaries = plans.flat_map do |plan|
        plan[:records].map { |record| record.merge(employee_id: ids.fetch(plan[:employee_number])) }
      end
      salaries.each_slice(BATCH) { |slice| SalaryRecord.insert_all!(slice) }
    end

    def country_sequence(countries)
      weighted = Catalog::COUNTRIES.map { |row| [ row[:code], row[:weight] ] }
      allocate(employee_count, weighted).flat_map { |code, count| [ countries.fetch(code) ] * count }.shuffle(random: random)
    end

    def build_person(index, country, departments)
      department_name = weighted_pick(Catalog::DEPARTMENTS)
      level = weighted_pick(Catalog::LEVELS)
      currency = country.currency_code
      amount = salary_for(country.code, level, department_name)
      tenure = random.rand(40..3650)
      hire_date = as_of - tenure
      status, terminated_on = employment_status(hire_date, tenure)
      records = [ salary_row(amount, currency, hire_date, "hire") ]
      current_amount = amount
      current_level = level

      if tenure > 420 && random.rand(100) < 45
        current_amount = round_major((current_amount * (100 + random.rand(4..12))) / 100, currency)
        records << salary_row(current_amount, currency, hire_date + 365, "merit")
      end

      promoted = promote(country.code, department_name, current_level, current_amount, currency, hire_date, tenure)
      if promoted
        current_level = promoted[:level]
        records << promoted[:record]
      end

      person = {
        employee_number: format("ACME-%06d", index + 1),
        first_name: Catalog::FIRST_NAMES[index % Catalog::FIRST_NAMES.length],
        last_name: Catalog::LAST_NAMES[(index / Catalog::FIRST_NAMES.length) % Catalog::LAST_NAMES.length],
        email: email_for(index),
        country_id: country.id,
        department_id: departments.fetch(department_name).id,
        job_title: "#{Catalog::LADDER.fetch(current_level)}, #{department_name}",
        job_level: current_level,
        status: status,
        hire_date: hire_date,
        terminated_on: terminated_on
      }
      [ person, records ]
    end

    def promote(country_code, department_name, level, amount, currency, hire_date, tenure)
      return nil unless tenure > 800 && random.rand(100) < 18

      next_level = next_in_track(level)
      return nil unless next_level

      floor = salary_for(country_code, next_level, department_name, pick: false)
      promoted_amount = [ floor, (amount * 115) / 100 ].max
      {
        level: next_level,
        record: salary_row(round_major(promoted_amount, currency), currency, hire_date + 700, "promotion")
      }
    end

    def employment_status(hire_date, tenure)
      roll = random.rand(100)
      return [ "active", nil ] if roll < 92
      return [ "on_leave", nil ] if roll < 96

      [ "terminated", hire_date + random.rand(1..(tenure - 1)) ]
    end

    def salary_for(country_code, level, department_name, pick: true)
      low, high = Catalog::BANDS.fetch(country_code).fetch(level)
      factor = Catalog::DEPARTMENT_FACTORS.fetch(department_name)
      min = (low * factor) / 100
      max = [ (high * factor) / 100, min + 1 ].max
      major = pick ? random.rand(min..max) : min
      round_major(major, currency_for(country_code))
    end

    def salary_row(major, currency, effective_on, reason)
      {
        amount_cents: major * (10**Currencies.exponent(currency)),
        currency_code: currency,
        effective_on: effective_on,
        reason: reason,
        note: nil
      }
    end

    def round_major(value, currency)
      step = currency == "JPY" ? 10_000 : 1_000
      rounded = (value / step) * step
      [ rounded, step ].max
    end

    def currency_for(country_code)
      Catalog::COUNTRIES.find { |row| row[:code] == country_code }.fetch(:currency)
    end

    def next_in_track(level)
      track = level.start_with?("M") ? %w[M1 M2 M3] : %w[IC1 IC2 IC3 IC4 IC5 IC6]
      index = track.index(level)
      return nil if index.nil? || index == track.length - 1

      track[index + 1]
    end

    def email_for(index)
      first = Catalog::FIRST_NAMES[index % Catalog::FIRST_NAMES.length]
      last = Catalog::LAST_NAMES[(index / Catalog::FIRST_NAMES.length) % Catalog::LAST_NAMES.length]
      "#{first}.#{last}.#{index}@acme.test".downcase
    end

    def weighted_pick(pairs)
      roll = random.rand(pairs.sum { |_, weight| weight })
      pairs.each do |value, weight|
        return value if roll < weight

        roll -= weight
      end
      pairs.last.first
    end

    def allocate(total, weighted)
      weight_total = weighted.sum { |_, weight| weight }
      portions = weighted.each_with_index.map { |(key, weight), index|
        exact = total * weight.to_f / weight_total
        { key: key, count: exact.floor, fraction: exact - exact.floor, index: index }
      }
      remainder = total - portions.sum { |row| row[:count] }
      portions.sort_by { |row| [ -row[:fraction], row[:index] ] }.first(remainder).each { |row| row[:count] += 1 }
      portions.map { |row| [ row[:key], row[:count] ] }
    end
  end
end
