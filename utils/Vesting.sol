// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19;

import { Vm } from "forge-std/Vm.sol";
import { VestingPool } from "../interfaces/VestingPool.sol";

library VestingUtils {

    // Copied from https://github.com/shutter-network/shutter-dao/blob/c4e1cdbab306f013fb1d4e7698b9ea74bbdb4f8d/contracts/libraries/VestingLibrary.sol
    struct Vesting {
        // First storage slot
        uint128 initialUnlock; // 16 bytes -> Max 3.4e20 tokens (including decimals)
        uint8 curveType; // 1 byte -> Max 256 different curve types
        bool managed; // 1 byte
        uint16 durationWeeks; // 2 bytes -> Max 65536 weeks ~ 1260 years
        uint64 startDate; // 8 bytes -> Works until year 292278994, but not before 1970
        // Second storage slot
        uint128 amount; // 16 bytes -> Max 3.4e20 tokens (including decimals)
        uint128 amountClaimed; // 16 bytes -> Max 3.4e20 tokens (including decimals)
        // Third storage slot
        uint64 pausingDate; // 8 bytes -> Works until year 292278994, but not before 1970
        bool cancelled; // 1 byte
        bool requiresSPT; // 1 byte
    }

    function getAddedVestingIds(Vm.Log[] memory logs, VestingPool vestingPool) public pure returns (bytes32[] memory) {
        bytes32[] memory vestingIds = new bytes32[](logs.length);
        uint256 n = 0;
        for (uint256 i = 0; i < logs.length; i++) {
            if (logs[i].emitter == address(vestingPool)) {
                if (logs[i].topics[0] != keccak256("AddedVesting(bytes32)")) {
                    continue;
                }
                assert(logs[i].topics.length == 2);
                vestingIds[n] = logs[i].topics[1];
                n += 1;
            }
        }
        bytes32[] memory result = new bytes32[](n);
        for (uint256 i = 0; i < n; i++) {
            result[i] = vestingIds[i];
        }
        return result;
    }

    function getVesting(VestingPool vestingPool, bytes32 vestingId) public view returns (Vesting memory) {
        Vesting memory vesting;
        (
            vesting.initialUnlock,
            vesting.curveType,
            vesting.managed,
            vesting.durationWeeks,
            vesting.startDate,
            vesting.amount,
            vesting.amountClaimed,
            vesting.pausingDate,
            vesting.cancelled,
            vesting.requiresSPT
        ) = vestingPool.vestings(vestingId);
        return vesting;
    }
}
