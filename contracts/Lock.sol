// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";

contract Subscription is Ownable {
    address public paymentToken;
    address public discountToken;   // apply discount if user holds this token ( NFT )

    uint public pricePerMonth;
    uint public discountPercentageFullYear;
    uint public discountPercentageForDiscountToken;

    mapping(address => uint) public subscriptions;  // user => util timestamp

    event Subscribed(address subscriber, uint until);

    /**
     * @dev Constructor.
     * @param _paymentToken Token used for subscription payments.
     * @param _discountToken Token used for dicounts if user hplds it.
     * @param _pricePerMonth Price per month of subscription.
     * @param _discountPercentageFullYear Discount percentage for full year.
     * @param _discountPercentageForDiscountToken Discount percentage for holding _discountToken.
     */
    constructor(address _paymentToken, address _discountToken, uint _pricePerMonth, uint _discountPercentageFullYear, uint _discountPercentageForDiscountToken) {
        require(_paymentToken != address(0), "Wrong _paymentToken");
        require(_pricePerMonth > 0, "Wrong _pricePerMonth");
        require(_discountPercentageFullYear > 0 && discountPercentageFullYear <= 100, "Wrong _discountPercentageFullYear");

        paymentToken = _paymentToken;
        discountToken = _discountToken;
        pricePerMonth = _pricePerMonth;
        discountPercentageFullYear = _discountPercentageFullYear;
        discountPercentageForDiscountToken = _discountPercentageForDiscountToken;
    }

    /**
     * @dev Updates price per month.
     * @param _pricePerMonth Price to be used.
     */
    function updatePricePerMonth(uint _pricePerMonth) external onlyOwner() {
        pricePerMonth = _pricePerMonth;
    }

    /**
     * @dev Updates discount token.
     * @param _discountToken Token address to be used.
     */
    function updateDiscountToken(address _discountToken) external onlyOwner() {
        discountToken = _discountToken;
    }

    /**
     * @dev Updates discount percentage for full year.
     * @param _discountPercentageFullYear Discount percentage for full year to be used.
     */
    function updateDiscountPercentageFullYear(uint _discountPercentageFullYear) external onlyOwner() {
        discountPercentageFullYear = _discountPercentageFullYear;
    }

    /**
     * dev Updates discount percentage for holding _discountToken.
     * @param _discountPercentageForDiscountToken Discount percentage for holding _discountToken to be used.
     */
    function updateDiscountPercentageForDiscountToken(uint _discountPercentageForDiscountToken) external onlyOwner() {
        discountPercentageForDiscountToken = _discountPercentageForDiscountToken;
    }

    /**
     * @dev Subscribes user.
     * @param _months Month count to be sunscribed for.
     */
    function subscribe(uint _months) external {
        uint discount;
        uint fullYears = (_months / 12);
        uint amountToPay = pricePerMonth * _months;
        
        if (fullYears > 0) {
            discount = pricePerMonth * fullYears * discountPercentageFullYear / 100;
            amountToPay -= discount;
        }

        if (discountToken != address(0)) {
            if (IERC20(discountToken).balanceOf(msg.sender) > 0) {
                // TODO: transferFrom ?
                amountToPay -= amountToPay * discountPercentageForDiscountToken / 100;
            }
        }

        IERC20(paymentToken).transferFrom(msg.sender, address(this), amountToPay);

        subscriptions[msg.sender] += subscriptions[msg.sender] + _months * 4 weeks;
    }

    /**
     * @dev Cancels subscription for subscriber.
     * @param _subscriber Subscriber address.
     */
    function cancelSubscription(address _subscriber) external {
        require(_subscriber != address(0), "Wrong _subscriber");
        require(msg.sender == owner() || msg.sender == _subscriber, "Not allowed");
        require(subscriptions[_subscriber] > block.timestamp, "No ongoing subscription");

        delete subscriptions[_subscriber];
        // TODO: return portion or all the rest of payment?
    }
}
