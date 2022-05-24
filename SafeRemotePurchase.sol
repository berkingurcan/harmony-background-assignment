// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;
contract Purchase {
    uint public value;
    address payable public seller;
    address payable public buyer;
    uint public confirmTime;
    uint public contractTime;

    enum State { Created, Locked, Release, Inactive }
    State public state;

    modifier condition(bool condition_) {
        require(condition_);
        _;
    }

    error OnlyBuyer();
    error OnlySeller();
    error InvalidState();
    error ValueNotEven();

    modifier onlyBuyer() {
        if (msg.sender != buyer)
            revert OnlyBuyer();
        _;
    }

    modifier onlySeller() {
        if (msg.sender != seller)
            revert OnlySeller();
        _;
    }

    modifier inState(State state_) {
        if (state != state_)
            revert InvalidState();
        _;
    }

    modifier customModifier() {
        require(msg.sender == buyer || block.timestamp >= confirmTime + 5 minutes);
        _;
    }

    event Aborted();
    event PurchaseConfirmed();
    event ItemReceived();
    event SellerRefunded();
    event PurchaseCompleted();

    constructor() payable {
        seller = payable(msg.sender);
        value = msg.value / 2;
        contractTime = block.timestamp;
        if ((2 * value) != msg.value)
            revert ValueNotEven();
    }

    function abort()
        external
        onlySeller
        inState(State.Created)
    {
        emit Aborted();
        state = State.Inactive;

        seller.transfer(address(this).balance);
    }

    function confirmPurchase()
        external
        inState(State.Created)
        condition(msg.value == (2 * value))
        payable
    {
        emit PurchaseConfirmed();
        buyer = payable(msg.sender);
        confirmTime = block.timestamp;
        state = State.Locked;
    }

    function completePurchase()
        external
        inState(State.Locked) 
        customModifier
    {
        emit PurchaseCompleted();
        state = State.Inactive;

        buyer.transfer(value);
        seller.transfer(3 * value);
    }
}
