// SPDX-License-Identifier: CC-BY-NC-4.0
pragma solidity ^0.8.0;

import {Test} from "@forge-std/Test.sol";
import {MockERC20} from "@test/mocks/MockERC20.sol";
import {FundShareVault} from "@src/modules/deposit/FundShareVault.sol";

contract TestFundShareVault is Test {
    MockERC20 internal mockToken;
    FundShareVault internal fundShareVault;

    function setUp() public {
        mockToken = new MockERC20(18);
    }

    function test_constructor(uint8 decimalsOffset) public {
        vm.assume(decimalsOffset <= 18);
        fundShareVault =
            new FundShareVault(address(mockToken), "Fund Share Vault", "FSV", decimalsOffset);
        assertEq(fundShareVault.controller(), address(this));
        assertEq(fundShareVault.decimalsOffset(), decimalsOffset);
    }

    error OwnableUnauthorizedAccount(address account);

    function test_only_owner_can_deposit(address other) public {
        vm.assume(other != address(this));
        vm.assume(other != address(0));
        vm.assume(other != address(fundShareVault));
        vm.assume(other != address(mockToken));

        fundShareVault = new FundShareVault(address(mockToken), "Fund Share Vault", "FSV", 0);
        mockToken.mint(other, 1000000);
        vm.startPrank(other);
        mockToken.approve(address(fundShareVault), 1000000);
        vm.expectRevert(abi.encodeWithSelector(OwnableUnauthorizedAccount.selector, other));
        fundShareVault.deposit(1000000, address(this));
        vm.stopPrank();
    }

    function test_only_owner_can_withdraw(address other) public {
        vm.assume(other != address(this));
        vm.assume(other != address(0));
        vm.assume(other != address(fundShareVault));
        vm.assume(other != address(mockToken));

        fundShareVault = new FundShareVault(address(mockToken), "Fund Share Vault", "FSV", 0);
        mockToken.mint(other, 1000000);
        vm.startPrank(other);
        mockToken.approve(address(fundShareVault), 1000000);
        vm.expectRevert(abi.encodeWithSelector(OwnableUnauthorizedAccount.selector, other));
        fundShareVault.withdraw(1000000, address(this), address(this));
        vm.stopPrank();
    }

    function test_only_owner_can_mint_unbacked(address other) public {
        vm.assume(other != address(this));
        vm.assume(other != address(0));
        vm.assume(other != address(fundShareVault));
        vm.assume(other != address(mockToken));

        fundShareVault = new FundShareVault(address(mockToken), "Fund Share Vault", "FSV", 0);
        vm.expectRevert(abi.encodeWithSelector(OwnableUnauthorizedAccount.selector, other));
        vm.prank(other);
        fundShareVault.mintUnbacked(1000000, other);
    }
}
