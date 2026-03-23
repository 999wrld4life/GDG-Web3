# Shared Wallet (Foundry)

A simple shared wallet smart contract built with Foundry.

This project demonstrates:
- ETH deposits from multiple users
- Owner-only withdrawals
- Deposit history tracking with timestamps
- Basic unit tests using `forge-std/Test.sol`

## Contract Overview

Main contract: `src/SharedWallet.sol`

### State
- `owner`: wallet owner set at deployment
- `totalBalance`: tracked total ETH balance managed by the contract
- `balances[address]`: total ETH deposited by each user
- `deposits[]`: array of deposit records

### Struct
- `Deposit`
	- `user`: depositor address
	- `amount`: ETH amount deposited
	- `time`: block timestamp of deposit

### Functions
- `deposit() external payable`
	- Requires `msg.value > 0`
	- Updates user balance and `totalBalance`
	- Appends a deposit record

- `withdraw(uint256 amount) external`
	- Only callable by `owner`
	- Requires enough contract balance
	- Transfers ETH via low-level `call`
	- Decreases `totalBalance`

## Tests

Test file: `test/SharedWallet.t.sol`

Covered scenarios:
- `testDeposit()`
	- Multiple users deposit ETH
	- Verifies per-user balances and `totalBalance`

- `testWithdraw()`
	- Owner deposits and withdraws ETH
	- Verifies contract balance and `totalBalance` after withdrawal

## Project Structure

```text
src/
	SharedWallet.sol
test/
	SharedWallet.t.sol
```

## Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)

## How To Run

From the project root (`Shared-wallet/Shared-wallet`):

```bash
forge clean
forge build
forge test
```

## Notes

- This is a learning/demo contract and not production-hardened.
- `balances` tracks deposited amounts per user, not ownership shares after withdrawals.
- Currently, only the owner can withdraw funds.
