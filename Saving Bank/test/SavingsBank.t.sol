// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {SavingsBank} from "../src/SavingsBank.sol";

/// @title SavingsBankTest
/// @notice Full test suite for the SavingsBank contract
contract SavingsBankTest is Test {
    event Deposit(address indexed user, uint256 amount);
    event Withdrawal(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed owner, uint256 amount);
    SavingsBank public bank;

    // Test actors
    address public owner;
    address public alice;
    address public bob;
    address public charlie;

    // Constants matching the contract
    uint256 constant MIN_DEPOSIT = 0.001 ether;
    uint256 constant COOLDOWN    = 60 seconds;

    // ─────────────────────────────────────────────────────────────
    //  Setup
    // ─────────────────────────────────────────────────────────────

    function setUp() public {
        owner   = makeAddr("owner");
        alice   = makeAddr("alice");
        bob     = makeAddr("bob");
        charlie = makeAddr("charlie");

        // Deploy from owner account
        vm.prank(owner);
        bank = new SavingsBank();

        // Fund test accounts
        vm.deal(alice,   10 ether);
        vm.deal(bob,     10 ether);
        vm.deal(charlie, 10 ether);
    }

    // ─────────────────────────────────────────────────────────────
    //  ✅ Deposit Tests
    // ─────────────────────────────────────────────────────────────

    /// @notice A user can deposit ETH and the balance updates correctly
    function test_DepositUpdatesBalance() public {
        uint256 depositAmount = 1 ether;

        vm.prank(alice);
        bank.deposit{value: depositAmount}();

        assertEq(bank.getBalance(alice), depositAmount, "Alice balance mismatch after deposit");
    }

    /// @notice Depositing emits the Deposit event with correct args
    function test_DepositEmitsEvent() public {
        uint256 depositAmount = 0.5 ether;

        vm.expectEmit(true, false, false, true);
        emit Deposit(alice, depositAmount);

        vm.prank(alice);
        bank.deposit{value: depositAmount}();
    }

    /// @notice Multiple deposits accumulate correctly
    function test_MultipleDepositsAccumulate() public {
        vm.startPrank(alice);
        bank.deposit{value: 1 ether}();
        bank.deposit{value: 2 ether}();
        bank.deposit{value: 0.5 ether}();
        vm.stopPrank();

        assertEq(bank.getBalance(alice), 3.5 ether, "Accumulated balance wrong");
    }

    /// @notice Deposit below minimum reverts
    function test_DepositBelowMinimumReverts() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                SavingsBank.BelowMinimumDeposit.selector,
                0.0009 ether,
                MIN_DEPOSIT
            )
        );
        vm.prank(alice);
        bank.deposit{value: 0.0009 ether}();
    }

    /// @notice Zero deposit reverts
    function test_ZeroDepositReverts() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                SavingsBank.BelowMinimumDeposit.selector,
                0,
                MIN_DEPOSIT
            )
        );
        vm.prank(alice);
        bank.deposit{value: 0}();
    }

    /// @notice Deposit at exactly the minimum amount succeeds
    function test_DepositAtMinimumSucceeds() public {
        vm.prank(alice);
        bank.deposit{value: MIN_DEPOSIT}();

        assertEq(bank.getBalance(alice), MIN_DEPOSIT);
    }

    // ─────────────────────────────────────────────────────────────
    //  ✅ Withdrawal Tests
    // ─────────────────────────────────────────────────────────────

    /// @notice A user can withdraw their deposited funds
    function test_WithdrawUpdatesBalance() public {
        // Setup
        vm.prank(alice);
        bank.deposit{value: 2 ether}();

        uint256 aliceBalanceBefore = alice.balance;

        // Withdraw
        vm.prank(alice);
        bank.withdraw(1 ether);

        assertEq(bank.getBalance(alice), 1 ether,                    "Bank balance not updated");
        assertEq(alice.balance,          aliceBalanceBefore + 1 ether, "ETH not returned to Alice");
    }

    /// @notice Withdrawal emits the Withdrawal event with correct args
    function test_WithdrawEmitsEvent() public {
        vm.prank(alice);
        bank.deposit{value: 2 ether}();

        vm.expectEmit(true, false, false, true);
        emit Withdrawal(alice, 1 ether);

        vm.prank(alice);
        bank.withdraw(1 ether);
    }

    /// @notice A user cannot withdraw more than their balance
    function test_WithdrawMoreThanBalanceReverts() public {
        vm.prank(alice);
        bank.deposit{value: 1 ether}();

        vm.expectRevert(
            abi.encodeWithSelector(
                SavingsBank.InsufficientBalance.selector,
                2 ether,
                1 ether
            )
        );
        vm.prank(alice);
        bank.withdraw(2 ether);
    }

    /// @notice A user with zero balance cannot withdraw
    function test_WithdrawWithNoBalanceReverts() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                SavingsBank.InsufficientBalance.selector,
                1 ether,
                0
            )
        );
        vm.prank(alice);
        bank.withdraw(1 ether);
    }

    /// @notice Withdrawing zero amount reverts
    function test_WithdrawZeroReverts() public {
        vm.prank(alice);
        bank.deposit{value: 1 ether}();

        vm.expectRevert(SavingsBank.ZeroAmount.selector);
        vm.prank(alice);
        bank.withdraw(0);
    }

    /// @notice Full withdrawal leaves zero balance
    function test_FullWithdrawalLeavesZeroBalance() public {
        vm.prank(alice);
        bank.deposit{value: 1 ether}();

        vm.prank(alice);
        bank.withdraw(1 ether);

        assertEq(bank.getBalance(alice), 0, "Balance should be zero after full withdrawal");
    }

    // ─────────────────────────────────────────────────────────────
    //  ✅ Cooldown Tests (Bonus)
    // ─────────────────────────────────────────────────────────────

    /// @notice Second withdrawal within cooldown period reverts
    function test_WithdrawCooldownPreventsSecondWithdraw() public {
        vm.prank(alice);
        bank.deposit{value: 3 ether}();

        // First withdrawal
        vm.prank(alice);
        bank.withdraw(0.5 ether);

        // Immediately try again — should revert
        vm.expectRevert();
        vm.prank(alice);
        bank.withdraw(0.5 ether);
    }

    /// @notice Withdrawal succeeds after cooldown expires
    function test_WithdrawSucceedsAfterCooldown() public {
        vm.prank(alice);
        bank.deposit{value: 3 ether}();

        vm.prank(alice);
        bank.withdraw(0.5 ether);

        // Warp past the cooldown
        vm.warp(block.timestamp + COOLDOWN + 1);

        vm.prank(alice);
        bank.withdraw(0.5 ether);

        assertEq(bank.getBalance(alice), 2 ether);
    }

    /// @notice getCooldownRemaining returns correct value
    function test_CooldownRemainingIsAccurate() public {
        vm.prank(alice);
        bank.deposit{value: 1 ether}();

        vm.prank(alice);
        bank.withdraw(0.1 ether);

        // Warp 30 seconds in
        vm.warp(block.timestamp + 30);

        uint256 remaining = bank.getCooldownRemaining(alice);
        assertApproxEqAbs(remaining, 30, 1, "Cooldown remaining should be ~30s");
    }

    /// @notice New user has no cooldown
    function test_NewUserHasNoCooldown() public {
        assertEq(bank.getCooldownRemaining(alice), 0);
    }

    // ─────────────────────────────────────────────────────────────
    //  ✅ Total Balance Tests
    // ─────────────────────────────────────────────────────────────

    /// @notice Contract total balance reflects deposits
    function test_TotalBalanceReflectsDeposits() public {
        vm.prank(alice);
        bank.deposit{value: 1 ether}();

        vm.prank(bob);
        bank.deposit{value: 2 ether}();

        assertEq(bank.getTotalBalance(), 3 ether, "Total balance mismatch");
    }

    /// @notice Total balance decreases after withdrawal
    function test_TotalBalanceDecreasesAfterWithdrawal() public {
        vm.prank(alice);
        bank.deposit{value: 2 ether}();

        vm.prank(alice);
        bank.withdraw(1 ether);

        assertEq(bank.getTotalBalance(), 1 ether);
    }

    /// @notice Total balance starts at zero
    function test_TotalBalanceStartsAtZero() public view {
        assertEq(bank.getTotalBalance(), 0);
    }

    // ─────────────────────────────────────────────────────────────
    //  ✅ BONUS: Multiple Users
    // ─────────────────────────────────────────────────────────────

    /// @notice Multiple users can deposit and balances are tracked independently
    function test_MultipleUsersIndependentBalances() public {
        vm.prank(alice);
        bank.deposit{value: 1 ether}();

        vm.prank(bob);
        bank.deposit{value: 2 ether}();

        vm.prank(charlie);
        bank.deposit{value: 3 ether}();

        assertEq(bank.getBalance(alice),   1 ether, "Alice balance wrong");
        assertEq(bank.getBalance(bob),     2 ether, "Bob balance wrong");
        assertEq(bank.getBalance(charlie), 3 ether, "Charlie balance wrong");
        assertEq(bank.getTotalBalance(),   6 ether, "Total balance wrong");
    }

    /// @notice One user withdrawing does not affect another user's balance
    function test_WithdrawDoesNotAffectOtherUsers() public {
        vm.prank(alice);
        bank.deposit{value: 2 ether}();

        vm.prank(bob);
        bank.deposit{value: 2 ether}();

        vm.prank(alice);
        bank.withdraw(1 ether);

        assertEq(bank.getBalance(alice), 1 ether, "Alice balance wrong after withdrawal");
        assertEq(bank.getBalance(bob),   2 ether, "Bob balance should be unaffected");
    }

    /// @notice Multiple users deposit and withdraw in sequence
    function test_MultipleUsersDepositAndWithdraw() public {
        // Alice deposits
        vm.prank(alice);
        bank.deposit{value: 3 ether}();

        // Bob deposits
        vm.prank(bob);
        bank.deposit{value: 1 ether}();

        // Alice withdraws half
        vm.prank(alice);
        bank.withdraw(1.5 ether);

        // Warp cooldown for alice
        vm.warp(block.timestamp + COOLDOWN + 1);

        // Alice withdraws the rest
        vm.prank(alice);
        bank.withdraw(1.5 ether);

        // Bob withdraws all
        vm.prank(bob);
        bank.withdraw(1 ether);

        assertEq(bank.getBalance(alice), 0,       "Alice final balance wrong");
        assertEq(bank.getBalance(bob),   0,       "Bob final balance wrong");
        assertEq(bank.getTotalBalance(), 0,       "Contract should be empty");
    }

    // ─────────────────────────────────────────────────────────────
    //  ✅ BONUS: Emergency Withdraw (Owner)
    // ─────────────────────────────────────────────────────────────

    /// @notice Owner can emergency withdraw all funds
    function test_OwnerEmergencyWithdraw() public {
        vm.prank(alice);
        bank.deposit{value: 2 ether}();

        vm.prank(bob);
        bank.deposit{value: 1 ether}();

        uint256 ownerBefore = owner.balance;

        vm.expectEmit(true, false, false, true);
        emit EmergencyWithdraw(owner, 3 ether);

        vm.prank(owner);
        bank.emergencyWithdraw();

        assertEq(owner.balance,          ownerBefore + 3 ether, "Owner did not receive funds");
        assertEq(bank.getTotalBalance(), 0,                     "Contract should be empty");
    }

    /// @notice Non-owner cannot call emergencyWithdraw
    function test_NonOwnerCannotEmergencyWithdraw() public {
        vm.prank(alice);
        bank.deposit{value: 1 ether}();

        vm.expectRevert(SavingsBank.OnlyOwner.selector);
        vm.prank(alice);
        bank.emergencyWithdraw();
    }

    /// @notice Emergency withdraw on empty contract reverts
    function test_EmergencyWithdrawOnEmptyContractReverts() public {
        vm.expectRevert(SavingsBank.ZeroAmount.selector);
        vm.prank(owner);
        bank.emergencyWithdraw();
    }

    // ─────────────────────────────────────────────────────────────
    //  ✅ View / Getter Tests
    // ─────────────────────────────────────────────────────────────

    /// @notice getBalance returns 0 for users with no deposits
    function test_GetBalanceReturnsZeroForNewUser() public view {
        assertEq(bank.getBalance(alice), 0);
    }

    /// @notice Owner is set correctly in constructor
    function test_OwnerSetCorrectly() public view {
        assertEq(bank.owner(), owner);
    }

    // ─────────────────────────────────────────────────────────────
    //  ✅ Fuzz Tests
    // ─────────────────────────────────────────────────────────────

    /// @notice Fuzz: any valid deposit amount is tracked correctly
    function testFuzz_DepositTracksAmount(uint256 amount) public {
        amount = bound(amount, MIN_DEPOSIT, 5 ether);
        vm.deal(alice, amount);

        vm.prank(alice);
        bank.deposit{value: amount}();

        assertEq(bank.getBalance(alice), amount);
        assertEq(bank.getTotalBalance(), amount);
    }

    /// @notice Fuzz: partial withdraw always keeps correct balance
    function testFuzz_PartialWithdrawCorrectBalance(uint256 depositAmt, uint256 withdrawAmt) public {
        depositAmt  = bound(depositAmt,  MIN_DEPOSIT, 5 ether);
        withdrawAmt = bound(withdrawAmt, 1,           depositAmt);
        vm.deal(alice, depositAmt);

        vm.prank(alice);
        bank.deposit{value: depositAmt}();

        vm.prank(alice);
        bank.withdraw(withdrawAmt);

        assertEq(bank.getBalance(alice), depositAmt - withdrawAmt);
    }
}