import { CDPReactProvider } from "@coinbase/cdp-react";
import { StrictMode } from "react";
import { createRoot } from "react-dom/client";

import App from "./App.tsx";
import { APP_CONFIG, CDP_CONFIG } from "./config.ts";
import { theme } from "./theme.ts";
import "./index.css";
import '@coinbase/onchainkit/styles.css';
import { Providers } from './Providers'; 

createRoot(document.getElementById("root")!).render(
  <StrictMode>
    <CDPReactProvider config={CDP_CONFIG} app={APP_CONFIG} theme={theme}>
      <Providers> 
      <App />
      </Providers>
    </CDPReactProvider>
  </StrictMode>,
);
