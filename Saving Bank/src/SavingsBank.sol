// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title SavingsBank
/// @author SavingsBank Assignment
/// @notice A simple savings bank contract allowing deposits, withdrawals, and balance tracking
/// @dev Includes bonus features: minimum deposit, withdrawal cooldown, and owner emergency withdraw
contract SavingsBank {
    // ─────────────────────────────────────────────────────────────
    //  State Variables
    // ─────────────────────────────────────────────────────────────

    /// @notice The contract owner (set at deployment)
    address public owner;

    /// @notice Minimum deposit amount: 0.001 ETH
    uint256 public constant MIN_DEPOSIT = 0.001 ether;

    /// @notice Withdrawal cooldown period: 60 seconds
    uint256 public constant COOLDOWN = 60 seconds;

    /// @notice Maps each address to their ETH balance in the bank
    mapping(address => uint256) private balances;

    /// @notice Tracks the last withdrawal timestamp per user (for cooldown)
    mapping(address => uint256) private lastWithdrawal;

    // ─────────────────────────────────────────────────────────────
    //  Events
    // ─────────────────────────────────────────────────────────────

    /// @notice Emitted when a user deposits ETH
    event Deposit(address indexed user, uint256 amount);

    /// @notice Emitted when a user withdraws ETH
    event Withdrawal(address indexed user, uint256 amount);

    /// @notice Emitted when the owner performs an emergency withdrawal
    event EmergencyWithdraw(address indexed owner, uint256 amount);

    // ─────────────────────────────────────────────────────────────
    //  Errors
    // ─────────────────────────────────────────────────────────────

    error BelowMinimumDeposit(uint256 sent, uint256 minimum);
    error InsufficientBalance(uint256 requested, uint256 available);
    error CooldownActive(uint256 remainingSeconds);
    error OnlyOwner();
    error TransferFailed();
    error ZeroAmount();

    // ─────────────────────────────────────────────────────────────
    //  Modifiers
    // ─────────────────────────────────────────────────────────────

    modifier onlyOwner() {
        if (msg.sender != owner) revert OnlyOwner();
        _;
    }

    // ─────────────────────────────────────────────────────────────
    //  Constructor
    // ─────────────────────────────────────────────────────────────

    constructor() {
        owner = msg.sender;
    }

    // ─────────────────────────────────────────────────────────────
    //  External / Public Functions
    // ─────────────────────────────────────────────────────────────

    /// @notice Deposit ETH into the savings bank
    /// @dev Requires a minimum deposit of MIN_DEPOSIT (0.001 ETH)
    function deposit() external payable {
        if (msg.value < MIN_DEPOSIT) {
            revert BelowMinimumDeposit(msg.value, MIN_DEPOSIT);
        }

        balances[msg.sender] += msg.value;

        emit Deposit(msg.sender, msg.value);
    }

    /// @notice Withdraw ETH from the savings bank
    /// @param amount The amount of ETH (in wei) to withdraw
    /// @dev Enforces balance check and 60-second cooldown between withdrawals
    function withdraw(uint256 amount) external {
        if (amount == 0) revert ZeroAmount();

        uint256 userBalance = balances[msg.sender];
        if (amount > userBalance) {
            revert InsufficientBalance(amount, userBalance);
        }

        // Cooldown check
        uint256 elapsed = block.timestamp - lastWithdrawal[msg.sender];
        if (elapsed < COOLDOWN && lastWithdrawal[msg.sender] != 0) {
            revert CooldownActive(COOLDOWN - elapsed);
        }

        // Effects before interaction (CEI pattern)
        balances[msg.sender] -= amount;
        lastWithdrawal[msg.sender] = block.timestamp;

        // Interaction
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if (!success) revert TransferFailed();

        emit Withdrawal(msg.sender, amount);
    }

    /// @notice Emergency withdraw — owner can drain the entire contract
    /// @dev Only callable by the contract owner
    function emergencyWithdraw() external onlyOwner {
        uint256 contractBalance = address(this).balance;
        if (contractBalance == 0) revert ZeroAmount();

        // Reset all users' balances is not feasible in a loop, but
        // owner is trusted; this is an emergency escape hatch.
        (bool success, ) = payable(owner).call{value: contractBalance}("");
        if (!success) revert TransferFailed();

        emit EmergencyWithdraw(owner, contractBalance);
    }

    // ─────────────────────────────────────────────────────────────
    //  View Functions
    // ─────────────────────────────────────────────────────────────

    /// @notice Returns the balance of a specific user
    /// @param user The address to query
    /// @return The user's deposited ETH balance in wei
    function getBalance(address user) external view returns (uint256) {
        return balances[user];
    }

    /// @notice Returns the total ETH held by the contract
    /// @return Total ETH in wei
    function getTotalBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /// @notice Returns seconds remaining before a user can withdraw again
    /// @param user The address to query
    /// @return Seconds until cooldown expires (0 if no cooldown active)
    function getCooldownRemaining(address user) external view returns (uint256) {
        if (lastWithdrawal[user] == 0) return 0;
        uint256 elapsed = block.timestamp - lastWithdrawal[user];
        if (elapsed >= COOLDOWN) return 0;
        return COOLDOWN - elapsed;
    }
}