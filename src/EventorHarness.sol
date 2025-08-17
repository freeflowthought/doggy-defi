// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IEventor} from "src/IEventor.sol";
import {ReentrancyGuardUpgradeable} from "openzeppelin-contracts-upgradeable/contracts/utils/ReentrancyGuardUpgradeable.sol";

// This contract is used to test the Eventor contract as it doesn't have onlyEOA modifier.
contract EventorHarness is IEventor, ReentrancyGuardUpgradeable {
    uint256 public constant TIMEOUT = 1 hours;
    mapping(bytes32 => Commitment) public commitments;

    IERC20 public immutable USDC;

    constructor(IERC20 _USDC) {
        USDC = _USDC;
    }

    function commit(address _to, uint256 _declaredAmount, string memory _paymentId)
        public
        virtual
        nonReentrant
    {
        bytes32 commitmentHash = keccak256(abi.encodePacked(_paymentId));
        if (commitments[commitmentHash].createdAt != 0) {
            revert AlreadyCommitted();
        }

        commitments[commitmentHash] = Commitment({
            to: _to,
            declaredAmount: _declaredAmount,
            balanceBefore: USDC.balanceOf(_to),
            createdAt: block.timestamp,
            revealed: false
        });

        emit Committed(commitmentHash, _to, _declaredAmount);
    }

    function reveal(string memory _paymentId) public virtual nonReentrant {
        bytes32 commitmentHash = keccak256(abi.encodePacked(_paymentId));
        Commitment storage commitment = commitments[commitmentHash];

        if (commitment.createdAt == 0) {
            revert NotCommitted();
        }
        if (commitment.revealed) {
            revert AlreadyRevealed();
        }
        if (block.timestamp > commitment.createdAt + TIMEOUT) {
            revert CommitmentExpired();
        }

        uint256 amount = USDC.balanceOf(commitment.to) - commitment.balanceBefore;
        if (amount == 0) {
            revert NoFundsReceived();
        }
        if (amount != commitment.declaredAmount) {
            revert InvalidDeclaredAmount(commitment.declaredAmount, amount);
        }

        commitment.revealed = true;

        emit Revealed(commitmentHash, commitment.to, amount, _paymentId);
        emit ConfirmedPayment(commitment.to, amount, _paymentId);
    }

    function sponsoredReveal(string memory _paymentId) public virtual {
        reveal(_paymentId);
    }
    

    /// @notice Allows the original committer to "reclaim" a payment commitment if it has expired and has not been revealed. This function is used to clear out expired commitments from the system.
    /// @param _paymentId The unique identifier of the payment commitment to be reclaimed.
    function reclaim(string memory _paymentId) public virtual nonReentrant {
        bytes32 commitmentHash = keccak256(abi.encodePacked(_paymentId));
        Commitment storage commitment = commitments[commitmentHash];

        if (commitment.createdAt == 0) {
            revert NotCommitted();
        }
        if (commitment.revealed) {
            revert AlreadyRevealed();
        }
        if (block.timestamp <= commitment.createdAt + TIMEOUT) {
            revert CommitmentNotExpired();
        }

        emit Reclaimed(commitmentHash, commitment.to);
    }
}
