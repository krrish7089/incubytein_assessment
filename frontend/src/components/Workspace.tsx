import { AppShell, Button, Group, NavLink, Text } from "@mantine/core";
import { Link, useLocation } from "react-router-dom";
import type { ReactNode } from "react";
import { useAuth } from "../auth";

export function Workspace({ children }: { children: ReactNode }) {
  const { hr, signOut } = useAuth();
  const location = useLocation();

  return (
    <AppShell header={{ height: 68 }} navbar={{ width: 230, breakpoint: "sm" }} padding="lg">
      <AppShell.Header>
        <Group h="100%" px="lg" justify="space-between">
          <div>
            <div className="wordmark">Acme Compensation</div>
            <Text size="xs" c="dimmed">How the organization pays people</Text>
          </div>
          <Group gap="sm">
            <Text size="sm">{hr.name}</Text>
            <Button variant="subtle" color="spruce" onClick={() => void signOut()}>Sign out</Button>
          </Group>
        </Group>
      </AppShell.Header>
      <AppShell.Navbar p="md">
        <NavLink component={Link} to="/" label="Payroll picture" active={location.pathname === "/"} />
        <NavLink component={Link} to="/people" label="People" active={location.pathname.startsWith("/people")} />
      </AppShell.Navbar>
      <AppShell.Main>{children}</AppShell.Main>
    </AppShell>
  );
}
