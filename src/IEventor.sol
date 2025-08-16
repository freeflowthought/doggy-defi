// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

interface IEventor {
    struct Commitment {
        address to;
        uint256 declaredAmount;
        uint256 balanceBefore;
        uint256 createdAt;
        bool revealed;
    }

    event Committed(bytes32 indexed commitmentHash, address indexed to, uint256 declaredAmount);
    event Revealed(bytes32 indexed commitmentHash, address indexed to, uint256 amount, string paymentId);
    event Reclaimed(bytes32 indexed commitmentHash, address indexed to);
    event ConfirmedPayment(address indexed to, uint256 indexed amount, string paymentId);

    error AlreadyCommitted();
    error NotCommitted();
    error AlreadyRevealed();
    error OnlyEOA();
    error InvalidTo();
    error NoFundsReceived();
    error InvalidDeclaredAmount(uint256 expected, uint256 actual);
    error OnlyPaymaster();
    error OnlyOwner();
    error CommitmentExpired();
    error CommitmentNotExpired();

    function commit(address _to, uint256 _declaredAmount, string memory _paymentId) external;

    function reveal(string memory _paymentId) external;

    function sponsoredReveal(string memory _paymentId) external;

    function reclaim(string memory _paymentId) external;
}
