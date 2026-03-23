# SimpleAuction (Foundry)

A beginner-friendly Solidity auction project built with Foundry.

This contract allows users to create auctions, place higher bids, withdraw outbid funds, and finalize auctions.

## Project Structure

- `src/SimpleAuction.sol`: Main auction smart contract.
- `test/SimpleAuction.t.sol`: Unit tests for create/bid flows.
- `foundry.toml`: Foundry configuration.

## Contract Overview

The contract supports multiple auctions using incremental IDs.

### State

- `auctionCount`: Total number of auctions created.
- `auctions`: Mapping from auction ID to auction data.
- `pendingReturns`: Funds available for outbid users to withdraw.

### Main Functions

- `createAuction(uint256 duration)`
	- Creates a new auction.
	- Seller is `msg.sender`.
	- End time is `block.timestamp + duration`.

- `bid(uint256 auctionId)` `payable`
	- Places a bid on an active auction.
	- Requires the auction to still be running.
	- Requires new bid to be higher than current highest bid.
	- Previous highest bid is credited to `pendingReturns`.

- `withdraw()`
	- Lets outbid users pull their refundable balance.
	- Reverts if there is nothing to withdraw.

- `endAuction(uint256 auctionId)`
	- Ends an auction after the deadline.
	- Marks auction as ended.
	- Transfers winning bid to the seller.

## Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)

Check installation:

```bash
forge --version
```

## Getting Started

1. Install dependencies:

```bash
forge install
```

2. Build contracts:

```bash
forge build
```

3. Run tests:

```bash
forge test
```

## Current Test Coverage

`test/SimpleAuction.t.sol` currently verifies:

- Auction creation increments `auctionCount`.
- Higher bids replace the current winner and update highest bid state.

## Notes

- `withdraw()` follows the pull-payment pattern for outbid users.
- `endAuction()` can be called by any account after expiry, and sends highest bid to the seller.
- This is a learning project and may require additional checks/features for production use.

## Useful Commands

```bash
forge test -vv
forge fmt
forge snapshot
anvil
```
