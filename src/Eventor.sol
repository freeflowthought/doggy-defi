// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {EventorHarness} from "src/EventorHarness.sol";

contract Eventor is EventorHarness {
    address public paymaster;
    address public owner;

    modifier onlyEOA() {
        require(msg.sender == tx.origin, OnlyEOA());
        _;
    }

    modifier onlyPaymaster() {
        require(msg.sender == paymaster, OnlyPaymaster());
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, OnlyOwner());
        _;
    }

    constructor(IERC20 _USDC, address _paymaster) EventorHarness(_USDC) {
        owner = msg.sender;
        paymaster = _paymaster;
    }

    function setPaymaster(address _paymaster) public onlyOwner {
        paymaster = _paymaster;
    }

    function commit(address _to, uint256 _declaredAmount, string memory _paymentId) public override onlyEOA {
        super.commit(_to, _declaredAmount, _paymentId);
    }

    function reveal(string memory _paymentId) public override onlyEOA {
        super.reveal(_paymentId);
    }

    function sponsoredReveal(string memory _paymentId) public override onlyPaymaster {
        super.reveal(_paymentId);
    }

    function reclaim(string memory _paymentId) public override onlyEOA {
        super.reclaim(_paymentId);
    }
}
