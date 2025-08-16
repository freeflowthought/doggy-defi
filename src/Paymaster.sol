// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IEventor} from "src/IEventor.sol";

contract Paymaster {
    IEventor public immutable eventor;

    constructor(IEventor _eventor) {
        eventor = _eventor;
    }

    function sponsoredReveal(address _to, uint256 _declaredAmount, string memory _paymentId) external {
        eventor.sponsoredReveal(_paymentId);
    }

    receive() external payable {}
}
