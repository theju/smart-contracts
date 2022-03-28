// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

/**
 * @title RecurringSubscription
 */
contract RecurringSubscription {

    bool active;

    uint256 amount;
    uint256 intervalNum = 1;
    uint256 interval;
    uint256 timeCreated;

    address provider;
    address subscriber;

    event Collect(uint256 ts);
    event Payout(uint256 ts);
    event Cancel(uint256 ts);

    constructor(address _subscriber, uint256 _amount, uint256 _interval) {
        provider = address(msg.sender);
        subscriber = _subscriber;
        amount = _amount;
        interval = _interval;
        active = true;
        timeCreated = block.timestamp;
    }

    function cancel() public {
        require(msg.sender == provider || msg.sender == subscriber, "Only provider or subscriber can cancel.");
        active = false;
        selfdestruct(payable(address(subscriber)));
        emit Cancel(block.timestamp);
    }

    function collect() public payable {
        require(msg.sender == subscriber, "Only subscriber can pay.");
        require(active == true, "Subscription has been cancelled.");

        emit Collect(block.timestamp);
    }

    function payout() public payable {
        require(msg.sender == provider, "Only provider can be paid.");
        require(active == true, "Subscription has been cancelled.");
        require(block.timestamp >= timeCreated + intervalNum * interval, "Interval has not yet been reached.");

        intervalNum += 1;
        payable(provider).transfer(amount);
        emit Payout(block.timestamp);
    }

    function isActive() public view returns (bool) {
        return active;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
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
