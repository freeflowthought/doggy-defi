// @noErrors: 2307 2580 2339 - cannot find 'process', cannot find './wagmi', cannot find 'import.meta'
'use client';

import type { ReactNode } from 'react';
import { OnchainKitProvider } from '@coinbase/onchainkit';
import { baseSepolia } from 'viem/chains';// add baseSepolia for testing

export function Providers(props: { children: ReactNode }) {
  return (
    <OnchainKitProvider
//       apiKey={process.env.REACT_APP_PUBLIC_ONCHAINKIT_API_KEY}
          apiKey="w07zOyaQU7Yw5BuxIPknfJAg55wAASRH"
      chain={baseSepolia} // add baseSepolia for testing
    >
      {props.children}
    </OnchainKitProvider>
  );
}