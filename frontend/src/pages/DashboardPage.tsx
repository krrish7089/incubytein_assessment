import { Alert, Grid, Group, Paper, Select, Stack, Table, Text, Title } from "@mantine/core";
import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { api, ApiError } from "../api";
import type { Dashboard } from "../types";

export function DashboardPage() {
  const [data, setData] = useState<Dashboard | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [currency, setCurrency] = useState<string | null>(null);

  useEffect(() => {
    api<Dashboard>("/api/v1/dashboard")
      .then((dashboard) => {
        setData(dashboard);
        const preferred = dashboard.payroll_by_currency.find((row) => row.currency_code === "USD");
        setCurrency(preferred?.currency_code || dashboard.payroll_by_currency[0]?.currency_code || null);
      })
      .catch((caught) => setError(caught instanceof ApiError ? caught.message : "Could not load the payroll picture"));
  }, []);

  if (error) return <Alert color="red">{error}</Alert>;
  if (!data) return <Text c="dimmed">Loading the payroll picture…</Text>;

  const bands = data.bands.find((row) => row.currency_code === currency);
  const maxBand = Math.max(1, ...(bands?.bands.map((band) => band.count) || [1]));
  const departments = data.by_department.filter((row) => !currency || row.currency_code === currency);

  return (
    <Stack gap="lg">
      <div>
        <Title order={2}>Payroll picture</Title>
        <Text c="dimmed">Annual base salary as of {data.as_of}. On leave is included. Terminated people are not.</Text>
      </div>

      <Grid>
        <Stat label="On payroll" value={data.payroll_headcount.toLocaleString()} note="Active and on leave, with a salary effective today" />
        <Stat label="Active" value={data.headcount.active.toLocaleString()} note="Includes future hires who are not on payroll yet" />
        <Stat label="On leave" value={data.headcount.on_leave.toLocaleString()} note="Still paid" />
        <Stat label="Terminated" value={data.headcount.terminated.toLocaleString()} note="History kept, excluded from totals" />
      </Grid>

      <Alert color="spruce" variant="light" title={`Indicative total ${data.indicative_usd.formatted}`}>
        {data.indicative_usd.disclaimer}
        {data.indicative_usd.as_of && ` Rates dated ${data.indicative_usd.as_of}.`}
        {data.indicative_usd.missing_currencies.length > 0 && ` Missing rates: ${data.indicative_usd.missing_currencies.join(", ")}.`}
      </Alert>

      <Paper withBorder p="md">
        <Title order={4} mb="sm">By currency</Title>
        <MoneyTable rows={data.payroll_by_currency} nameLabel="Currency" name={(row) => row.currency_code} />
      </Paper>

      <Grid>
        <Grid.Col span={{ base: 12, md: 7 }}>
          <Paper withBorder p="md" h="100%">
            <Title order={4} mb="sm">By country</Title>
            <MoneyTable rows={data.by_country} nameLabel="Country" name={(row) => `${row.country_name} · ${row.currency_code}`} />
          </Paper>
        </Grid.Col>
        <Grid.Col span={{ base: 12, md: 5 }}>
          <Paper withBorder p="md" h="100%">
            <Group justify="space-between" mb="sm">
              <Title order={4}>Bands</Title>
              <Select
                aria-label="Band currency"
                data={data.bands.map((row) => row.currency_code)}
                value={currency}
                onChange={setCurrency}
                w={110}
              />
            </Group>
            {bands?.bands.map((band) => (
              <div className="band" key={band.label}>
                <Text size="sm">{band.label}</Text>
                <div className="band-track"><span style={{ width: `${(band.count / maxBand) * 100}%` }} /></div>
                <Text size="sm" ta="right">{band.count}</Text>
              </div>
            ))}
          </Paper>
        </Grid.Col>
      </Grid>

      <Paper withBorder p="md">
        <Title order={4} mb="sm">By department{currency ? ` · ${currency}` : ""}</Title>
        <MoneyTable rows={departments} nameLabel="Department" name={(row) => row.department_name} />
      </Paper>

      <Paper withBorder p="md">
        <Title order={4} mb="sm">Recent changes</Title>
        <Text c="dimmed" size="sm" mb="sm">Hires are not listed here. Open a person to see the full history.</Text>
        {data.recent_changes.length === 0 && <Text size="sm">No changes before today, other than hire.</Text>}
        <Stack gap="xs">
          {data.recent_changes.map((change) => (
            <Group key={change.id} justify="space-between">
              <Text size="sm">
                <Link to={`/people/${change.employee_id}`}>{change.employee_name}</Link>
                {" · "}{change.reason_label} · {change.effective_on}
              </Text>
              <Text size="sm" fw={600}>{change.formatted}</Text>
            </Group>
          ))}
        </Stack>
      </Paper>
    </Stack>
  );
}

function Stat({ label, value, note }: { label: string; value: string; note: string }) {
  return (
    <Grid.Col span={{ base: 6, md: 3 }}>
      <Paper withBorder p="md" h="100%">
        <Text size="xs" tt="uppercase" c="dimmed" fw={700}>{label}</Text>
        <div className="stat-value">{value}</div>
        <Text size="xs" c="dimmed" mt={6}>{note}</Text>
      </Paper>
    </Grid.Col>
  );
}

function MoneyTable<T extends { headcount: number; formatted_total: string; formatted_average: string; formatted_median: string }>({
  rows,
  nameLabel,
  name,
}: {
  rows: T[];
  nameLabel: string;
  name: (row: T) => string;
}) {
  return (
    <Table striped highlightOnHover>
      <Table.Thead>
        <Table.Tr>
          <Table.Th>{nameLabel}</Table.Th>
          <Table.Th>People</Table.Th>
          <Table.Th>Total</Table.Th>
          <Table.Th>Average</Table.Th>
          <Table.Th>Median</Table.Th>
        </Table.Tr>
      </Table.Thead>
      <Table.Tbody>
        {rows.map((row) => (
          <Table.Tr key={name(row)}>
            <Table.Td>{name(row)}</Table.Td>
            <Table.Td>{row.headcount.toLocaleString()}</Table.Td>
            <Table.Td>{row.formatted_total}</Table.Td>
            <Table.Td>{row.formatted_average}</Table.Td>
            <Table.Td>{row.formatted_median}</Table.Td>
          </Table.Tr>
        ))}
      </Table.Tbody>
    </Table>
  );
}
