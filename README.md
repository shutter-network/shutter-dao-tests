# Shutter DAO Proposal Tests

This repository contains tests of proposals for Shutter DAO 0x36 which can be
run against mainnet. Executable tests make the effects of a proposal explicit
and verifiable, making it easier to check that a proposal does what it claims
to do.

## Installation

To get started, clone the repository and make sure the following dependencies
are installed:

- [forge](https://getfoundry.sh/)
- [npm](https://www.npmjs.com/)

Then, run `npm install` in the project root directory.

## Running Tests

To run the tests, the following environment variable has to be set (see for
instance `.envrc.example`):

- `FORK_URL`: The URL of an Ethereum mainnet JSON RPC provider

`make test` will prepare and execute the tests. Specify `FORGE_OPTS` to pass
options to forge, e.g., to filter the tests to run:
`make test FORGE_OPTS="--match-contract <test contract name>"`.

## Adding Tests

#### Specify the proposal

Add proposals as JSON files in the `proposals/` directory. They must have the
following format:

```json
{
  "strategy": "0x4b29d8B250B8b442ECfCd3a4e3D91933d2db720F",
  "transactions": [
    {
      "targetAddress": "",
      "functionName": "",
      "functionSignature": "",
      "parameters": "",
      "value": 0
    }
  ],
  "metadata": ""
}
```

- `strategy` defines the voting strategy of the proposal. As of now, Shutter
  DAO 0x36 only supports linear ERC20 voting defined by
  [0x4b29d8B250B8b442ECfCd3a4e3D91933d2db720F](https://etherscan.io/address/0x4b29d8B250B8b442ECfCd3a4e3D91933d2db720F).
- `transactions` is the list of "transactions" that will be executed when the
  proposal succeeds. The fields `targetAddress`, `functionName`,
  `functionSignature` and `parameters` contain the values entered in the
  [Create Proposal](https://docs.fractalframework.xyz/home/proposals/create)
  interface in Fractal. Pure value transfers are not currently supported and
  the `value` field should be left at `0`.
- `metadata` is ignored.

#### Write the test

Put the test files in the `test/` directory and name them according to the
corresponding proposal (e.g., if the proposal is called `BurnTokens.json`, the
file should be called `BurnTokens.t.sol`). The tests are standard
[foundry](https://getfoundry.sh) test contracts and should inherit from
`TestProposal` in `utils/ProposalTest.sol`. Each test contract should implement
the `proposalFile` function to specify the name of the proposal that is tested:

```solidity
contract Proposal1Test is ProposalTest {
    function proposalFile() public pure override returns (string memory) {
        return "BurnTokens.json";
    }

    function testTokensAreBurnt() public {
        // test code goes here
    }
```

The default `setUp` function defined in `ProposalTest` will submit the
proposal, vote on it, and execute it. I.e., the tests are run on top of the
state immediately after the proposal has been executed. If the proposal fails
to execute, the test will fail already in the `setUp` function. If you
override the `setUp` function, be sure to either call `super.setUp();` or
reimplement the same logic.
