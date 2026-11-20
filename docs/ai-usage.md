# How AI was used

The assessment brief was the instruction: an HR manager, 10,000 employees, spreadsheets, and the question of how the organization pays people. An agent in Cursor wrote the implementation on Ruby 3.2.2 and the Rails 7.2 app that was already in the repository.

The agent was not asked to “build an HR platform.” The written scope in `docs/requirements.md` was the constraint: base salary, effective dates, native currency, one HR login. Payroll, tax, live FX, demographics, and import were called out as exclusions before the models were added, so a generic CRUD expansion would have been a miss, not a feature.

AI was useful for the volume of straightforward code: the seed’s country bands, the React screens, and the repetitive request coverage. It is a poor sole judge of pay rules. Those were checked by tests that fail if currencies are summed, if a future raise counts as current, if a terminated person stays on payroll, or if a yen amount accepts a decimal. RuboCop and Brakeman ran over the result. The UI was exercised in a browser against the seeded app, not only reviewed as source.

Commits are ordered so the scope exists before the schema, and the schema before the API and the interface. That history is the point of the brief: the solution should be readable as a sequence of decisions, not as one generated drop.
