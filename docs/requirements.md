# Acme Compensation — requirements

## Goal

Give Acme’s HR manager one place to keep base-salary data for about 10,000 employees, and to answer a practical question: how does this organization pay people? Today that answer lives in spreadsheets. The product replaces the spreadsheet for looking people up, recording a pay change, and reading the shape of pay. It does not calculate a paycheck.

## Who it is for

One persona: the HR manager. They already know the workforce. They need trustworthy totals, a person they can open in a few seconds, and a history of why pay changed. They do not need employee self-service, and they should not have to export to Excel to answer a country or department question.

## Scope

The product manages **annual base salary** only, stored as an effective-dated history.

- Sign in as the HR manager. Salary data is not anonymous.
- Search and filter people by name, email, employee number, country, department, and employment status.
- Hire someone with an opening salary. The employee number is assigned by the system.
- Record a later change: merit, promotion, market adjustment, or correction. A promotion can update level and title in the same action.
- See the current salary and the full history on the person. A future-dated change is visible, and it does not become “current” until its effective date.
- Update profile details HR actually edits: name, email, title, level, department, and status. Country stays fixed after hire, because pay currency is the country’s currency.
- Mark someone on leave or terminated. **On leave stays on payroll. Terminated does not.** History is kept either way. There is no delete.
- Dashboard, as of today:
  - headcount by status, and a separate count of people actually on payroll
  - total, average, and median annual base **by currency**
  - the same figures by country and by department
  - a simple band distribution per currency
  - recent changes that are not the original hire
  - one indicative USD total, clearly labeled as not payroll
- Export the current payroll view to CSV so HR can still use a spreadsheet when they must. Amounts in the file are plain numbers, not formatted text.

A seeded workforce of 10,000 people across ten countries makes the screens honest. Bands differ by country. Salaries are not one random range copied into every currency.

## Currency rule

Amounts are integers in minor units (cents, paise, yen). A salary record uses the currency of the employee’s country. The dashboard never adds rupees to dollars. The indicative USD figure uses a static rate table dated in the product, and the screen says it is not used to pay anyone.

“Current salary” means the latest record whose effective date is on or before today. That definition is shared by the directory, the person page, the dashboard, and the export.

## Deliberately out of scope

- **Payroll runs, tax, deductions, benefits, bonus, and equity.** Those are a different product with a different owner. Mixing them in would make “total pay” look precise when it is not. Base salary is the question HR asked.
- **Live foreign exchange and a single global payroll number.** A converted total is useful as a comparison and dangerous as a figure of record. Static indicative USD is the compromise. Payroll stays in native currency.
- **Pay-equity demographics** (gender, ethnicity, age). The brief does not ask for them, and they need a legal basis, tighter access control, and careful statistics. A casual gap chart would be worse than leaving them out.
- **Approval workflows, employee self-service, and SSO.** One HR manager is the user. A single account is enough to keep salaries off an open URL without pretending to be an identity platform.
- **Country transfers and expat pay in a foreign currency.** Currency follows the country. A transfer needs an explicit policy (which date, which currency, what happens to history). That policy is not in the brief, so country is set at hire.
- **Spreadsheet import.** Export is in, because it is the safety valve. Import needs an agreed column map and a dry run with HR. Guessing the map would load bad pay into the system of record.
- **Editing history in place.** Corrections are a new effective-dated record, so the previous figure remains visible.

## Done when

An HR manager can sign in, read the pay picture for the seeded organization, find a person, record a change, and download the current payroll. Tests cover money, effective dating, who is on payroll, and the API those screens use.
