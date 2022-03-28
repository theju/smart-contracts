// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

contract Auction {
    struct Bid {
        uint time;
        address bidder;
        uint256 bid;
    }

    event BidReceived(Bid bid);
    event ReservePriceChanged(uint256 price);

    address private owner;
    address private platform; // NOTE: Set the value here before deploy else platform commission will get burnt
    uint8 private commission = 5;
    bool private ended;
    uint256 private reservePrice;
    uint private endTime;
    Bid private highestBid;
    mapping(address => uint256) private balances;

    constructor(uint256 _reservePrice, uint _endTime) {
        owner = msg.sender;
        ended = false;
        reservePrice = _reservePrice;
        endTime = block.timestamp + _endTime;
    }

    function setPlatform(address _addr) public {
        require(msg.sender == platform, "Only platform may call this method");
        platform = _addr;
    }

    function setFees(uint8 _commission) public {
        require(msg.sender == platform, "Only platform may call this method");
        commission = _commission;
    }

    function bid() public payable {
        require(msg.sender != owner, "Owner cannot bid");
        require(msg.value > reservePrice, "Bid must be larger than reserve price");
        require(msg.value > highestBid.bid, "Bid must be greater than current highest bid");
        require(block.timestamp < endTime, "Auction closed");
        require(ended == false, "Auction has ended");
        balances[highestBid.bidder] += highestBid.bid;
        Bid memory bb = Bid({time: block.timestamp, bidder: msg.sender, bid: msg.value});
        highestBid = bb;

        emit BidReceived(highestBid);
    }

    function changeReservePrice(uint256 price) public {
        require(msg.sender == owner, "Only owner can change price");
        require(price >= highestBid.bid, "Reserve price cannot be lower than highest bid");
        require(ended == false, "Auction has ended");
        reservePrice = price;

        emit ReservePriceChanged(reservePrice);
    }

    function refund() public returns (bool) {
        require(balances[msg.sender] > 0, "No balance for user");
        uint256 value = balances[msg.sender];
        balances[msg.sender] = 0;
        if (!payable(msg.sender).send(value)) {
            balances[msg.sender] = value;
            return false;
        }
        return true;
    }

    function claim() public {
        require(msg.sender == owner || msg.sender == platform, "Only owner or platform can withdraw");
        require(block.timestamp > endTime, "Auction still ongoing");
        ended = true;
        if (msg.sender == owner) {
            payable(address(owner)).transfer((1 - commission / 100) * highestBid.bid);
        } else {
            payable(address(platform)).transfer(commission / 100 * highestBid.bid);
        }
    }
}
