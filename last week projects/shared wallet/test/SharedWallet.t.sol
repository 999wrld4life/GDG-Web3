// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import {Test} from "forge-std/Test.sol";
import {SharedWallet} from "../src/SharedWallet.sol";

contract SharedWalletTest is Test {
    SharedWallet wallet;
    address user1 = address(0x1);
    address user2 = address(0x2);

    receive() external payable {}

    function setUp() public {
        wallet = new SharedWallet();
        vm.label(user1, "User1");
        vm.label(user2, "User2");
    }

    function testDeposit() public {
        vm.deal(user1, 1 ether);
        vm.deal(user2, 2 ether);

        // User1 deposits 0.5 ETH
        vm.prank(user1);
        wallet.deposit{value: 0.5 ether}();

        assertEq(wallet.balances(user1), 0.5 ether);
        assertEq(wallet.totalBalance(), 0.5 ether);

        // User2 deposits 1 ETH
        vm.prank(user2);
        wallet.deposit{value: 1 ether}();

        assertEq(wallet.balances(user2), 1 ether);
        assertEq(wallet.totalBalance(), 1.5 ether);
    }

    function testWithdraw() public {
        // Owner deposits some ETH to the wallet
        wallet.deposit{value: 2 ether}();

        // Owner withdraws 1 ETH
        wallet.withdraw(1 ether);

        assertEq(address(wallet).balance, 1 ether);
        assertEq(wallet.totalBalance(), 1 ether);
    }
}
