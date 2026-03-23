// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract SharedWallet {

    // STEP 1: Deposit struct
    struct Deposit {
        address user;
        uint256 amount;
        uint256 time;
    }

    // STEP 2: State variables
    address public owner;
    uint256 public totalBalance;

    mapping(address => uint256) public balances;

    Deposit[] public deposits;

    // STEP 3: Constructor
    constructor() {
        owner = msg.sender;
    }

    // STEP 4: Deposit function
    function deposit() public payable {
        require(msg.value > 0, "Send some ETH");

        balances[msg.sender] += msg.value;
        totalBalance += msg.value;

        deposits.push(
            Deposit({
                user: msg.sender,
                amount: msg.value,
                time: block.timestamp
            })
        );
    }

    // STEP 5: Withdraw function
    function withdraw(uint256 amount) public {
        require(msg.sender == owner, "Only owner can withdraw");
        require(amount <= address(this).balance, "Not enough balance");

        // Safe withdrawal using call.
        (bool success, ) = owner.call{value: amount}("");
        require(success, "Transfer failed");

        totalBalance -= amount;
    }

}