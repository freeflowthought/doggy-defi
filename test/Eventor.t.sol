// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {EventorHarness} from "src/EventorHarness.sol";
import {Eventor} from "src/Eventor.sol";
import {Paymaster} from "src/Paymaster.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IEventor} from "src/IEventor.sol";

IERC20 constant USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48); // on ethereum mainnet

contract EventorTest is Test {
    EventorHarness public eventor;

    address public constant USDC_HOLDER = 0x87555C010f5137141ca13b42855d90a108887005;
    address public constant RECIPIENT = address(0x123);
    uint256 public constant PAYMENT_AMOUNT = 1e6; // 1 USDC (6 decimals)
    string public constant PAYMENT_ID = "test_payment";

    function setUp() public virtual {
        // Fork mainnet at a recent block
        vm.createSelectFork("https://ethereum-rpc.publicnode.com");

        // Deploy contracts
        eventor = new EventorHarness(USDC);

        // Give recipient some initial ETH for the balance check
        vm.deal(RECIPIENT, 1 ether);
    }

    function test_CommitReveal() public {
        vm.startPrank(USDC_HOLDER, USDC_HOLDER);

        uint256 initialUsdcBalance = USDC.balanceOf(USDC_HOLDER);
        require(initialUsdcBalance >= PAYMENT_AMOUNT, "USDC holder doesn't have enough USDC");

        // Commit
        eventor.commit(RECIPIENT, PAYMENT_AMOUNT, PAYMENT_ID);

        // Transfer USDC
        USDC.transfer(RECIPIENT, PAYMENT_AMOUNT);

        // Expect the ConfirmedPayment event
        vm.expectEmit(true, true, false, true);
        emit IEventor.ConfirmedPayment(RECIPIENT, PAYMENT_AMOUNT, PAYMENT_ID);

        // Reveal
        eventor.reveal(PAYMENT_ID);

        assertEq(USDC.balanceOf(RECIPIENT), PAYMENT_AMOUNT, "Recipient should receive USDC");
        assertEq(USDC.balanceOf(USDC_HOLDER), initialUsdcBalance - PAYMENT_AMOUNT, "Sender should have less USDC");

        vm.stopPrank();
    }

    function test_reclaim() public {
        vm.startPrank(USDC_HOLDER, USDC_HOLDER);

        eventor.commit(RECIPIENT, PAYMENT_AMOUNT, PAYMENT_ID);

        // Warp time to after the timeout
        vm.warp(block.timestamp + eventor.TIMEOUT() + 1);

        vm.expectEmit(true, true, false, true);
        emit IEventor.Reclaimed(keccak256(abi.encodePacked(PAYMENT_ID)), RECIPIENT);

        eventor.reclaim(PAYMENT_ID);

        vm.stopPrank();
    }

    function test_reveal_fails_after_timeout() public {
        vm.startPrank(USDC_HOLDER, USDC_HOLDER);

        eventor.commit(RECIPIENT, PAYMENT_AMOUNT, PAYMENT_ID);

        // Warp time to after the timeout
        vm.warp(block.timestamp + eventor.TIMEOUT() + 1);

        vm.expectRevert(IEventor.CommitmentExpired.selector);
        eventor.reveal(PAYMENT_ID);

        vm.stopPrank();
    }

    function test_EventorOnlyEOA() public {
        Eventor notHarnessEventor = new Eventor(USDC, address(0));
        vm.expectRevert(IEventor.OnlyEOA.selector);
        notHarnessEventor.commit(RECIPIENT, PAYMENT_AMOUNT, PAYMENT_ID);
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

        // Commit
        eventorWithPaymaster.commit(RECIPIENT, PAYMENT_AMOUNT, PAYMENT_ID);

        // Transfer USDC
        USDC.transfer(RECIPIENT, PAYMENT_AMOUNT);

        vm.stopPrank();

        vm.startPrank(address(paymaster));

        vm.expectEmit(true, true, false, true);
        emit IEventor.ConfirmedPayment(RECIPIENT, PAYMENT_AMOUNT, PAYMENT_ID);

        // Reveal
        paymaster.sponsoredReveal(RECIPIENT, PAYMENT_AMOUNT, PAYMENT_ID);

        assertEq(USDC.balanceOf(RECIPIENT), PAYMENT_AMOUNT, "Recipient should receive USDC");
        assertEq(USDC.balanceOf(USDC_HOLDER), initialUsdcBalance - PAYMENT_AMOUNT, "Sender should have less USDC");

        vm.stopPrank();
    }

    function test_sponsoredReveal_notPaymaster() public {
        vm.startPrank(USDC_HOLDER, USDC_HOLDER);

        eventorWithPaymaster.commit(RECIPIENT, PAYMENT_AMOUNT, PAYMENT_ID);

        vm.stopPrank();

        vm.startPrank(address(this));

        vm.expectRevert(IEventor.OnlyPaymaster.selector);
        eventorWithPaymaster.sponsoredReveal(PAYMENT_ID);

        vm.stopPrank();
    }
}
