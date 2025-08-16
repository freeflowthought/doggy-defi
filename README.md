# BeaconPay

A smart contract system for handling USDC payments with event verification using transient storage, designed for EIP-7702 batched transactions. BeaconPay introduces a sponsored transactions feature, allowing dApps and merchants to cover gas fees for their users.

## Overview

This project consists of:

- **Eventor**: A contract that validates and emits payment events using transient storage.
- **Paymaster**: A contract that enables sponsored transactions, allowing a third party to pay for gas fees.
- **EventorHarness**: A test version of Eventor without EOA restrictions.
- **Test Suite**: Comprehensive tests with mainnet forking.

## Features

- ✅ **Sponsored Transactions**: dApps and merchants can cover gas fees for their users, enabling a seamless payment experience.
- ✅ **EIP-7702 Compatible**: Designed for EIP-7702 use cases with batched transactions.
- ✅ **Transient Storage**: Uses Solidity's transient storage for gas-efficient state management.
- ✅ **Multi-Chain Support**: Deployable on Ethereum, Zircuit, and Flow networks.
- ✅ **Payment Validation**: Validates USDC transfers with a commit-reveal pattern.
- ✅ **Event Emission**: Emits confirmed payment events after validation.
- ✅ **EOA Only**: Restricted to externally owned accounts for security.

## BeaconPay: Sponsored Transactions

BeaconPay's core feature is the ability to sponsor transactions, abstracting away gas fees from the end-user. This is achieved through a combination of EIP-7702 and the `Paymaster` contract.

### How it Works

1.  **User Signs a Transaction (Off-Chain)**: The user signs an EIP-7702 transaction to call the `reveal` function on the `Eventor` contract. The `authorized` field of the transaction is set to the `Paymaster` contract's address.
2.  **dApp/Merchant Submits the Transaction (On-Chain)**: The dApp or merchant receives the signed transaction and submits it to the network, paying the gas fee from their own wallet.
3.  **Execution and Verification**: The Ethereum network executes the transaction. The `Paymaster` contract calls the `sponsoredReveal` function on the `Eventor` contract, which verifies the payment and emits the `ConfirmedPayment` event.

This process allows users to interact with your dApp and make payments without needing to hold ETH for gas.

## Contracts

### Eventor

The main contract that handles payment validation and event emission using a commit-reveal pattern.

**Key Features:**
- Uses transient storage for temporary state between calls.
- Validates USDC payment amounts and recipients.
- Emits `ConfirmedPayment` events after successful validation.
- Implements a commit-reveal pattern for payment validation.

### Paymaster

The `Paymaster` contract is responsible for executing sponsored transactions. It has a `sponsoredReveal` function that can only be called by the registered paymaster address in the `Eventor` contract.

## Supported Networks

| Network | USDC Address |
|---------|-------------|
| Ethereum | `0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48` |
| Zircuit | `0x3b952c8C9C44e8Fe201e2b26F6B2200203214cfF` |
| Flow | `0x7f27352D5F83Db87a5A3E00f4B07Cc2138D8ee52` |

## Installation

```bash
# Clone the repository
git clone <repository-url>
cd beacon-pay

# Install dependencies
forge install
```

## Usage

### Build

```bash
forge build
```

### Test

```bash
# Run all tests
forge test

# Run tests for the sponsored transactions feature
forge test --match-contract EventorPaymasterTest

# Run tests with mainnet fork
forge test --fork-url https://ethereum-rpc.publicnode.com
```

### Deploy

Set your environment variables:
```bash
export PRIVATE_KEY=your_private_key
export ETHERSCAN_KEY=your_etherscan_api_key
```

Deploy the `Eventor` and `Paymaster` contracts, and then set the paymaster address in the `Eventor` contract.

## Development

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)

### Project Structure

```
├── src/
│   ├── Eventor.sol          # Main payment validation contract
│   ├── Paymaster.sol        # Contract for sponsoring transactions
│   ├── EventorHarness.sol   # Test version without EOA restriction
│   └── IEventor.sol         # Interface definition
├── test/
│   └── Eventor.t.sol        # Test suite
├── script/
│   ├── DeployEventor.s.sol  # Deployment script
│   └── README.md            # Deployment instructions
└── lib/                     # Dependencies
```

## Security Considerations

- The `Eventor` contract only accepts `commit` and `reveal` calls from EOAs (`tx.origin == msg.sender`).
- The `sponsoredReveal` function can only be called by the registered `paymaster` address.
- Uses transient storage to prevent cross-transaction state pollution.
- Validates payment amounts and recipients before event emission.

## License

MIT