class CreateCompensationSchema < ActiveRecord::Migration[7.2]
  def change
    create_table :countries do |t|
      t.string :code, null: false
      t.string :name, null: false
      t.string :currency_code, null: false

      t.timestamps
    end
    add_index :countries, :code, unique: true

    create_table :departments do |t|
      t.string :name, null: false

      t.timestamps
    end
    add_index :departments, :name, unique: true

    create_table :employees do |t|
      t.string :employee_number, null: false
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :email, null: false
      t.references :country, null: false, foreign_key: true
      t.references :department, null: false, foreign_key: true
      t.string :job_title, null: false
      t.string :job_level, null: false
      t.string :status, null: false, default: "active"
      t.date :hire_date, null: false
      t.date :terminated_on

      t.timestamps
    end
    add_index :employees, :employee_number, unique: true
    add_index :employees, :email, unique: true
    add_index :employees, :status
    add_index :employees, [ :last_name, :first_name ]

    create_table :salary_records do |t|
      t.references :employee, null: false, foreign_key: true, index: false
      t.integer :amount_cents, null: false, limit: 8
      t.string :currency_code, null: false
      t.date :effective_on, null: false
      t.string :reason, null: false
      t.text :note

      t.timestamps
    end
    add_index :salary_records, [ :employee_id, :effective_on ], unique: true
    add_index :salary_records, :effective_on

    create_table :exchange_rates do |t|
      t.string :currency_code, null: false
      t.decimal :units_per_usd, precision: 16, scale: 6, null: false
      t.date :as_of, null: false
      t.string :source, null: false

      t.timestamps
    end
    add_index :exchange_rates, :currency_code, unique: true

    create_table :hr_accounts do |t|
      t.string :name, null: false
      t.string :email, null: false
      t.string :password_digest, null: false

      t.timestamps
    end
    add_index :hr_accounts, :email, unique: true

    add_check_constraint :employees, "status IN ('active', 'on_leave', 'terminated')", name: "employees_status_known"
    add_check_constraint :employees,
      "(status = 'terminated' AND terminated_on IS NOT NULL) OR (status <> 'terminated' AND terminated_on IS NULL)",
      name: "employees_termination_matches_status"
    add_check_constraint :employees,
      "job_level IN ('IC1', 'IC2', 'IC3', 'IC4', 'IC5', 'IC6', 'M1', 'M2', 'M3')",
      name: "employees_job_level_known"
    add_check_constraint :salary_records, "amount_cents > 0", name: "salary_records_amount_positive"
    add_check_constraint :salary_records,
      "reason IN ('hire', 'merit', 'promotion', 'market_adjustment', 'correction')",
      name: "salary_records_reason_known"
  end
end
