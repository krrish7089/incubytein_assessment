import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import { MantineProvider, createTheme } from "@mantine/core";
import { BrowserRouter } from "react-router-dom";
import { App } from "./App";
import "@mantine/core/styles.css";
import "./styles.css";

const theme = createTheme({
  primaryColor: "spruce",
  primaryShade: 7,
  fontFamily: "Figtree, 'Segoe UI', sans-serif",
  headings: { fontFamily: "Fraunces, Georgia, serif" },
  defaultRadius: "md",
  colors: {
    spruce: [
      "#f1f6f3",
      "#dce8e1",
      "#bdd4c8",
      "#96bba8",
      "#6f9e86",
      "#4f846b",
      "#356b52",
      "#1f4d3a",
      "#173c2d",
      "#0e261c",
    ],
  },
});

createRoot(document.getElementById("root")!).render(
  <StrictMode>
    <MantineProvider theme={theme}>
      <BrowserRouter>
        <App />
      </BrowserRouter>
    </MantineProvider>
  </StrictMode>,
);
