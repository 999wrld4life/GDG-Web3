// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/StakingPool.sol";

contract StakingPoolTest is Test {
    StakingPool pool;

    receive() external payable {}

    function setUp() public {
        pool = new StakingPool(1 ether); // 1 ether per second reward
    }

    function testStakeAndUnstake() public {
        vm.deal(address(this), 10 ether);
        pool.stake{value: 1 ether}();

        uint256 reward = pool.calculateReward(address(this));
        assertEq(reward, 0); // immediately after staking, reward is 0

        // simulate 10 seconds passing
        vm.warp(block.timestamp + 10);
        reward = pool.calculateReward(address(this));
        assertEq(reward, 10 ether);

        // Provide reward liquidity so unstake can pay principal + rewards.
        vm.deal(address(pool), 20 ether);

        pool.unstake();
        // After unstake, reward should be claimed
        reward = pool.calculateReward(address(this));
        assertEq(reward, 0);
    }
}
