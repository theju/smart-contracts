// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

/**
 * @title RecurringSubscription
 */
contract RecurringSubscription {

    bool isActive;

    uint256 amount;
    uint256 intervalNum = 1;
    uint256 interval;
    uint256 timeCreated;

    address owner;
    address provider;
    address subscriber;

    event Collect(uint256 ts);
    event Payout(uint256 ts);
    event Cancel(uint256 ts);

    constructor(address _provider, address _subscriber, uint256 _amount, uint256 _interval) {
        owner = address(msg.sender);
        provider = _provider;
        subscriber = _subscriber;
        amount = _amount;
        interval = _interval;
        isActive = true;
        timeCreated = block.timestamp;
    }

    function cancel() public {
        require(msg.sender == provider || msg.sender == subscriber, "Only provider or subscriber can cancel.");
        isActive = false;
        emit Cancel(block.timestamp);
    }

    function collect() public payable {
        require(msg.sender == subscriber, "Only subscriber can pay.");
        require(isActive == true, "Subscription has been cancelled.");
        require(block.timestamp >= timeCreated + intervalNum * interval, "Next subscription interval has not arrived.");
        require(msg.value == amount, "Amount is not equal to the subscription amount.");

        intervalNum += 1;
        emit Collect(block.timestamp);
    }

    function payout() public payable {
        require(msg.sender == provider, "Only provider can be paid.");
        require(isActive == true, "Subscription has been cancelled.");

        payable(provider).transfer(address(this).balance * uint256(95) / uint256(100));
        payable(owner).transfer(address(this).balance * uint256(5) / uint256(100));
        emit Payout(block.timestamp);
    }

    function getChargeAmount() public view returns (uint256) {
        return amount;
    }

    function getInterval() public view returns (uint256) {
        return interval;
    }

    function getIntervalNum() public view returns (uint256) {
        return intervalNum;
    }

    function getTimeCreated() public view returns (uint256) {
        return timeCreated;
    }

    function getSubscriber() public view returns (address) {
        return subscriber;
    }
}
