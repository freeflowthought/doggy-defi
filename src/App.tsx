import { useIsInitialized, useIsSignedIn } from "@coinbase/cdp-hooks";
import Loading from "./Loading";
import SignedInScreen from "./SignedInScreen";
import SignInScreen from "./SignInScreen";

import { Swap } from '@coinbase/onchainkit/swap'; 
import type { Token } from '@coinbase/onchainkit/token';

const eth: Token = {
  name: 'ETH',
  address: '',
  symbol: 'ETH',
  decimals: 18,
  image:
    'https://wallet-api-production.s3.amazonaws.com/uploads/tokens/eth_288.png',
  chainId: 8453,
};

const usdc: Token = {
  name: 'USDC',
  address: '0x833589fcd6edb6e08f4c7c32d4f71b54bda02913',
  symbol: 'USDC',
  decimals: 6,
  image:
    'https://d3r81g40ycuhqg.cloudfront.net/wallet/wais/44/2b/442b80bd16af0c0d9b22e03a16753823fe826e5bfd457292b55fa0ba8c1ba213-ZWUzYjJmZGUtMDYxNy00NDcyLTg0NjQtMWI4OGEwYjBiODE2',
  chainId: 8453,
};

/**
 * This component how to use the useIsIntialized, useEvmAddress, and useIsSignedIn hooks.
 * It also demonstrates how to use the AuthButton component to sign in and out of the app.
 */
function App() {
  const { isInitialized } = useIsInitialized();
  const { isSignedIn } = useIsSignedIn();

  return (
    <div className="app flex-col-container flex-grow">
      {!isInitialized && <Loading />}
      {isInitialized && (
        <>
          {!isSignedIn && <SignInScreen />}
          {isSignedIn && (
            <> 
              <SignedInScreen />
              <Swap from={[eth]} to={[usdc]}/>
            </>
          )}
        </>
      )}
    </div>
  );
}
export default App;