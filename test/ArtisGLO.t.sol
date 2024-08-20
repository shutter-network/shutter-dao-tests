// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19;

import { ProposalTest } from "../utils/ProposalTest.sol";
import { VestingPool } from "../interfaces/VestingPool.sol";
import { VestingUtils } from "../utils/Vesting.sol";
import { Vm } from "forge-std/Vm.sol";
import { console2 } from "forge-std/Test.sol";

contract ArtisGLOTest is ProposalTest {
  function proposalFile() public pure override returns (string memory) {
    return "ArtisGLO.json";
  }

  uint256 daoUSDCBefore;
  uint256 artisUSDCBefore;

  function setUp() public override {
    daoUSDCBefore = usdc.balanceOf(dao);
    artisUSDCBefore = usdc.balanceOf(artis2);

    vm.recordLogs();
    super.setUp();
  }

  function testBalances() public {
    assertEq(usdc.balanceOf(dao), daoUSDCBefore - 301_000 * 10 ** 6);
    assertEq(usdc.balanceOf(artis2), artisUSDCBefore + 301_000 * 10 ** 6);
  }
}
