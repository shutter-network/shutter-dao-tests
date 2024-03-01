// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.19;

import { ProposalTest } from "../utils/ProposalTest.sol";
import { VestingPool } from "../interfaces/VestingPool.sol";
import { VestingUtils } from "../utils/Vesting.sol";
import { Vm } from "forge-std/Vm.sol";
import { console2 } from "forge-std/Test.sol";

contract Proposal1Test is ProposalTest {
    function proposalFile() public pure override returns (string memory) {
        return "Proposal1.json";
    }

    uint256 daoSHUBefore;
    uint256 daoUSDCBefore;
    uint256 tailoredAgencyUSDCBefore;
    uint256 artisUSDCBefore;

    function setUp() public override {
        daoSHUBefore = shu.balanceOf(dao);
        daoUSDCBefore = usdc.balanceOf(dao);
        tailoredAgencyUSDCBefore = usdc.balanceOf(tailoredAgency);
        artisUSDCBefore = usdc.balanceOf(artis);

        vm.recordLogs();
        super.setUp();
    }

    function testArtisUSDC() public {
        assertEq(usdc.balanceOf(artis), artisUSDCBefore + 5_000 * 10**6);
    }

    function testTailoredAgencyUSDC() public {
        assertEq(usdc.balanceOf(tailoredAgency), tailoredAgencyUSDCBefore + 15_000 * 10**6);
    }

    function testDAOUSDC() public {
        assertEq(usdc.balanceOf(dao), daoUSDCBefore - 20_000 * 10**6);
    }

    function testDAOSHU() public {
        assertEq(shu.balanceOf(dao), daoSHUBefore - 450_000 ether);
    }

    function testArtisVesting() public {
        VestingPool vestingPool = VestingPool(vestingPoolManager.getVestingPool(artis));

        Vm.Log[] memory logs = vm.getRecordedLogs();
        bytes32[] memory vestingIds = VestingUtils.getAddedVestingIds(logs, vestingPool);
        assertEq(vestingIds.length, 1);
        bytes32 vestingId = vestingIds[0];
        VestingUtils.Vesting memory vesting = VestingUtils.getVesting(vestingPool, vestingId);

        assertEq(vesting.initialUnlock, 30_000 ether);
        assertEq(vesting.curveType, 0);
        assertEq(vesting.managed, false);
        assertEq(vesting.durationWeeks, 103);
        assertEq(vesting.startDate, 1710720000);
        assertEq(vesting.amount, 300_000 ether);
        assertEq(vesting.amountClaimed, 0);
        assertEq(vesting.pausingDate, 0);
        assertEq(vesting.cancelled, false);
        assertEq(vesting.requiresSPT, false);

        vm.warp(vesting.startDate);
        uint256 shuBalanceBefore = shu.balanceOf(artis);
        vm.startPrank(artis);
        vestingPool.claimVestedTokens(vestingId, artis, type(uint128).max);
        vm.stopPrank();
        assertEq(shu.balanceOf(artis), shuBalanceBefore + 30_000 ether);
    }

    function testTailoredAgencyVesting() public {
        VestingPool vestingPool = VestingPool(vestingPoolManager.getVestingPool(tailoredAgency));

        Vm.Log[] memory logs = vm.getRecordedLogs();
        bytes32[] memory vestingIds = VestingUtils.getAddedVestingIds(logs, vestingPool);
        assertEq(vestingIds.length, 1);
        bytes32 vestingId = vestingIds[0];
        VestingUtils.Vesting memory vesting = VestingUtils.getVesting(vestingPool, vestingId);

        assertEq(vesting.initialUnlock, 150_000 ether);
        assertEq(vesting.curveType, 0);
        assertEq(vesting.managed, false);
        assertEq(vesting.durationWeeks, 1);
        assertEq(vesting.startDate, 1710720000);
        assertEq(vesting.amount, 150_000 ether);
        assertEq(vesting.amountClaimed, 0);
        assertEq(vesting.pausingDate, 0);
        assertEq(vesting.cancelled, false);
        assertEq(vesting.requiresSPT, false);

        vm.warp(vesting.startDate);
        uint256 shuBalanceBefore = shu.balanceOf(tailoredAgency);
        vm.startPrank(tailoredAgency);
        vestingPool.claimVestedTokens(vestingId, tailoredAgency, type(uint128).max);
        vm.stopPrank();
        assertEq(shu.balanceOf(tailoredAgency), shuBalanceBefore + 150_000 ether);
    }
}
