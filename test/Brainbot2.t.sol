// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19;

import { ProposalTest } from "../utils/ProposalTest.sol";
import { LockupTranched } from "@sablier/v2-core/src/types/DataTypes.sol";
import { Vm } from "forge-std/Vm.sol";
import { console2 } from "forge-std/Test.sol";

contract Brainbot2Test is ProposalTest {
  function proposalFile() public pure override returns (string memory) {
    return "Brainbot2.json";
  }

  uint256 daoUSDCBalanceBefore;
  uint256 daoGLOBalanceBefore;
  uint256 brainbotUSDCBalanceBefore;
  uint256 brainbotGLOBalanceBefore;

  function setUp() public override {
    daoUSDCBalanceBefore = usdc.balanceOf(dao);
    daoGLOBalanceBefore = glo.balanceOf(dao);
    brainbotUSDCBalanceBefore = usdc.balanceOf(brainbot2);
    brainbotGLOBalanceBefore = glo.balanceOf(brainbot2);

    super.setUp();
  }

  function testTransfers() public {
    assert(usdc.balanceOf(dao) == daoUSDCBalanceBefore - 200_000 * 10 ** 6);
    assert(glo.balanceOf(dao) == daoGLOBalanceBefore - 33_000 * 10 ** 18);

    assert(
      usdc.balanceOf(brainbot2) == brainbotUSDCBalanceBefore + 200_000 * 10 ** 6
    );
    assert(
      glo.balanceOf(brainbot2) == brainbotGLOBalanceBefore + 33_000 * 10 ** 18
    );
  }
}
