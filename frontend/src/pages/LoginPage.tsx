import { Alert, Button, Center, Paper, PasswordInput, Stack, Text, TextInput, Title } from "@mantine/core";
import { FormEvent, useState } from "react";
import { Navigate } from "react-router-dom";
import { api } from "../api";
import type { Session } from "../types";

export function LoginPage({ signedIn, onSuccess }: { signedIn: boolean; onSuccess: (session: Session) => void }) {
  const [email, setEmail] = useState("hr@acme.test");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  if (signedIn) return <Navigate to="/" replace />;

  async function submit(event: FormEvent) {
    event.preventDefault();
    setBusy(true);
    setError(null);
    try {
      const session = await api<Session>("/api/v1/session", {
        method: "POST",
        body: JSON.stringify({ email, password }),
      });
      onSuccess(session);
    } catch (caught) {
      setError(caught instanceof Error ? caught.message : "Sign in failed");
    } finally {
      setBusy(false);
    }
  }

  return (
    <Center mih="100vh" p="md">
      <Paper withBorder shadow="sm" p="xl" w={420} component="form" onSubmit={submit}>
        <Stack>
          <div>
            <Text size="xs" tt="uppercase" c="spruce.7" fw={700}>Acme</Text>
            <Title order={2} className="wordmark">Compensation</Title>
            <Text c="dimmed" size="sm" mt={4}>Base salary for the HR manager. Not a payroll run.</Text>
          </div>
          {error && <Alert color="red">{error}</Alert>}
          <TextInput label="Email" value={email} onChange={(event) => setEmail(event.currentTarget.value)} required />
          <PasswordInput label="Password" value={password} onChange={(event) => setPassword(event.currentTarget.value)} required />
          <Button type="submit" loading={busy}>Sign in</Button>
          <Text size="xs" c="dimmed">Demo account: hr@acme.test / Acme-HR-2026</Text>
        </Stack>
      </Paper>
    </Center>
  );
}
