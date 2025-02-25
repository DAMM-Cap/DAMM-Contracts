// SPDX-License-Identifier: CC-BY-NC-4.0
pragma solidity ^0.8.0;

import {TestBaseDeposit} from "./TestBaseDeposit.sol";
import {AssetPolicy} from "@src/modules/deposit/Structs.sol";
import {IDepositModule} from "@src/interfaces/IDepositModule.sol";
import {Errors} from "@src/libs/Errors.sol";
import "@src/libs/Constants.sol";

contract TestDepositModule is TestBaseDeposit {
    function setUp() public override(TestBaseDeposit) {
        TestBaseDeposit.setUp();

        vm.startPrank(address(fund));
        balanceOfOracle.addBalanceToValuate(address(mockToken1), address(fund));
        balanceOfOracle.addBalanceToValuate(address(mockToken2), address(fund));
        vm.stopPrank();
    }

    function test_deposit(uint256 amount)
        public
        withRole(alice, DEPOSITOR_ROLE)
        maxApproveDepositModule(alice, address(mockToken1))
    {
        amount = bound(
            amount,
            depositModule.getGlobalAssetPolicy(address(mockToken1)).minimumDeposit + 1,
            type(uint192).max
        );
        mockToken1.mint(alice, amount);

        vm.prank(alice);
        (uint256 sharesOut, uint256 liquidity) =
            depositModule.deposit(address(mockToken1), amount, 0, alice);

        assertEq(mockToken1.balanceOf(address(fund)), amount, "fund balance wrong");
        assertEq(mockToken1.balanceOf(address(alice)), 0, "alice balance wrong");
        assertEq(internalVault.totalAssets(), amount, "total assets wrong");
        assertEq(internalVault.totalSupply(), internalVault.balanceOf(alice), "total supply wrong");
        assertEq(sharesOut, internalVault.balanceOf(alice), "shares out wrong");
        assertEq(internalVault.totalAssets(), liquidity, "liquidity wrong");
    }

    function test_cannot_deposit_amount_that_is_below_minimum_deposit(uint256 amount)
        public
        withRole(alice, DEPOSITOR_ROLE)
        maxApproveDepositModule(alice, address(mockToken1))
    {
        amount = bound(
            amount, 1, depositModule.getGlobalAssetPolicy(address(mockToken1)).minimumDeposit - 1
        );

        vm.startPrank(alice);
        vm.expectRevert(Errors.Deposit_InsufficientDeposit.selector);
        depositModule.deposit(address(mockToken1), amount, 0, alice);
        vm.stopPrank();
    }

    function test_cannot_deposit_zero_amount() public withRole(alice, DEPOSITOR_ROLE) {
        vm.startPrank(alice);
        vm.expectRevert(Errors.Deposit_InsufficientDeposit.selector);
        depositModule.deposit(address(mockToken1), 0, 0, alice);
        vm.stopPrank();
    }

    function test_deposit_slippage_limit_is_exceeded(uint256 amount)
        public
        withRole(alice, DEPOSITOR_ROLE)
        maxApproveDepositModule(alice, address(mockToken1))
    {
        amount = bound(
            amount,
            depositModule.getGlobalAssetPolicy(address(mockToken1)).minimumDeposit + 1,
            type(uint192).max
        );

        mockToken1.mint(alice, amount);

        vm.startPrank(alice);
        vm.expectRevert(Errors.Deposit_SlippageLimitExceeded.selector);
        depositModule.deposit(address(mockToken1), amount, amount * 10e2, alice);
        vm.stopPrank();
    }

    function test_withdraw(uint256 amount)
        public
        withRole(alice, DEPOSITOR_ROLE)
        withRole(alice, WITHDRAWER_ROLE)
        maxApproveDepositModule(alice, address(mockToken1))
        maxApproveDepositModule(alice, address(internalVault))
    {
        vm.assume(
            amount > depositModule.getGlobalAssetPolicy(address(mockToken1)).minimumDeposit + 1
        );
        vm.assume(
            amount > depositModule.getGlobalAssetPolicy(address(mockToken1)).minimumWithdrawal + 1
        );
        vm.assume(amount < type(uint192).max);
        mockToken1.mint(alice, amount);

        vm.prank(alice);
        depositModule.deposit(address(mockToken1), amount, 0, alice);

        uint256 currentLiquidity = internalVault.totalAssets();

        vm.startPrank(alice);
        (uint256 assetAmountOut, uint256 liquidity) =
            depositModule.withdraw(address(mockToken1), internalVault.balanceOf(alice), 0, alice);
        vm.stopPrank();

        assertApproxEqAbs(mockToken1.balanceOf(alice), amount, precisionLoss, "alice balance wrong");
        assertApproxEqAbs(assetAmountOut, amount, precisionLoss, "asset amount out wrong");
        assertApproxEqAbs(
            mockToken1.balanceOf(address(fund)), 0, precisionLoss, "fund balance wrong"
        );
        assertEq(internalVault.totalAssets(), 0, "total assets wrong");
        assertEq(internalVault.totalSupply(), 0, "total supply wrong");
        assertEq(liquidity, currentLiquidity, "liquidity wrong");
    }

    function test_cannot_withdraw_amount_that_is_below_minimum_withdrawal()
        public
        withRole(alice, DEPOSITOR_ROLE)
        withRole(alice, WITHDRAWER_ROLE)
        maxApproveDepositModule(alice, address(mockToken1))
        maxApproveDepositModule(alice, address(internalVault))
    {
        mockToken1.mint(alice, type(uint160).max);

        vm.prank(alice);
        depositModule.deposit(address(mockToken1), type(uint160).max, 0, alice);

        vm.startPrank(alice);
        vm.expectRevert(Errors.Deposit_InsufficientWithdrawal.selector);
        depositModule.withdraw(address(mockToken1), 1, 0, alice);
        vm.stopPrank();
    }

    function test_cannot_withdraw_zero_amount() public withRole(alice, WITHDRAWER_ROLE) {
        vm.startPrank(alice);
        vm.expectRevert(Errors.Deposit_InsufficientWithdrawal.selector);
        depositModule.withdraw(address(mockToken1), 0, 0, alice);
        vm.stopPrank();
    }

    function test_withdraw_slippage_limit_is_exceeded(uint256 amount)
        public
        withRole(alice, DEPOSITOR_ROLE)
        withRole(alice, WITHDRAWER_ROLE)
        maxApproveDepositModule(alice, address(mockToken1))
        maxApproveDepositModule(alice, address(internalVault))
    {
        vm.assume(
            amount > depositModule.getGlobalAssetPolicy(address(mockToken1)).minimumDeposit + 1
        );
        vm.assume(amount < type(uint192).max);

        mockToken1.mint(alice, amount);

        vm.prank(alice);
        (uint256 sharesOut, uint256 liquidity) =
            depositModule.deposit(address(mockToken1), amount, 0, alice);

        vm.startPrank(alice);
        vm.expectRevert(Errors.Deposit_SlippageLimitExceeded.selector);
        depositModule.withdraw(address(mockToken1), sharesOut, amount + 1, alice);
        vm.stopPrank();
    }

    function test_dilute(uint256 amount) public withRole(alice, DILUTER_ROLE) {
        amount = bound(amount, 1, type(uint256).max);

        vm.prank(alice);
        depositModule.dilute(amount, alice);

        assertEq(internalVault.totalAssets(), 0);
        assertEq(internalVault.totalSupply(), amount);
    }

    function test_enable_global_asset_policy(AssetPolicy memory policy, address asset) public {
        vm.assume(asset != address(0));
        vm.assume(asset != address(mockToken1));
        vm.assume(asset != address(mockToken2));

        assertFalse(depositModule.getGlobalAssetPolicy(asset).enabled);

        policy.enabled = true;

        vm.prank(address(fund));
        depositModule.enableGlobalAssetPolicy(asset, policy);

        assertTrue(depositModule.getGlobalAssetPolicy(asset).enabled);
        assertEq(depositModule.getGlobalAssetPolicy(asset).minimumDeposit, policy.minimumDeposit);
        assertEq(
            depositModule.getGlobalAssetPolicy(asset).minimumWithdrawal, policy.minimumWithdrawal
        );
        assertEq(depositModule.getGlobalAssetPolicy(asset).canDeposit, policy.canDeposit);
        assertEq(depositModule.getGlobalAssetPolicy(asset).canWithdraw, policy.canWithdraw);
    }

    function test_disable_global_asset_policy() public {
        assertTrue(depositModule.getGlobalAssetPolicy(address(mockToken1)).enabled);

        vm.prank(address(fund));
        depositModule.disableGlobalAssetPolicy(address(mockToken1));

        assertFalse(depositModule.getGlobalAssetPolicy(address(mockToken1)).enabled);
    }

    function test_upsert_global_asset_policy(
        AssetPolicy memory policy1,
        AssetPolicy memory policy2,
        address asset
    ) public {
        vm.assume(asset != address(0));
        vm.assume(asset != address(mockToken1));
        vm.assume(asset != address(mockToken2));

        policy1.enabled = true;
        policy2.enabled = true;

        vm.prank(address(fund));
        depositModule.enableGlobalAssetPolicy(asset, policy1);

        assertTrue(depositModule.getGlobalAssetPolicy(asset).enabled);
        assertEq(depositModule.getGlobalAssetPolicy(asset).minimumDeposit, policy1.minimumDeposit);
        assertEq(
            depositModule.getGlobalAssetPolicy(asset).minimumWithdrawal, policy1.minimumWithdrawal
        );
        assertEq(depositModule.getGlobalAssetPolicy(asset).canDeposit, policy1.canDeposit);
        assertEq(depositModule.getGlobalAssetPolicy(asset).canWithdraw, policy1.canWithdraw);

        vm.prank(address(fund));
        depositModule.enableGlobalAssetPolicy(asset, policy2);

        assertTrue(depositModule.getGlobalAssetPolicy(asset).enabled);
        assertEq(depositModule.getGlobalAssetPolicy(asset).minimumDeposit, policy2.minimumDeposit);
        assertEq(
            depositModule.getGlobalAssetPolicy(asset).minimumWithdrawal, policy2.minimumWithdrawal
        );
        assertEq(depositModule.getGlobalAssetPolicy(asset).canDeposit, policy2.canDeposit);
        assertEq(depositModule.getGlobalAssetPolicy(asset).canWithdraw, policy2.canWithdraw);
    }

    function test_pause() public {
        assertFalse(depositModule.paused());

        vm.prank(address(fund));
        depositModule.pause();

        assertTrue(depositModule.paused());

        vm.prank(address(fund));
        depositModule.unpause();

        assertFalse(depositModule.paused());
    }

    function test_set_pauser() public {
        assertFalse(depositModule.hasRole(PAUSER_ROLE, alice));

        vm.prank(address(fund));
        depositModule.setPauser(alice);

        assertTrue(depositModule.hasRole(PAUSER_ROLE, alice));
    }

    function test_revoke_pauser() public {
        assertFalse(depositModule.hasRole(PAUSER_ROLE, alice));

        vm.prank(address(fund));
        depositModule.setPauser(alice);

        assertTrue(depositModule.hasRole(PAUSER_ROLE, alice));

        vm.prank(address(fund));
        depositModule.revokePauser(alice);

        assertFalse(depositModule.hasRole(PAUSER_ROLE, alice));
    }

    function test_supports_interface() public view {
        assertTrue(depositModule.supportsInterface(type(IDepositModule).interfaceId));
    }
}
