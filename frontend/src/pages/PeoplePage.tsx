import { Alert, Button, Group, Pagination, Select, Table, Text, TextInput, Title } from "@mantine/core";
import { useEffect, useState } from "react";
import { Link, useSearchParams } from "react-router-dom";
import { api, ApiError } from "../api";
import { useAuth } from "../auth";
import type { PeopleResponse } from "../types";

const STATUS_LABELS: Record<string, string> = {
  active: "Active",
  on_leave: "On leave",
  terminated: "Terminated",
  all: "All",
};

export function PeoplePage() {
  const { reference } = useAuth();
  const [params, setParams] = useSearchParams();
  const [data, setData] = useState<PeopleResponse | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [query, setQuery] = useState(params.get("q") || "");

  useEffect(() => {
    const handle = window.setTimeout(() => {
      setParams((current) => {
        if ((current.get("q") || "") === query) return current;
        const merged = new URLSearchParams(current);
        if (query) merged.set("q", query);
        else merged.delete("q");
        merged.delete("page");
        return merged;
      });
    }, 250);
    return () => window.clearTimeout(handle);
  }, [query, setParams]);

  useEffect(() => {
    setError(null);
    api<PeopleResponse>(`/api/v1/employees?${params.toString()}`)
      .then(setData)
      .catch((caught) => {
        setData(null);
        setError(caught instanceof ApiError ? caught.message : "Could not load people");
      });
  }, [params]);

  function update(next: Record<string, string | null>) {
    const merged = new URLSearchParams(params);
    Object.entries(next).forEach(([key, value]) => {
      if (!value) merged.delete(key);
      else merged.set(key, value);
    });
    setParams(merged);
  }

  const status = params.get("status") || "active";

  return (
    <div>
      <Group justify="space-between" mb="md">
        <div>
          <Title order={2}>People</Title>
          <Text c="dimmed" size="sm">{data ? `${data.meta.total.toLocaleString()} matching` : "Directory of base salary"}</Text>
        </div>
        <Group>
          <Button component="a" href="/api/v1/exports/compensation" variant="default">Export CSV</Button>
          <Button component={Link} to="/people/new">New hire</Button>
        </Group>
      </Group>

      <Group align="end" mb="md" grow>
        <TextInput label="Search" placeholder="Name, email, or employee number" value={query} onChange={(event) => setQuery(event.currentTarget.value)} />
        <Select
          label="Country"
          placeholder="All countries"
          clearable
          data={reference.countries.map((country) => ({ value: String(country.id), label: country.name }))}
          value={params.get("country_id")}
          onChange={(value) => update({ country_id: value, page: null })}
        />
        <Select
          label="Department"
          placeholder="All departments"
          clearable
          data={reference.departments.map((department) => ({ value: String(department.id), label: department.name }))}
          value={params.get("department_id")}
          onChange={(value) => update({ department_id: value, page: null })}
        />
        <Select
          label="Status"
          data={["active", "on_leave", "terminated", "all"].map((value) => ({ value, label: STATUS_LABELS[value] }))}
          value={status}
          onChange={(value) => update({ status: value === "active" ? null : value, page: null })}
        />
        <Select
          label="Sort"
          data={[
            { value: "name", label: "Name" },
            { value: "hire_date", label: "Hire date" },
            { value: "salary", label: "Salary" },
          ]}
          value={params.get("sort") || "name"}
          onChange={(value) => update({ sort: value === "name" ? null : value, page: null })}
        />
      </Group>
      {params.get("sort") === "salary" && !params.get("country_id") && (
        <Text size="sm" c="dimmed" mb="sm">Choose a country before sorting by salary. Amounts in different currencies are not ordered together.</Text>
      )}
      {error && <Alert color="red" mb="md">{error}</Alert>}
      {data && data.employees.length === 0 && !error && (
        <Text mt="md" c="dimmed">
          No one matches. This list is {STATUS_LABELS[status].toLowerCase()} people. Choose All to include other statuses.
        </Text>
      )}

      <Table striped highlightOnHover withTableBorder>
        <Table.Thead>
          <Table.Tr>
            <Table.Th>Employee</Table.Th>
            <Table.Th>Country</Table.Th>
            <Table.Th>Department</Table.Th>
            <Table.Th>Level</Table.Th>
            <Table.Th>Status</Table.Th>
            <Table.Th>Annual base</Table.Th>
          </Table.Tr>
        </Table.Thead>
        <Table.Tbody>
          {data?.employees.map((employee) => (
            <Table.Tr key={employee.id}>
              <Table.Td>
                <Link to={`/people/${employee.id}`}>{employee.full_name}</Link>
                <Text size="xs" c="dimmed">{employee.employee_number}</Text>
              </Table.Td>
              <Table.Td>{employee.country.name}</Table.Td>
              <Table.Td>{employee.department.name}</Table.Td>
              <Table.Td>{employee.job_level}</Table.Td>
              <Table.Td>{STATUS_LABELS[employee.status] || employee.status}</Table.Td>
              <Table.Td>{employee.current_salary?.formatted || "Not effective yet"}</Table.Td>
            </Table.Tr>
          ))}
        </Table.Tbody>
      </Table>
      {data && data.meta.total_pages > 1 && (
        <Pagination
          mt="md"
          total={data.meta.total_pages}
          value={data.meta.page}
          onChange={(page) => update({ page: page === 1 ? null : String(page) })}
        />
      )}
    </div>
  );
}
