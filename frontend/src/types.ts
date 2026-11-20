export type Hr = { id: number; name: string; email: string };

export type Session = { hr: Hr | null; csrf_token: string };

export type Country = { id: number; code: string; name: string; currency_code: string };
export type Department = { id: number; name: string };

export type Reference = {
  countries: Country[];
  departments: Department[];
  job_levels: string[];
  statuses: string[];
  salary_reasons: { value: string; label: string }[];
};

export type Salary = {
  id: number;
  amount_cents: number;
  currency_code: string;
  formatted: string;
  major: string;
  effective_on: string;
  reason: string;
  reason_label: string;
  note: string | null;
};

export type Employee = {
  id: number;
  employee_number: string;
  first_name: string;
  last_name: string;
  full_name: string;
  email: string;
  country: Country;
  department: Department;
  job_title: string;
  job_level: string;
  status: string;
  hire_date: string;
  terminated_on: string | null;
  current_salary: Salary | null;
  upcoming_salary?: Salary | null;
  salary_history?: Salary[];
};

export type PeopleResponse = {
  employees: Employee[];
  meta: { page: number; per_page: number; total: number; total_pages: number };
};

export type MoneyRow = {
  currency_code: string;
  headcount: number;
  total_cents: number;
  average_cents: number;
  median_cents: number;
  formatted_total: string;
  formatted_average: string;
  formatted_median: string;
};

export type Dashboard = {
  as_of: string;
  headcount: { active: number; on_leave: number; terminated: number };
  payroll_headcount: number;
  payroll_by_currency: MoneyRow[];
  by_country: (MoneyRow & { country_name: string; country_code: string })[];
  by_department: (MoneyRow & { department_name: string })[];
  bands: { currency_code: string; bands: { label: string; count: number }[] }[];
  recent_changes: (Salary & { employee_id: number; employee_name: string; employee_number: string })[];
  indicative_usd: {
    total_cents: number;
    formatted: string;
    as_of: string | null;
    source: string | null;
    missing_currencies: string[];
    disclaimer: string;
  };
};
