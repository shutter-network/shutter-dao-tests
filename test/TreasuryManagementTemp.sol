// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19;

import { ProposalTest } from "../utils/ProposalTest.sol";
import { Vm } from "forge-std/Vm.sol";
import { console2 } from "forge-std/Test.sol";

contract TreasuryManagementTemp is ProposalTest {
  function proposalFile() public pure override returns (string memory) {
    return "TreasuryManagementTemp.json";
  }

  uint256 daoDAIBefore;
  uint256 daoUSDCBefore;
  uint256 daoSDAIBefore;

  function setUp() public override {
    daoDAIBefore = dai.balanceOf(dao);
    daoUSDCBefore = usdc.balanceOf(dao);
    daoSDAIBefore = sdai.balanceOf(dao);

    vm.recordLogs();
    super.setUp();
  }

  function testBalanceDifferences() public {
    assertEq(dai.balanceOf(dao), daoDAIBefore);
    assertEq(usdc.balanceOf(dao), daoUSDCBefore - 3_000_000 * 10 ** 6);
    assert(sdai.balanceOf(dao) > daoSDAIBefore + 2_500_000 * 10 ** 18);
  }

  function testAllowances() public {
    assertEq(usdc.allowance(dao, address(sdai)), 0);
    assertEq(dai.allowance(dao, 0x0A59649758aa4d66E25f08Dd01271e891fe52199), 0);
  }
}
