// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.19;

import { ProposalTest } from "../utils/ProposalTest.sol";
import { VestingPool } from "../interfaces/VestingPool.sol";
import { VestingUtils } from "../utils/Vesting.sol";
import { Vm } from "forge-std/Vm.sol";
import { console2 } from "forge-std/Test.sol";

contract Brainbot1Test is ProposalTest {
  function proposalFile() public pure override returns (string memory) {
    return "Brainbot1.json";
  }

  uint256 daoSHUBefore;
  uint256 daoUSDCBefore;
  uint256 brainbotUSDCBefore;

  function setUp() public override {
    daoSHUBefore = shu.balanceOf(dao);
    daoUSDCBefore = usdc.balanceOf(dao);
    brainbotUSDCBefore = usdc.balanceOf(brainbot);

    vm.recordLogs();
    super.setUp();
  }

  function testBrainbotUSDC() public {
    assertEq(usdc.balanceOf(brainbot), brainbotUSDCBefore + 600_000 * 10 ** 6);
  }

  function testDAOUSDC() public {
    assertEq(usdc.balanceOf(dao), daoUSDCBefore - 600_000 * 10 ** 6);
  }

  function testDAOSHU() public {
    assertEq(shu.balanceOf(dao), daoSHUBefore - 200_000 ether);
  }

  function testBrainbotVesting() public {
    VestingPool vestingPool = VestingPool(
      vestingPoolManager.getVestingPool(brainbot)
    );

    Vm.Log[] memory logs = vm.getRecordedLogs();
    bytes32[] memory vestingIds = VestingUtils.getAddedVestingIds(
      logs,
      vestingPool
    );
    assertEq(vestingIds.length, 1);
    bytes32 vestingId = vestingIds[0];
    VestingUtils.Vesting memory vesting = VestingUtils.getVesting(
      vestingPool,
      vestingId
    );

    assertEq(vesting.initialUnlock, 200_000 ether);
    assertEq(vesting.curveType, 0);
    assertEq(vesting.managed, false);
    assertEq(vesting.durationWeeks, 1);
    assertEq(vesting.startDate, 1743465600);
    assertEq(vesting.amount, 200_000 ether);
    assertEq(vesting.amountClaimed, 0);
    assertEq(vesting.pausingDate, 0);
    assertEq(vesting.cancelled, false);
    assertEq(vesting.requiresSPT, false);

    vm.warp(vesting.startDate);
    uint256 shuBalanceBefore = shu.balanceOf(brainbot);
    vm.startPrank(brainbot);
    vestingPool.claimVestedTokens(vestingId, brainbot, type(uint128).max);
    vm.stopPrank();
    assertEq(shu.balanceOf(brainbot), shuBalanceBefore + 200_000 ether);
  }
}
