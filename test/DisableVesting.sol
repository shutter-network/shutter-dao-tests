// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19;

import { ProposalTest } from "../utils/ProposalTest.sol";

contract DisableVesting is ProposalTest {
  function proposalFile() public pure override returns (string memory) {
    return "DisableVesting.json";
  }

  function setUp() public override {
    super.setUp();
  }

  function testEnabledModules() public view {
    (address[] memory modules, address next) = safe.getModulesPaginated(
      0x0000000000000000000000000000000000000001,
      10
    );
    assert(next == 0x0000000000000000000000000000000000000001);
    assert(modules.length == 1);
    assert(modules[0] == address(azorius));

    assert(safe.isModuleEnabled(address(azorius)));
  }
}
