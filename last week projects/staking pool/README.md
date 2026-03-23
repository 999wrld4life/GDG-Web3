# Staking Pool (Foundry)

A simple ETH staking pool contract built with Foundry.

Users can:
- Stake ETH
- Accrue rewards over time
- Unstake to receive principal + reward

## Features

- `stake()` accepts ETH and records stake timestamp.
- `calculateReward(address)` returns pending reward based on elapsed time.
- `unstake()` pays back `staked amount + reward` and marks stake as claimed.

Current reward formula:

```solidity
reward = (block.timestamp - startTime) * rewardRate;
```

## Project Structure

```text
src/
	StakingPool.sol
test/
	StakingPool.t.sol
script/
	Counter.s.sol   # deployment script that deploys StakingPool
```

## Requirements

- [Foundry](https://book.getfoundry.sh/getting-started/installation)

## Install

```bash
forge install
```

## Build

```bash
forge build
```

## Test

```bash
forge test -vv
```

## Deploy Script

Run the script locally:

```bash
forge script script/Counter.s.sol:StakingPoolScript
```

Broadcast to a network (example):

```bash
forge script script/Counter.s.sol:StakingPoolScript \
	--rpc-url $RPC_URL \
	--private-key $PRIVATE_KEY \
	--broadcast
```

## Contract Overview

### State

- `owner`: address that deployed the contract
- `rewardRate`: reward earned per second
- `stakes[user]`: user stake info (`amount`, `startTime`, `claimed`)

### Main Functions

- `stake()`
	- Requires `msg.value > 0`
	- Stores stake for `msg.sender`

- `calculateReward(address user)`
	- Returns `0` if stake already claimed
	- Otherwise returns elapsed-time reward

- `unstake()`
	- Requires stake is not already claimed
	- Marks stake claimed
	- Transfers principal + reward to caller

## Important Notes

- The contract must have enough ETH balance to pay rewards on `unstake()`.
- New `stake()` calls overwrite a user's previous stake in the current design.
- There is no owner-only funding or withdrawal method yet.
- Reward math is intentionally simple for learning/demo purposes.

## Next Improvements

- Add explicit pool funding function and events.
- Support multiple stakes per user.
- Add input validation for unstake edge cases.
- Add safety checks for pool insolvency before transfer.
- Add more test coverage (multiple users, re-stake flows, edge timestamps).

## License

MIT
