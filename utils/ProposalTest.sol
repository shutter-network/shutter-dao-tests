// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19;

import {Test, console2, stdStorage, StdStorage} from "forge-std/Test.sol";
import "forge-std/Vm.sol";
import "forge-std/StdJson.sol";
import {Azorius, IAzorius} from "@fractal-framework/fractal-contracts/contracts/azorius/Azorius.sol";
import {LinearERC20Voting} from "@fractal-framework/fractal-contracts/contracts/azorius/LinearERC20Voting.sol";
import {Enum} from "@gnosis.pm/safe-contracts/contracts/common/Enum.sol";
import {ERC20Votes} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {VestingPoolManager} from "../interfaces/VestingPoolManager.sol";
import {ShutterToken} from "../interfaces/ShutterToken.sol";

using stdJson for string;
using stdStorage for StdStorage;

contract AddressBook is Test {
    address public dao = 0x36bD3044ab68f600f6d3e081056F34f2a58432c4;
    Azorius public azorius =
        Azorius(0xAA6BfA174d2f803b517026E93DBBEc1eBa26258e);
    LinearERC20Voting public strategy =
        LinearERC20Voting(0x4b29d8B250B8b442ECfCd3a4e3D91933d2db720F);
    ShutterToken public shu =
        ShutterToken(0xe485E2f1bab389C08721B291f6b59780feC83Fd7);
    VestingPoolManager public vestingPoolManager =
        VestingPoolManager(0xD724DBe7e230E400fe7390885e16957Ec246d716);

    IERC20 public usdc = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    IERC20 public dai = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    IERC20 public sdai = IERC20(0x83F20F44975D03b1b09e64809B757c47f942BEeA);

    address public tailoredAgency = 0x4a356947348d1d17d8989E54720b4e76cb2857e1;
    address public artis = 0x1530f792f85b9935f865d5de7e8cB9B0bca90C25;
    address public brainbot = 0xB476Ee7D610DAe7B23B671EBC7Bd6112E9772969;

    constructor() {
        vm.label(dao, "dao");
        vm.label(address(azorius), "azorius");
        vm.label(address(strategy), "strategy");
        vm.label(address(shu), "shu");
        vm.label(address(vestingPoolManager), "vestingPoolManager");
        vm.label(tailoredAgency, "tailoredAgency");
        vm.label(artis, "artis");
        vm.label(brainbot, "brainbot");
    }
}

abstract contract ProposalTest is Test, AddressBook {
    struct Transaction {
        bytes data;
        Enum.Operation operation;
        address to;
        uint256 value;
    }

    struct Proposal {
        string metadata;
        address strategy;
        Transaction[] transactions;
    }

    address public voter;

    function proposalFile() public pure virtual returns (string memory) {}

    function setUp() public virtual {
        initializeVoter();
        Proposal memory proposal = loadProposal(proposalFile());
        uint32 proposalId = submitProposal(proposal);
        voteOnProposal(proposalId);
        executeProposal(proposal, proposalId);
        resetVoter();
    }

    function initializeVoter() public {
        voter = makeAddr("voter");
        vm.label(voter, "voter");

        uint256 n = shu.totalSupply();
        uint256 qNum = strategy.quorumNumerator();
        uint256 qDenom = strategy.QUORUM_DENOMINATOR();
        uint256 amount = (n * (qDenom + qNum) * qNum + 2 * qDenom - 2) /
            qDenom /
            qDenom;
        stdstore
            .target(address(shu))
            .sig("balanceOf(address)")
            .with_key(voter)
            .checked_write(amount);
        stdstore.target(address(shu)).sig("totalSupply()").checked_write(
            n + amount
        );

        vm.startPrank(voter);
        shu.delegate(voter);
        vm.stopPrank();
        vm.roll(block.number + 1);
    }

    function resetVoter() public {
        uint256 totalSupply = shu.totalSupply() - shu.balanceOf(voter);
        stdstore
            .target(address(shu))
            .sig("balanceOf(address)")
            .with_key(voter)
            .checked_write(uint256(0));
        stdstore.target(address(shu)).sig("totalSupply()").checked_write(
            totalSupply
        );
    }

    function loadProposal(
        string memory filename
    ) public view returns (Proposal memory) {
        string memory root = vm.projectRoot();
        string memory path = string.concat(
            root,
            "/encoded_proposals/",
            filename
        );
        string memory json = vm.readFile(path);
        bytes memory proposalEncoded = json.parseRaw(".");
        Proposal memory proposal = abi.decode(proposalEncoded, (Proposal));
        console2.log("value", proposal.transactions[0].value);
        require(proposal.strategy == address(strategy), "unknown strategy");
        return proposal;
    }

    function submitProposal(Proposal memory proposal) public returns (uint32) {
        uint256 n = proposal.transactions.length;
        Azorius.Transaction[] memory transactions = new Azorius.Transaction[](
            n
        );
        for (uint256 i = 0; i < n; i++) {
            Transaction memory transaction = proposal.transactions[i];
            transactions[i] = IAzorius.Transaction(
                transaction.to,
                transaction.value,
                transaction.data,
                Enum.Operation.Call
            );
        }

        uint32 expectedProposalId = uint32(azorius.totalProposalCount());
        vm.startPrank(address(voter));
        azorius.submitProposal(
            proposal.strategy,
            "",
            transactions,
            proposal.metadata
        );
        vm.stopPrank();
        vm.roll(block.number + 1);
        return expectedProposalId;
    }

    function voteOnProposal(uint32 proposalId) public {
        vm.startPrank(voter);
        strategy.vote(proposalId, uint8(LinearERC20Voting.VoteType.YES));
        vm.stopPrank();
    }

    function executeProposal(
        Proposal memory proposal,
        uint32 proposalId
    ) public {
        (, , , , uint256 endBlock, ) = strategy.getProposalVotes(proposalId);
        vm.roll(endBlock + 1);

        address[] memory targets = new address[](proposal.transactions.length);
        uint256[] memory values = new uint256[](proposal.transactions.length);
        bytes[] memory data = new bytes[](proposal.transactions.length);
        Enum.Operation[] memory operations = new Enum.Operation[](
            proposal.transactions.length
        );
        for (uint256 i = 0; i < proposal.transactions.length; i++) {
            targets[i] = proposal.transactions[i].to;
            values[i] = proposal.transactions[i].value;
            data[i] = proposal.transactions[i].data;
            operations[i] = proposal.transactions[i].operation;
        }
        vm.startPrank(voter);
        azorius.executeProposal(proposalId, targets, values, data, operations);
        vm.stopPrank();
    }
}
