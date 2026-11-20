import { Alert, Button, Group, Select, Stack, Table, Text, Textarea, TextInput, Title } from "@mantine/core";
import { FormEvent, useEffect, useState } from "react";
import { Link, useParams } from "react-router-dom";
import { api, ApiError } from "../api";
import { useAuth } from "../auth";
import type { Employee } from "../types";

export function PersonPage() {
  const { id } = useParams();
  const { reference } = useAuth();
  const [employee, setEmployee] = useState<Employee | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [notice, setNotice] = useState<string | null>(null);

  async function load() {
    const response = await api<{ employee: Employee }>(`/api/v1/employees/${id}`);
    setEmployee(response.employee);
  }

  useEffect(() => {
    load().catch((caught) => setError(caught instanceof ApiError ? caught.message : "Could not load this person"));
  }, [id]);

  if (error && !employee) return <Alert color="red">{error}</Alert>;
  if (!employee) return <Text c="dimmed">Loading…</Text>;

  return (
    <Stack gap="lg">
      <div>
        <Text size="sm"><Link to="/people">People</Link></Text>
        <Group justify="space-between" align="end">
          <div>
            <Title order={2}>{employee.full_name}</Title>
            <Text c="dimmed">{employee.employee_number} · {employee.job_title} · {employee.country.name}</Text>
          </div>
          <div style={{ textAlign: "right" }}>
            <Text size="xs" tt="uppercase" c="dimmed" fw={700}>Current annual base</Text>
            <div className="stat-value">{employee.current_salary?.formatted || "Not effective yet"}</div>
          </div>
        </Group>
      </div>
      {notice && <Alert color="spruce">{notice}</Alert>}
      {error && <Alert color="red">{error}</Alert>}
      {employee.upcoming_salary && (
        <Alert color="yellow" title="Scheduled change">
          {employee.upcoming_salary.formatted} from {employee.upcoming_salary.effective_on} ({employee.upcoming_salary.reason_label}). It is not in today’s payroll.
        </Alert>
      )}

      <ProfileForm
        employee={employee}
        onSaved={async (message) => {
          setNotice(message);
          setError(null);
          await load();
        }}
        onError={setError}
      />
      <ChangeForm
        employee={employee}
        reasons={reference.salary_reasons}
        levels={reference.job_levels}
        onSaved={async (message) => {
          setNotice(message);
          setError(null);
          await load();
        }}
        onError={setError}
      />

      <div>
        <Title order={4} mb="sm">History</Title>
        <Table withTableBorder>
          <Table.Thead>
            <Table.Tr>
              <Table.Th>Effective</Table.Th>
              <Table.Th>Reason</Table.Th>
              <Table.Th>Amount</Table.Th>
              <Table.Th>Note</Table.Th>
            </Table.Tr>
          </Table.Thead>
          <Table.Tbody>
            {employee.salary_history?.map((salary) => (
              <Table.Tr key={salary.id}>
                <Table.Td>{salary.effective_on}</Table.Td>
                <Table.Td>{salary.reason_label}</Table.Td>
                <Table.Td>{salary.formatted}</Table.Td>
                <Table.Td>{salary.note}</Table.Td>
              </Table.Tr>
            ))}
          </Table.Tbody>
        </Table>
      </div>
    </Stack>
  );
}

function ProfileForm({
  employee,
  onSaved,
  onError,
}: {
  employee: Employee;
  onSaved: (message: string) => Promise<void>;
  onError: (message: string) => void;
}) {
  const { reference } = useAuth();
  const [form, setForm] = useState({
    first_name: employee.first_name,
    last_name: employee.last_name,
    email: employee.email,
    department_id: String(employee.department.id),
    job_title: employee.job_title,
    job_level: employee.job_level,
    status: employee.status,
    terminated_on: employee.terminated_on || "",
  });
  const [busy, setBusy] = useState(false);

  useEffect(() => {
    setForm({
      first_name: employee.first_name,
      last_name: employee.last_name,
      email: employee.email,
      department_id: String(employee.department.id),
      job_title: employee.job_title,
      job_level: employee.job_level,
      status: employee.status,
      terminated_on: employee.terminated_on || "",
    });
  }, [employee]);

  async function submit(event: FormEvent) {
    event.preventDefault();
    setBusy(true);
    try {
      await api(`/api/v1/employees/${employee.id}`, {
        method: "PATCH",
        body: JSON.stringify({
          employee: {
            ...form,
            department_id: Number(form.department_id),
            terminated_on: form.status === "terminated" ? form.terminated_on : null,
          },
        }),
      });
      await onSaved("Profile updated.");
    } catch (caught) {
      onError(caught instanceof Error ? caught.message : "Could not update the profile");
    } finally {
      setBusy(false);
    }
  }

  return (
    <Stack component="form" onSubmit={submit}>
      <Title order={4}>Profile</Title>
      <Text size="sm" c="dimmed">Country stays {employee.country.name}. A transfer would change the pay currency, and that rule is not in this product.</Text>
      <Group grow>
        <TextInput label="First name" value={form.first_name} onChange={(event) => setForm({ ...form, first_name: event.currentTarget.value })} />
        <TextInput label="Last name" value={form.last_name} onChange={(event) => setForm({ ...form, last_name: event.currentTarget.value })} />
      </Group>
      <TextInput label="Email" value={form.email} onChange={(event) => setForm({ ...form, email: event.currentTarget.value })} />
      <Group grow>
        <Select label="Department" data={reference.departments.map((item) => ({ value: String(item.id), label: item.name }))} value={form.department_id} onChange={(value) => setForm({ ...form, department_id: value || form.department_id })} />
        <Select label="Level" data={reference.job_levels} value={form.job_level} onChange={(value) => setForm({ ...form, job_level: value || form.job_level })} />
      </Group>
      <TextInput label="Title" value={form.job_title} onChange={(event) => setForm({ ...form, job_title: event.currentTarget.value })} />
      <Group grow>
        <Select
          label="Status"
          data={[
            { value: "active", label: "Active" },
            { value: "on_leave", label: "On leave" },
            { value: "terminated", label: "Terminated" },
          ]}
          value={form.status}
          onChange={(value) => setForm({ ...form, status: value || "active" })}
        />
        {form.status === "terminated" && (
          <TextInput label="Terminated on" type="date" required value={form.terminated_on} onChange={(event) => setForm({ ...form, terminated_on: event.currentTarget.value })} />
        )}
      </Group>
      <Button type="submit" w="fit-content" loading={busy} variant="default">Save profile</Button>
    </Stack>
  );
}

function ChangeForm({
  employee,
  reasons,
  levels,
  onSaved,
  onError,
}: {
  employee: Employee;
  reasons: { value: string; label: string }[];
  levels: string[];
  onSaved: (message: string) => Promise<void>;
  onError: (message: string) => void;
}) {
  const [form, setForm] = useState({
    salary_amount: "",
    effective_on: new Date().toISOString().slice(0, 10),
    reason: "merit",
    note: "",
    job_level: employee.job_level,
    job_title: employee.job_title,
  });
  const [busy, setBusy] = useState(false);

  async function submit(event: FormEvent) {
    event.preventDefault();
    setBusy(true);
    try {
      await api(`/api/v1/employees/${employee.id}/salary_records`, {
        method: "POST",
        body: JSON.stringify({ salary_record: form }),
      });
      setForm({ ...form, salary_amount: "", note: "" });
      await onSaved("Salary change recorded.");
    } catch (caught) {
      onError(caught instanceof Error ? caught.message : "Could not record the change");
    } finally {
      setBusy(false);
    }
  }

  return (
    <Stack component="form" onSubmit={submit}>
      <Title order={4}>Record a salary change</Title>
      <Text size="sm" c="dimmed">Amount is annual base in {employee.country.currency_code}. This adds a row. It does not overwrite history.</Text>
      <Group grow>
        <TextInput label="Annual base" required placeholder="160000" value={form.salary_amount} onChange={(event) => setForm({ ...form, salary_amount: event.currentTarget.value })} />
        <TextInput label="Effective on" required type="date" value={form.effective_on} onChange={(event) => setForm({ ...form, effective_on: event.currentTarget.value })} />
        <Select label="Reason" data={reasons.map((reason) => ({ value: reason.value, label: reason.label }))} value={form.reason} onChange={(value) => setForm({ ...form, reason: value || "merit" })} />
      </Group>
      {form.reason === "promotion" && (
        <Group grow>
          <Select label="New level" data={levels} value={form.job_level} onChange={(value) => setForm({ ...form, job_level: value || form.job_level })} />
          <TextInput label="New title" value={form.job_title} onChange={(event) => setForm({ ...form, job_title: event.currentTarget.value })} />
        </Group>
      )}
      <Textarea label="Note" value={form.note} onChange={(event) => setForm({ ...form, note: event.currentTarget.value })} />
      <Button type="submit" w="fit-content" loading={busy}>Record change</Button>
    </Stack>
  );
}
