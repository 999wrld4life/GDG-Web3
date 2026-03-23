// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {CrowdFund} from "../src/CrowdFund.sol";

contract CrowdFundTest is Test {
CrowdFund crowdfund;

address alice = address(1);
address bob = address(2);

function setUp() public {
    crowdfund = new CrowdFund();
}

function testCreateCampaign() public {

    crowdfund.create(1 ether, 7 days);

    assertEq(crowdfund.campaignCount(), 1);
}
}
