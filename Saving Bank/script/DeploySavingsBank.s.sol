// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {SavingsBank} from "../src/SavingsBank.sol";

/// @title DeploySavingsBank
/// @notice Foundry deployment script for the SavingsBank contract
contract DeploySavingsBank is Script {
    function run() external returns (SavingsBank bank) {
        // Read deployer private key from environment or use Anvil default
        uint256 deployerKey = vm.envOr(
            "PRIVATE_KEY",
            uint256(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80) // Anvil account #0
        );

        address deployer = vm.addr(deployerKey);

        console.log("=========================================");
        console.log("  Deploying SavingsBank");
        console.log("=========================================");
        console.log("  Deployer  :", deployer);
        console.log("  Chain ID  :", block.chainid);
        console.log("  Balance   :", deployer.balance / 1e18, "ETH");

        vm.startBroadcast(deployerKey);

        bank = new SavingsBank();

        vm.stopBroadcast();

        console.log("=========================================");
        console.log("  Deployment Successful!");
        console.log("  Contract  :", address(bank));
        console.log("  Owner     :", bank.owner());
        console.log("  Min Dep.  :", bank.MIN_DEPOSIT(), "wei (0.001 ETH)");
        console.log("  Cooldown  :", bank.COOLDOWN(), "seconds");
        console.log("=========================================");
    }
}