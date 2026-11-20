import { createContext, useContext } from "react";
import type { Hr, Reference } from "./types";

export type AuthValue = {
  hr: Hr;
  reference: Reference;
  signOut: () => Promise<void>;
};

export const AuthContext = createContext<AuthValue | null>(null);

export function useAuth() {
  const value = useContext(AuthContext);
  if (!value) throw new Error("Missing auth");
  return value;
}
