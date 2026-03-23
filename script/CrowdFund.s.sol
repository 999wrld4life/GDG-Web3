// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Import Foundry's scripting utilities
import "forge-std/Script.sol";

// Import the contract we want to deploy
import {CrowdFund} from "../src/CrowdFund.sol";

contract DeployCrowdFund is Script {

    function run() external {

        // Start broadcasting transactions to the blockchain
        vm.startBroadcast();

        // Deploy the contract
        CrowdFund crowdFund = new CrowdFund();

        // Stop broadcasting
        vm.stopBroadcast();
    }
}
