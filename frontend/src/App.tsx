import { Center, Loader } from "@mantine/core";
import { useEffect, useState } from "react";
import { Navigate, Outlet, Route, Routes, useNavigate } from "react-router-dom";
import { api } from "./api";
import { AuthContext } from "./auth";
import { Workspace } from "./components/Workspace";
import { DashboardPage } from "./pages/DashboardPage";
import { HirePage } from "./pages/HirePage";
import { LoginPage } from "./pages/LoginPage";
import { PeoplePage } from "./pages/PeoplePage";
import { PersonPage } from "./pages/PersonPage";
import type { Hr, Reference, Session } from "./types";

export function App() {
  const [hr, setHr] = useState<Hr | null>(null);
  const [reference, setReference] = useState<Reference | null>(null);
  const [ready, setReady] = useState(false);

  async function loadSession() {
    const session = await api<Session>("/api/v1/session");
    setHr(session.hr);
    if (session.hr) setReference(await api<Reference>("/api/v1/reference"));
    else setReference(null);
  }

  useEffect(() => {
    loadSession().finally(() => setReady(true));
  }, []);

  if (!ready) {
    return <Center mih="100vh"><Loader color="spruce" /></Center>;
  }

  return (
    <Routes>
      <Route path="/login" element={<LoginPage signedIn={Boolean(hr)} onSuccess={(session) => {
        setHr(session.hr);
        void api<Reference>("/api/v1/reference").then(setReference);
      }} />} />
      <Route element={<RequireAuth hr={hr} reference={reference} onSignOut={async () => {
        await api("/api/v1/session", { method: "DELETE" });
        setHr(null);
        setReference(null);
        await loadSession();
      }} />}>
        <Route path="/" element={<DashboardPage />} />
        <Route path="/people" element={<PeoplePage />} />
        <Route path="/people/new" element={<HirePage />} />
        <Route path="/people/:id" element={<PersonPage />} />
      </Route>
    </Routes>
  );
}

function RequireAuth({
  hr,
  reference,
  onSignOut,
}: {
  hr: Hr | null;
  reference: Reference | null;
  onSignOut: () => Promise<void>;
}) {
  const navigate = useNavigate();
  if (!hr) return <Navigate to="/login" replace />;
  if (!reference) return <Center mih="100vh"><Loader color="spruce" /></Center>;

  return (
    <AuthContext.Provider value={{
      hr,
      reference,
      signOut: async () => {
        await onSignOut();
        navigate("/login");
      },
    }}>
      <Workspace>
        <Outlet />
      </Workspace>
    </AuthContext.Provider>
  );
}
