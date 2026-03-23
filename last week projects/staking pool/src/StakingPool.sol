// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract StakingPool {

    struct Stake {
        uint256 amount;
        uint256 startTime;
        bool claimed;
    }

    address public owner;
    uint256 public rewardRate;
    mapping(address => Stake) public stakes;

    constructor(uint256 _rewardRate) {
        owner = msg.sender;
        rewardRate = _rewardRate;
    }

    function stake() external payable {
        require(msg.value > 0, "Must stake some ETH");

        stakes[msg.sender] = Stake({
            amount: msg.value,
            startTime: block.timestamp,
            claimed: false
        });
    }

    function calculateReward(address _user) public view returns (uint256) {
        Stake memory userStake = stakes[_user];
        if(userStake.claimed) return 0;
        uint256 duration = block.timestamp - userStake.startTime;
        return duration * rewardRate;
    }

    function unstake() external {
        Stake storage userStake = stakes[msg.sender];
        require(!userStake.claimed, "Already claimed");

        uint256 reward = calculateReward(msg.sender);
        uint256 payout = userStake.amount + reward;

        userStake.claimed = true;

        (bool success, ) = payable(msg.sender).call{value: payout}("");
        require(success, "Transfer failed");
    }
}
