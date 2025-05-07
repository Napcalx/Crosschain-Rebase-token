//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {RebaseToken} from "../src/RebaseToken.sol";
import {Vault} from "../src/Vault.sol";
import {IRebaseToken} from "../src/interface/IRebaseToken.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

contract RebaseTokenTest is Test {
    RebaseToken private rebaseToken;
    Vault private vault;

    address public owner = makeAddr("owner");
    address public user = makeAddr("user");

    function setUp() public {
        vm.startPrank(owner);
        rebaseToken = new RebaseToken();
        vault = new Vault(IRebaseToken(address(rebaseToken)));
        rebaseToken.grantMintAndBurnRole(address(vault));
        (bool success, ) = payable(address(vault)).call{value: 1e18}("");
        vm.stopPrank();
    }

    function addRewardToVault(uint256 rewardAmount) public {
        (bool succes, ) = payable(address(vault)).call{value: rewardAmount}("");
    }

    function testDepositLinear(uint256 amount) public {
        vm.assume(amount > 1e4);
        amount = bound(amount, 1e5, type(uint96).max);
        // 1. depoist
        vm.startPrank(user);
        vm.deal(user, amount);
        vault.deposit{value: amount}();
        // 2. check our rebase token balance
        uint256 startBalance = rebaseToken.balanceOf(user);
        console.log("startBalance", startBalance);
        assertEq(startBalance, amount);
        // 3. warp time and check the balance again
        vm.warp(block.timestamp + 1.5 hours);
        uint256 midBalance = rebaseToken.balanceOf(user);
        assertGt(midBalance, startBalance);
        // 4. warp time again by the same amount and chekc the balance again
        vm.warp(block.timestamp + 1.5 hours);
        uint256 endBalance = rebaseToken.balanceOf(user);
        assertGt(endBalance, midBalance);

        assertApproxEqAbs(
            endBalance - midBalance,
            midBalance - startBalance,
            1
        );
        vm.stopPrank();
    }

    function testCanRedeemImmediately(uint256 amount) public {
        amount = bound(amount, 1e5, type(uint96).max);
        // 1. deposit
        vm.startPrank(user);
        vm.deal(user, amount);
        vault.deposit{value: amount}();
        assertEq(rebaseToken.balanceOf(user), amount);
        // 2. redeem
        vault.redeem(type(uint256).max);
        assertEq(rebaseToken.balanceOf(user), 0);
        assertEq(address(user).balance, amount);
        vm.stopPrank();
    }

    function testCanRedeemAfterTimePassed(uint256 amount, uint256 time) public {
        time = bound(time, 1000, type(uint96).max);
        amount = bound(amount, 1e5, type(uint96).max);
        // 1. deposit
        vm.deal(user, amount);
        vm.prank(user);
        vault.deposit{value: amount}();
        // 2. warp time
        vm.warp(block.timestamp + time);
        uint256 balanceAfterAWhile = rebaseToken.balanceOf(user);
        vm.deal(owner, balanceAfterAWhile - amount);
        vm.prank(owner);
        addRewardToVault(balanceAfterAWhile - amount);
        // 3. redeem
        vm.prank(user);
        vault.redeem(type(uint256).max);

        uint256 ethBalance = address(user).balance;

        assertEq(ethBalance, balanceAfterAWhile);
        assertGt(ethBalance, amount);
    }

    function testTransfer(uint256 amount, uint256 amountToSend) public {
        amount = bound(amount, 1e5 + 1e5, type(uint96).max);
        amountToSend = bound(amountToSend, 1e5, amount - 1e5);

        // Deposit
        vm.deal(user, amount);
        vm.prank(user);
        vault.deposit{value: amount}();

        address userN = makeAddr("userN");
        uint256 userBalance = rebaseToken.balanceOf(user);
        uint256 userNBalance = rebaseToken.balanceOf(userN);
        assertEq(userBalance, amount);
        assertEq(userNBalance, 0);

        vm.prank(owner);
        rebaseToken.setInterestRate(4e10);

        // transfer
        vm.prank(user);
        rebaseToken.transfer(userN, amountToSend);
        uint256 userBalanceAfter = rebaseToken.balanceOf(user);
        uint256 userNBalanceAfter = rebaseToken.balanceOf(userN);
        assertEq(userBalanceAfter, userBalance - amountToSend);
        assertEq(userNBalanceAfter, amountToSend);

        // check the user interest rate has been inherited
        assertEq(rebaseToken.getUserInterestRate(user), 5e10);
        assertEq(rebaseToken.getUserInterestRate(userN), 5e10);
    }

    function testCannotSetInterestRate(uint256 newInterestRate) public {
        vm.prank(user);
        vm.expectPartialRevert(Ownable.OwnableUnauthorizedAccount.selector);
        rebaseToken.setInterestRate(newInterestRate);
    }

    function testCannotCallMintAndBurn() public {
        vm.prank(user);
        vm.expectPartialRevert(
            IAccessControl.AccessControlUnauthorizedAccount.selector
        );
        rebaseToken.mint(user, 200, rebaseToken.getInterestRate());
        vm.expectPartialRevert(
            IAccessControl.AccessControlUnauthorizedAccount.selector
        );
        rebaseToken.burn(user, 150);
    }

    function testPrincipalAmount(uint256 amount) public {
        amount = bound(amount, 1e5, type(uint96).max);
        vm.deal(user, amount);
        vm.prank(user);
        vault.deposit{value: amount}();
        assertEq(rebaseToken.getPrincipleBalanceOf(user), amount);

        vm.warp(block.timestamp + 1.5 hours);
        assertEq(rebaseToken.getPrincipleBalanceOf(user), amount);
    }

    function testGetRebaseTokenAddress() public view {
        assertEq(vault.getRebaseTokenAddress(), address(rebaseToken));
    }

    function testInterestRateCanOnlyDecrease(uint256 newInterestRate) public {
        uint256 initInterestRate = rebaseToken.getInterestRate();
        newInterestRate = bound(
            newInterestRate,
            initInterestRate,
            type(uint96).max
        );
        vm.prank(owner);
        vm.expectPartialRevert(
            RebaseToken.RebaseToken__InterestRateCanOnlyDecrease.selector
        );
        rebaseToken.setInterestRate(newInterestRate);
        assertEq(rebaseToken.getInterestRate(), initInterestRate);
    }

    function testTransferMintsAccruedInterestToBothUsers(
        uint256 mintAmount,
        uint256 amountSent
    ) public {
        mintAmount = bound(mintAmount, 1e5 + 1e5, type(uint96).max);
        amountSent = bound(amountSent, 1e5, mintAmount - 1e5);
        vm.deal(user, mintAmount);
        vm.prank(user);
        vault.deposit{value: mintAmount}();

        address user2 = makeAddr("user2");
        uint256 userBalance = rebaseToken.balanceOf(user);
        uint256 user2Balance = rebaseToken.balanceOf(user2);
        assertEq(userBalance, mintAmount);
        assertEq(user2Balance, 0);

        vm.warp(block.timestamp + 1.5 hours);
        vm.prank(user);
        rebaseToken.transfer(user2, amountSent);

        assertEq(
            rebaseToken.getUserInterestRate(user),
            rebaseToken.getUserInterestRate(user2)
        );
    }

    function testTransferFromWithAllowance(uint256 allowance) public {
        allowance = bound(allowance, 1e5, type(uint96).max);

        vm.deal(owner, allowance);
        vm.prank(owner);
        vault.deposit{value: allowance}();

        vm.prank(owner);
        rebaseToken.approve(user, allowance);

        address user1 = makeAddr("user1");

        uint256 ownerBalance = rebaseToken.balanceOf(owner);
        uint256 user1Balance = rebaseToken.balanceOf(user1);
        uint256 userAllowanceBefore = rebaseToken.allowance(owner, user);

        vm.prank(user);
        rebaseToken.transferFrom(owner, user1, allowance);

        uint256 ownerBalanceAfter = rebaseToken.balanceOf(owner);
        uint256 user1BalanceAfter = rebaseToken.balanceOf(user1);
        uint256 userAllowanceAfter = rebaseToken.allowance(owner, user);

        // Assert the balances and allowance are updated correctly
        assertEq(ownerBalanceAfter, ownerBalance - allowance);
        assertEq(user1BalanceAfter, user1Balance + allowance);
        assertEq(userAllowanceAfter, userAllowanceBefore - allowance);
    }

    function testTransferFromWithMaxUintAllowance(
        uint256 depositAmount,
        uint256 amountSent
    ) public {
        depositAmount = bound(depositAmount, 1e5 + 1e5, type(uint96).max);
        amountSent = bound(amountSent, 1e5, depositAmount - 1e5);

        // fund owner with Eth and Deposit into vault
        vm.deal(owner, depositAmount);
        vm.prank(owner);
        vault.deposit{value: depositAmount}();

        // Approve spender with Max uint256 allowance
        vm.prank(owner);
        rebaseToken.approve(user, type(uint256).max);

        address user1 = makeAddr("user1");
        uint256 ownerBalance = rebaseToken.balanceOf(owner);
        uint256 user1Balance = rebaseToken.balanceOf(user1);
        uint256 userAllowanceBefore = rebaseToken.allowance(owner, user);
        console.log("Owner's Balance", ownerBalance);
        console.log("User1 Balance", user1Balance);
        console.log("User's Allowance Before", userAllowanceBefore);

        vm.prank(user);
        rebaseToken.transferFrom(owner, user1, amountSent);

        uint256 ownerBalanceAfter = rebaseToken.balanceOf(owner);
        uint256 user1BalanceAfter = rebaseToken.balanceOf(user1);
        uint256 userAllowanceAfter = rebaseToken.allowance(owner, user);

        // Assert the balances and allowance are updated correctly
        assertEq(ownerBalanceAfter, ownerBalance - amountSent);
        assertEq(user1BalanceAfter, user1Balance + amountSent);

        //If allowance was uint256.max, it should not reduce
        assertEq(userAllowanceAfter, type(uint256).max);
    }

    function testTransferWithMaxAmount(uint256 depositAmount) public {
        depositAmount = bound(depositAmount, 1e5, type(uint96).max);

        vm.deal(user, depositAmount);
        vm.prank(user);
        vault.deposit{value: depositAmount}();

        address user1 = makeAddr("user1");
        vm.prank(user);
        rebaseToken.transfer(user1, type(uint256).max);

        uint256 userBalance = rebaseToken.balanceOf(user);
        uint256 user1Balance = rebaseToken.balanceOf(user1);

        assertEq(userBalance, 0);
        assertEq(user1Balance, depositAmount);
    }

    function testTransferFromWithMaxUintAmount(uint256 amount) public {
        amount = bound(amount, 1e5, type(uint96).max);

        vm.deal(owner, amount);
        vm.prank(owner);
        vault.deposit{value: amount}();

        vm.prank(owner);
        rebaseToken.approve(user, type(uint256).max);
        address user1 = makeAddr("user1");

        uint256 ownerBalance = rebaseToken.balanceOf(owner);
        uint256 user1Balance = rebaseToken.balanceOf(user1);

        vm.prank(user);
        rebaseToken.transferFrom(owner, user1, type(uint256).max);

        uint256 ownerBalanceAfter = rebaseToken.balanceOf(owner);
        uint256 user1BalanceAfter = rebaseToken.balanceOf(user1);

        // Assert the balances and allowance are updated correctly
        assertEq(ownerBalanceAfter, ownerBalance - amount);
        assertEq(user1BalanceAfter, user1Balance + amount);
    }

    function testRedeemFailsIfEthTransferFails(uint256 amount) public {
        amount = bound(amount, 1e5, type(uint96).max);
        RevertingReceiver badReceiver = new RevertingReceiver();

        // Give it some RebaseTokens
        vm.deal(address(badReceiver), 0);
        vm.deal(address(this), amount);

        // Deposit from this contract and transfer to badReceiver
        vault.deposit{value: amount}();
        rebaseToken.transfer(address(badReceiver), amount);

        // Try redeeming from badReceiver
        vm.expectRevert(Vault.Vault__RedeemFailed.selector);
        vm.prank(address(badReceiver));
        vault.redeem(type(uint256).max);
    }
}

contract RevertingReceiver {
    // fallback that rejects ETH

    receive() external payable {
        revert("Can't accept ETH");
    }
}
