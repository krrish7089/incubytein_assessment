import { Alert, Button, Group, Select, Stack, Text, TextInput, Title } from "@mantine/core";
import { FormEvent, useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { api } from "../api";
import { useAuth } from "../auth";
import type { Employee } from "../types";

export function HirePage() {
  const { reference } = useAuth();
  const navigate = useNavigate();
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);
  const [form, setForm] = useState({
    first_name: "",
    last_name: "",
    email: "",
    country_id: "",
    department_id: "",
    job_title: "",
    job_level: "IC3",
    hire_date: new Date().toISOString().slice(0, 10),
    salary_amount: "",
  });

  const country = reference.countries.find((item) => String(item.id) === form.country_id);

  function set<K extends keyof typeof form>(key: K, value: string) {
    setForm((current) => ({ ...current, [key]: value }));
  }

  async function submit(event: FormEvent) {
    event.preventDefault();
    setBusy(true);
    setError(null);
    try {
      const response = await api<{ employee: Employee }>("/api/v1/employees", {
        method: "POST",
        body: JSON.stringify({
          employee: {
            ...form,
            country_id: Number(form.country_id),
            department_id: Number(form.department_id),
          },
        }),
      });
      navigate(`/people/${response.employee.id}`);
    } catch (caught) {
      setError(caught instanceof Error ? caught.message : "Could not hire");
    } finally {
      setBusy(false);
    }
  }

  return (
    <Stack maw={640} component="form" onSubmit={submit}>
      <div>
        <Title order={2}>New hire</Title>
        <Text c="dimmed" size="sm">The employee number is assigned. Opening salary uses the country’s currency.</Text>
      </div>
      {error && <Alert color="red">{error}</Alert>}
      <Group grow>
        <TextInput label="First name" required value={form.first_name} onChange={(event) => set("first_name", event.currentTarget.value)} />
        <TextInput label="Last name" required value={form.last_name} onChange={(event) => set("last_name", event.currentTarget.value)} />
      </Group>
      <TextInput label="Email" required type="email" value={form.email} onChange={(event) => set("email", event.currentTarget.value)} />
      <Group grow>
        <Select label="Country" required data={reference.countries.map((item) => ({ value: String(item.id), label: item.name }))} value={form.country_id || null} onChange={(value) => set("country_id", value || "")} />
        <Select label="Department" required data={reference.departments.map((item) => ({ value: String(item.id), label: item.name }))} value={form.department_id || null} onChange={(value) => set("department_id", value || "")} />
      </Group>
      <Group grow>
        <TextInput label="Title" required value={form.job_title} onChange={(event) => set("job_title", event.currentTarget.value)} />
        <Select label="Level" required data={reference.job_levels} value={form.job_level} onChange={(value) => set("job_level", value || "IC3")} />
      </Group>
      <Group grow>
        <TextInput label="Hire date" required type="date" value={form.hire_date} onChange={(event) => set("hire_date", event.currentTarget.value)} />
        <TextInput
          label={country ? `Annual base (${country.currency_code})` : "Annual base"}
          required
          placeholder="145000.00"
          value={form.salary_amount}
          onChange={(event) => set("salary_amount", event.currentTarget.value)}
        />
      </Group>
      <Group>
        <Button type="submit" loading={busy}>Hire</Button>
        <Button component={Link} to="/people" variant="default">Cancel</Button>
      </Group>
    </Stack>
  );
}
