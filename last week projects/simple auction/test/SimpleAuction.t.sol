// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/SimpleAuction.sol";

contract SimpleAuctionTest is Test {

    SimpleAuction auction;

    address seller = address(1);
    address bidder1 = address(2);
    address bidder2 = address(3);

    function setUp() public {
        auction = new SimpleAuction();
    }

    function testCreateAuction() public {

        vm.prank(seller);
        auction.createAuction(100);

        assertEq(auction.auctionCount(), 1);
    }

    function testBidding() public {

        vm.prank(seller);
        auction.createAuction(100);

        vm.deal(bidder1, 1 ether);
        vm.deal(bidder2, 1 ether);

        vm.prank(bidder1);
        auction.bid{value: 0.5 ether}(1);

        vm.prank(bidder2);
        auction.bid{value: 0.8 ether}(1);

        (, address highestBidder, uint256 highestBid,,) = auction.auctions(1);

        assertEq(highestBidder, bidder2);
        assertEq(highestBid, 0.8 ether);
    }
}
