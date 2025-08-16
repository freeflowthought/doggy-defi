// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {EventorHarness} from "src/EventorHarness.sol";
import {Eventor} from "src/Eventor.sol";
import {Paymaster} from "src/Paymaster.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IEventor} from "src/IEventor.sol";

IERC20 constant USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48); // on ethereum mainnet

// Helper contract to execute all operations in one transaction
contract PaymentExecutor {
    function executePayment(address eventor, address recipient, uint256 usdcAmount, string memory paymentId) external {
        // First call to execute - sets up transient state
        IEventor(eventor).commit(recipient, usdcAmount, paymentId);

        // Transfer USDC between the calls
        IERC20(USDC).transfer(recipient, usdcAmount);

        // Second call to execute - validates and emits event
        IEventor(eventor).reveal(recipient, usdcAmount, paymentId);
    }

    function executeSponsoredPayment(
        address eventor,
        address recipient,
        uint256 usdcAmount,
        string memory paymentId,
        address paymaster
    ) external {
        // First call to execute - sets up transient state
        IEventor(eventor).commit(recipient, usdcAmount, paymentId);

        // Transfer USDC between the calls
        IERC20(USDC).transfer(recipient, usdcAmount);

        // Second call to execute - validates and emits event
        Paymaster(payable(paymaster)).sponsoredReveal(recipient, usdcAmount, paymentId);
    }
}

contract EventorTest is Test {
    EventorHarness public eventor;
    PaymentExecutor public paymentExecutor;

    address public constant USDC_HOLDER = 0x87555C010f5137141ca13b42855d90a108887005;
    address public constant RECIPIENT = address(0x123);
    uint256 public constant PAYMENT_AMOUNT = 1e6; // 1 USDC (6 decimals)

    // Helper function to create paymentId with USDC amount in first 16 bytes
    function createPaymentId(uint256 usdcAmount) internal pure returns (string memory) {
        // Encode USDC amount in first 16 bytes, rest can be random/hash
        bytes16 amountBytes = bytes16(uint128(usdcAmount));
        bytes16 randomBytes = bytes16(keccak256("test_payment"));
        return string(abi.encodePacked(amountBytes, randomBytes));
    }

    function setUp() public virtual {
        // Fork mainnet at a recent block
        vm.createSelectFork("https://ethereum-rpc.publicnode.com");

        // Deploy contracts
        eventor = new EventorHarness(USDC);
        paymentExecutor = new PaymentExecutor();

        // Give recipient some initial ETH for the balance check
        vm.deal(RECIPIENT, 1 ether);
    }

    function test_EventorDoubleCall() public {
        // Use the USDC holder as the caller (must be EOA)
        vm.startPrank(USDC_HOLDER, USDC_HOLDER); // tx.origin = USDC_HOLDER

        // Check initial balances
        uint256 initialUsdcBalance = USDC.balanceOf(USDC_HOLDER);
        require(initialUsdcBalance >= PAYMENT_AMOUNT, "USDC holder doesn't have enough USDC");

        // Create paymentId with USDC amount in first 16 bytes
        string memory paymentId = createPaymentId(PAYMENT_AMOUNT);

        // Transfer USDC to the PaymentExecutor so it can make the transfers
        USDC.transfer(address(paymentExecutor), PAYMENT_AMOUNT);

        // Expect the ConfirmedPayment event (amount will be 0 since no ETH transferred)
        vm.expectEmit(true, true, false, true);
        emit IEventor.ConfirmedPayment(RECIPIENT, PAYMENT_AMOUNT, paymentId);

        // Execute the payment (all operations in one transaction)
        paymentExecutor.executePayment(address(eventor), RECIPIENT, PAYMENT_AMOUNT, paymentId);

        // Verify USDC was transferred
        assertEq(USDC.balanceOf(RECIPIENT), PAYMENT_AMOUNT, "Recipient should receive USDC");
        assertEq(USDC.balanceOf(USDC_HOLDER), initialUsdcBalance - PAYMENT_AMOUNT, "Sender should have less USDC");

        vm.stopPrank();
    }

    function test_EventorOnlyEOA() public {
        vm.startPrank(USDC_HOLDER, USDC_HOLDER); // tx.origin = USDC_HOLDER
        USDC.transfer(address(paymentExecutor), PAYMENT_AMOUNT);
        Eventor notHarnessEventor = new Eventor(USDC, address(0));
        vm.expectRevert(IEventor.OnlyEOA.selector);
        paymentExecutor.executePayment(
            address(notHarnessEventor), RECIPIENT, PAYMENT_AMOUNT, createPaymentId(PAYMENT_AMOUNT)
        );
        vm.stopPrank();
    }
}

contract EventorPaymasterTest is EventorTest {
    Eventor public eventorWithPaymaster;
    Paymaster public paymaster;

    function setUp() public override {
        super.setUp();
        eventorWithPaymaster = new Eventor(USDC, address(this));
        paymaster = new Paymaster(IEventor(address(eventorWithPaymaster)));
        eventorWithPaymaster.setPaymaster(address(paymaster));
    }

    function test_sponsoredReveal() public {
        vm.startPrank(USDC_HOLDER, USDC_HOLDER);

        uint256 initialUsdcBalance = USDC.balanceOf(USDC_HOLDER);
        require(initialUsdcBalance >= PAYMENT_AMOUNT, "USDC holder doesn't have enough USDC");

        string memory paymentId = createPaymentId(PAYMENT_AMOUNT);

        USDC.transfer(address(paymentExecutor), PAYMENT_AMOUNT);

        vm.expectEmit(true, true, false, true);
        emit IEventor.ConfirmedPayment(RECIPIENT, PAYMENT_AMOUNT, paymentId);

        paymentExecutor.executeSponsoredPayment(
            address(eventorWithPaymaster), RECIPIENT, PAYMENT_AMOUNT, paymentId, address(paymaster)
        );

        assertEq(USDC.balanceOf(RECIPIENT), PAYMENT_AMOUNT, "Recipient should receive USDC");
        assertEq(USDC.balanceOf(USDC_HOLDER), initialUsdcBalance - PAYMENT_AMOUNT, "Sender should have less USDC");

        vm.stopPrank();
    }

    function test_sponsoredReveal_notPaymaster() public {
        vm.startPrank(USDC_HOLDER, USDC_HOLDER);

        USDC.transfer(address(paymentExecutor), PAYMENT_AMOUNT);

        vm.expectRevert(IEventor.OnlyPaymaster.selector);
        paymentExecutor.executeSponsoredPayment(
            address(eventorWithPaymaster),
            RECIPIENT,
            PAYMENT_AMOUNT,
            createPaymentId(PAYMENT_AMOUNT),
            address(this) // using 'this' as paymaster, which is not the registered one
        );

        vm.stopPrank();
    }
}
