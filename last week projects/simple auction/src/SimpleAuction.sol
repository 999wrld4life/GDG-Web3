// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract SimpleAuction {

    /* =============================================================
                            STEP 1
        Auction structure
    ============================================================= */

    struct Auction {
        address seller;
        address highestBidder;
        uint256 highestBid;
        uint256 endTime;
        bool ended;
    }

    /* =============================================================
                            STEP 2
        State Variables
    ============================================================= */

    uint256 public auctionCount;

    mapping(uint256 => Auction) public auctions;

    mapping(address => uint256) public pendingReturns;


    /* =============================================================
                            STEP 3
        Create Auction
    ============================================================= */

    function createAuction(uint256 duration) public {

        auctionCount++;

        auctions[auctionCount] = Auction({
            seller: msg.sender,
            highestBidder: address(0),
            highestBid: 0,
            endTime: block.timestamp + duration,
            ended: false
        });
    }


    /* =============================================================
                            STEP 4
        Bid Function
    ============================================================= */

    function bid(uint256 auctionId) public payable {

        Auction storage auction = auctions[auctionId];

        require(block.timestamp < auction.endTime, "Auction already ended");

        require(msg.value > auction.highestBid, "Bid must be higher");

        if (auction.highestBid != 0) {
            pendingReturns[auction.highestBidder] += auction.highestBid;
        }

        auction.highestBidder = msg.sender;
        auction.highestBid = msg.value;
    }


    /* =============================================================
                            STEP 5
        Withdraw Function
    ============================================================= */

    function withdraw() public {

        uint256 amount = pendingReturns[msg.sender];

        require(amount > 0, "No funds to withdraw");

        pendingReturns[msg.sender] = 0;

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Withdraw failed");
    }


    /* =============================================================
                            STEP 6
        End Auction
    ============================================================= */

    function endAuction(uint256 auctionId) public {

        Auction storage auction = auctions[auctionId];

        require(block.timestamp >= auction.endTime, "Auction still running");

        require(!auction.ended, "Auction already ended");

        auction.ended = true;

        (bool success, ) = payable(auction.seller).call{value: auction.highestBid}("");
        require(success, "Transfer to seller failed");
    }
}
