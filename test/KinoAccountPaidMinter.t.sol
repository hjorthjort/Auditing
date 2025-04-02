// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.27;

import {SystemDeployment} from "./SystemDeployment.t.sol";
import {Kimap} from "../src/kimap/Kimap.sol";
import {KinoAccountPaidMinter} from "../src/account/KinoAccountPaidMinter.sol";
import {IKinoAccountMinter} from "../src/interfaces/IKinoAccountMinter.sol";
import {IKinoAccountPaid} from "../src/interfaces/IKinoAccountPaid.sol";
import {KinoAccount} from "../src/account/KinoAccount.sol";

contract KinoAccountPaidMinterTest is SystemDeployment {
    Kimap internal kimap;
    address internal minterImpl;
    address internal basicKinoAccountImpl;
    address internal owner = address(1);
    address internal safe = address(255);
    IKinoAccountMinter internal mintedTba;
    uint256 internal constant INITIAL_PRICE = 0.01 ether;

    function setUp() public {
        kimap = deployKimap(address(this));

        // Deploy default KinoAccount implementation
        basicKinoAccountImpl = address(new KinoAccount());

        // Deploy KinoAccountPaidMinter implementation
        minterImpl = address(new KinoAccountPaidMinter(address(kimap)));
        address mintedTbaAddress;
        (mintedTbaAddress,) = callMint(
            kimap,
            address(this),
            zeroTba,
            "test",
            abi.encodeWithSelector(KinoAccountPaidMinter.initialize.selector, INITIAL_PRICE),
            minterImpl
        );
        mintedTba = IKinoAccountMinter(mintedTbaAddress);
    }

    function testInitialPrice() public view {
        assertEq(KinoAccountPaidMinter(payable(address(mintedTba))).currentPrice(), INITIAL_PRICE);
    }

    function testSetPriceAsOperator() public {
        uint256 newPrice = 0.02 ether;
        KinoAccountPaidMinter(payable(address(mintedTba))).setPrice(newPrice);
        assertEq(KinoAccountPaidMinter(payable(address(mintedTba))).currentPrice(), newPrice);
    }

    function testSetPriceAsNonOperator() public {
        uint256 newPrice = 0.02 ether;
        vm.prank(address(1));
        vm.expectRevert();
        KinoAccountPaidMinter(payable(address(mintedTba))).setPrice(newPrice);
    }

    function testSetPriceToZero() public {
        vm.expectRevert(KinoAccountPaidMinter.InvalidPrice.selector);
        KinoAccountPaidMinter(payable(address(mintedTba))).setPrice(0);
    }

    function testMintWithCorrectPayment() public {
        bytes memory name = "test-paid-mint";
        address mintedAddress = IKinoAccountMinter(payable(address(mintedTba))).mint{value: INITIAL_PRICE}(
            address(this), name, hex"", basicKinoAccountImpl
        );
        assertTrue(mintedAddress != address(0));
    }

    function testMintWithInsufficientPayment() public {
        bytes memory name = "test-paid-mint";
        vm.expectRevert(KinoAccountPaidMinter.IncorrectPayment.selector);
        IKinoAccountMinter(payable(address(mintedTba))).mint{value: INITIAL_PRICE - 1}(
            address(this), name, hex"", basicKinoAccountImpl
        );
    }

    function testMintWithExcessPayment() public {
        bytes memory name = "test-paid-mint";
        vm.expectRevert(KinoAccountPaidMinter.IncorrectPayment.selector);
        IKinoAccountMinter(payable(address(mintedTba))).mint{value: INITIAL_PRICE + 1}(
            address(this), name, hex"", basicKinoAccountImpl
        );
    }

    function testWithdrawAsOperator() public {
        // First mint to add funds
        bytes memory name = "test-paid-mint";
        IKinoAccountMinter(payable(address(mintedTba))).mint{value: INITIAL_PRICE}(
            address(this), name, hex"", basicKinoAccountImpl
        );

        uint256 initialBalance = address(this).balance;
        KinoAccountPaidMinter(payable(address(mintedTba))).withdraw();
        assertEq(address(this).balance, initialBalance + INITIAL_PRICE);
        assertEq(address(mintedTba).balance, 0);
    }

    function testWithdrawAsNonOperator() public {
        // First mint to add funds
        bytes memory name = "test-paid-mint";
        IKinoAccountMinter(payable(address(mintedTba))).mint{value: INITIAL_PRICE}(
            address(this), name, hex"", basicKinoAccountImpl
        );

        vm.prank(address(1));
        vm.expectRevert();
        KinoAccountPaidMinter(payable(address(mintedTba))).withdraw();
    }

    function testWithdrawWithNoBalance() public {
        vm.expectRevert(KinoAccountPaidMinter.WithdrawFailed.selector);
        KinoAccountPaidMinter(payable(address(mintedTba))).withdraw();
    }

    function testPriceUpdateEvent() public {
        uint256 newPrice = 0.02 ether;
        vm.expectEmit(true, true, true, true);
        emit PriceUpdated(INITIAL_PRICE, newPrice);
        KinoAccountPaidMinter(payable(address(mintedTba))).setPrice(newPrice);
    }

    receive() external payable {}

    event PriceUpdated(uint256 oldPrice, uint256 newPrice);
}
