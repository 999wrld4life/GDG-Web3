// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract StudentSavingsWallet {
    struct Transaction {
    address user;
    uint256 amount;
    string action;
    uint256 timestamp;
}

    mapping(address => uint256) private balances;

    Transaction[] private transactions;


    function deposit() public payable {
    balances[msg.sender] += msg.value;

    transactions.push(
        Transaction({
            user: msg.sender,
            amount: msg.value,
            action: "deposit",
            timestamp: block.timestamp
        })
    );
}
    function withdraw(uint256 amount) public {
    require(balances[msg.sender] >= amount, "Insufficient balance");

    balances[msg.sender] -= amount;

    (bool success, ) = payable(msg.sender).call{value: amount}("");
    require(success, "Transfer failed");

    transactions.push(
        Transaction({
            user: msg.sender,
            amount: amount,
            action: "withdraw",
            timestamp: block.timestamp
        })
    );
}
    function getMyBalance() public view returns (uint256) {
    return balances[msg.sender];
}

    function getMyTransactions() public view returns (Transaction[] memory) {
    uint count = 0;

    
    for (uint i = 0; i < transactions.length; i++) {
        if (transactions[i].user == msg.sender) {
            count++;
        }
    }

    
    Transaction[] memory result = new Transaction[](count);
    uint j = 0;

    // Populate the array
    for (uint i = 0; i < transactions.length; i++) {
        if (transactions[i].user == msg.sender) {
            result[j] = transactions[i];
            j++;
        }
    }

    return result;
}




}
