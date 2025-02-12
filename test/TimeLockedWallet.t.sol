// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console2} from "forge-std/Test.sol";
import {TimeLockedWallet} from "../src/TimeLockedWallet.sol";

contract TimeLockedWalletTest is Test {
    TimeLockedWallet public wallet;
    address public owner;

    function setUp() public {
        owner = makeAddr("owner");
        vm.prank(owner);
        wallet = new TimeLockedWallet();
    }

    function testDeposit() public {
        uint256 depositAmount = 1 ether;
        vm.deal(address(this), depositAmount);

        wallet.deposit{value: depositAmount}();

        assertEq(address(wallet).balance, depositAmount);
        assertEq(wallet.totalBalance(), depositAmount);
    }

    function testReceiveFunction() public {
        uint256 depositAmount = 1 ether;
        vm.deal(address(this), depositAmount);

        (bool success,) = address(wallet).call{value: depositAmount}("");

        assertTrue(success);
        assertEq(address(wallet).balance, depositAmount);
        assertEq(wallet.totalBalance(), depositAmount);
    }

    function testWithdrawBeforeLockTime() public {
        uint256 depositAmount = 1 ether;
        uint256 lockDuration = 30 days;
        vm.deal(address(this), depositAmount);

        wallet.depositWithLock{value: depositAmount}(lockDuration);

        vm.expectRevert("Funds are still locked");
        wallet.withdraw(0);
    }

    function testWithdrawAfterLockTime() public {
        uint256 depositAmount = 1 ether;
        uint256 lockDuration = 30 days;
        vm.deal(address(this), depositAmount);

        wallet.depositWithLock{value: depositAmount}(lockDuration);

        vm.warp(block.timestamp + lockDuration + 1);

        uint256 balanceBefore = address(this).balance;
        wallet.withdraw(0);
        uint256 balanceAfter = address(this).balance;

        assertEq(balanceAfter - balanceBefore, depositAmount);
        assertEq(address(wallet).balance, 0);
        assertEq(wallet.totalBalance(), 0);
    }

    function testGetMyDeposits() public {
        uint256 depositAmount = 1 ether;
        uint256 lockDuration = 30 days;
        vm.deal(address(this), depositAmount * 2);

        wallet.depositWithLock{value: depositAmount}(lockDuration);
        wallet.depositWithLock{value: depositAmount}(lockDuration * 2);

        TimeLockedWallet.DepositInfo[] memory deposits = wallet.getMyDeposits();

        assertEq(deposits.length, 2);
        assertEq(deposits[0].amount, depositAmount);
        assertEq(deposits[1].amount, depositAmount);
        assertTrue(deposits[0].unlockTime < deposits[1].unlockTime);
    }

    function testGetWithdrawableDeposits() public {
        uint256 depositAmount = 1 ether;
        uint256 lockDuration = 30 days;
        vm.deal(address(this), depositAmount * 2);

        wallet.depositWithLock{value: depositAmount}(lockDuration);
        wallet.depositWithLock{value: depositAmount}(lockDuration * 2);

        vm.warp(block.timestamp + lockDuration + 1);

        uint256[] memory withdrawable = wallet.getMyWithdrawableDeposits();

        assertEq(withdrawable.length, 1);
        assertEq(withdrawable[0], 0);
    }

    function testMultipleWithdraws() public {
        uint256 depositAmount = 1 ether;
        uint256 lockDuration = 30 days;
        vm.deal(address(this), depositAmount * 2);

        wallet.depositWithLock{value: depositAmount}(lockDuration);
        wallet.depositWithLock{value: depositAmount}(lockDuration);

        vm.warp(block.timestamp + lockDuration + 1);

        wallet.withdraw(0);
        wallet.withdraw(1);

        assertEq(address(wallet).balance, 0);
        assertEq(wallet.totalBalance(), 0);
    }

    function testInvalidDepositIndex() public {
        vm.expectRevert("Invalid deposit index");
        wallet.withdraw(0);
    }

    function testDepositCount() public {
        uint256 depositAmount = 1 ether;
        uint256 lockDuration = 30 days;
        vm.deal(address(this), depositAmount * 3);

        assertEq(wallet.getMyDepositCount(), 0);

        wallet.depositWithLock{value: depositAmount}(lockDuration);
        wallet.depositWithLock{value: depositAmount}(lockDuration);
        wallet.depositWithLock{value: depositAmount}(lockDuration);

        assertEq(wallet.getMyDepositCount(), 3);
    }

    receive() external payable {}
}
