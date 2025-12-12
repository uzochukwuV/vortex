// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./PlatformToken.sol";

/// @title Governance Contract
/// @notice On-chain governance for protocol parameter changes
/// @dev Token-weighted voting with time-locked execution
contract Governance is ReentrancyGuard {
    /// @notice Proposal metadata
    struct ProposalCore {
        address proposer;
        uint256 startBlock;
        uint256 endBlock;
        uint256 eta;
        bool executed;
        bool canceled;
    }

    /// @notice Proposal vote counts
    struct ProposalVotes {
        uint256 forVotes;
        uint256 againstVotes;
        uint256 abstainVotes;
    }

    /// @notice Vote receipt
    struct Receipt {
        bool hasVoted;
        uint8 support; // 0 = against, 1 = for, 2 = abstain
        uint256 votes;
    }

    /// @notice Proposal state enum
    enum ProposalState {
        Pending,
        Active,
        Canceled,
        Defeated,
        Succeeded,
        Queued,
        Expired,
        Executed
    }

    /// @notice Platform token for voting
    PlatformToken public immutable token;

    /// @notice Proposal counter
    uint256 public proposalCount;

    /// @notice Proposal core data
    mapping(uint256 => ProposalCore) public proposalCore;

    /// @notice Proposal vote data
    mapping(uint256 => ProposalVotes) public proposalVotes;

    /// @notice Proposal descriptions
    mapping(uint256 => string) public proposalTitles;
    mapping(uint256 => string) public proposalDescriptions;

    /// @notice Proposal actions
    mapping(uint256 => address[]) public proposalTargets;
    mapping(uint256 => bytes[]) public proposalCalldatas;

    /// @notice Vote receipts (proposalId => voter => receipt)
    mapping(uint256 => mapping(address => Receipt)) public receipts;

    /// @notice Voting delay (blocks to wait before voting starts)
    uint256 public votingDelay = 1; // ~12 seconds on Base

    /// @notice Voting period (blocks)
    uint256 public votingPeriod = 50400; // ~7 days on Base (12s blocks)

    /// @notice Proposal threshold (tokens required to create proposal)
    uint256 public proposalThreshold = 100000 * 10**18; // 100k tokens

    /// @notice Quorum (minimum votes required)
    uint256 public quorumVotes = 10_000_000 * 10**18; // 10M tokens (1% of supply)

    /// @notice Timelock delay (seconds to wait before execution)
    uint256 public timelockDelay = 2 days;

    /// @notice Maximum timelock delay
    uint256 public constant MAX_TIMELOCK_DELAY = 30 days;

    /// @notice Minimum timelock delay
    uint256 public constant MIN_TIMELOCK_DELAY = 1 days;

    /// @notice Guardian address (can cancel proposals)
    address public guardian;

    /// @notice Events
    event ProposalCreated(
        uint256 indexed id,
        address indexed proposer,
        string title,
        uint256 startBlock,
        uint256 endBlock
    );

    event VoteCast(
        address indexed voter,
        uint256 indexed proposalId,
        uint8 support,
        uint256 votes
    );

    event ProposalQueued(uint256 indexed id, uint256 eta);
    event ProposalExecuted(uint256 indexed id);
    event ProposalCanceled(uint256 indexed id);

    /// @param _token Platform token address
    /// @param _guardian Guardian address
    constructor(address _token, address _guardian) {
        require(_token != address(0), "Invalid token");
        require(_guardian != address(0), "Invalid guardian");

        token = PlatformToken(_token);
        guardian = _guardian;
    }

    /// @notice Create a new proposal
    /// @param title Proposal title
    /// @param description Proposal description
    /// @param targets Contract addresses to call
    /// @param calldatas Function calls with parameters
    function propose(
        string memory title,
        string memory description,
        address[] memory targets,
        bytes[] memory calldatas
    ) external returns (uint256) {
        require(
            token.balanceOf(msg.sender) >= proposalThreshold,
            "Below proposal threshold"
        );
        require(targets.length == calldatas.length, "Arity mismatch");
        require(targets.length > 0, "Empty proposal");
        require(targets.length <= 10, "Too many actions");

        uint256 proposalId = ++proposalCount;

        proposalCore[proposalId] = ProposalCore({
            proposer: msg.sender,
            startBlock: block.number + votingDelay,
            endBlock: block.number + votingDelay + votingPeriod,
            eta: 0,
            executed: false,
            canceled: false
        });

        proposalVotes[proposalId] = ProposalVotes({
            forVotes: 0,
            againstVotes: 0,
            abstainVotes: 0
        });

        proposalTitles[proposalId] = title;
        proposalDescriptions[proposalId] = description;
        proposalTargets[proposalId] = targets;
        proposalCalldatas[proposalId] = calldatas;

        emit ProposalCreated(
            proposalId,
            msg.sender,
            title,
            proposalCore[proposalId].startBlock,
            proposalCore[proposalId].endBlock
        );

        return proposalId;
    }

    /// @notice Cast a vote
    /// @param proposalId Proposal ID
    /// @param support Vote type (0 = against, 1 = for, 2 = abstain)
    function castVote(uint256 proposalId, uint8 support) external nonReentrant {
        require(support <= 2, "Invalid vote type");
        _castVote(msg.sender, proposalId, support);
    }

    /// @notice Internal vote casting
    function _castVote(address voter, uint256 proposalId, uint8 support) internal {
        require(state(proposalId) == ProposalState.Active, "Voting is closed");

        Receipt storage receipt = receipts[proposalId][voter];
        require(!receipt.hasVoted, "Already voted");

        uint256 votes = token.balanceOf(voter);
        require(votes > 0, "No voting power");

        ProposalVotes storage pVotes = proposalVotes[proposalId];

        if (support == 0) {
            pVotes.againstVotes += votes;
        } else if (support == 1) {
            pVotes.forVotes += votes;
        } else {
            pVotes.abstainVotes += votes;
        }

        receipt.hasVoted = true;
        receipt.support = support;
        receipt.votes = votes;

        emit VoteCast(voter, proposalId, support, votes);
    }

    /// @notice Queue a successful proposal for execution
    /// @param proposalId Proposal ID
    function queue(uint256 proposalId) external {
        require(
            state(proposalId) == ProposalState.Succeeded,
            "Proposal not succeeded"
        );

        ProposalCore storage core = proposalCore[proposalId];
        core.eta = block.timestamp + timelockDelay;

        emit ProposalQueued(proposalId, core.eta);
    }

    /// @notice Execute a queued proposal
    /// @param proposalId Proposal ID
    function execute(uint256 proposalId) external nonReentrant {
        require(
            state(proposalId) == ProposalState.Queued,
            "Proposal not queued"
        );

        ProposalCore storage core = proposalCore[proposalId];
        require(block.timestamp >= core.eta, "Timelock not expired");
        require(
            block.timestamp <= core.eta + 14 days,
            "Proposal expired"
        );

        core.executed = true;

        address[] memory targets = proposalTargets[proposalId];
        bytes[] memory calldatas = proposalCalldatas[proposalId];

        for (uint256 i = 0; i < targets.length; i++) {
            (bool success, ) = targets[i].call(calldatas[i]);
            require(success, "Execution failed");
        }

        emit ProposalExecuted(proposalId);
    }

    /// @notice Cancel a proposal
    /// @param proposalId Proposal ID
    function cancel(uint256 proposalId) external {
        ProposalCore storage core = proposalCore[proposalId];

        // Only proposer or guardian can cancel
        require(
            msg.sender == core.proposer ||
            msg.sender == guardian,
            "Not authorized"
        );

        require(
            state(proposalId) != ProposalState.Executed,
            "Cannot cancel executed proposal"
        );

        // Proposer can only cancel if below threshold
        if (msg.sender == core.proposer) {
            require(
                token.balanceOf(core.proposer) < proposalThreshold,
                "Proposer above threshold"
            );
        }

        core.canceled = true;

        emit ProposalCanceled(proposalId);
    }

    /// @notice Get proposal state
    /// @param proposalId Proposal ID
    function state(uint256 proposalId) public view returns (ProposalState) {
        require(proposalId > 0 && proposalId <= proposalCount, "Invalid proposal");

        ProposalCore memory core = proposalCore[proposalId];
        ProposalVotes memory votes = proposalVotes[proposalId];

        if (core.canceled) {
            return ProposalState.Canceled;
        } else if (block.number <= core.startBlock) {
            return ProposalState.Pending;
        } else if (block.number <= core.endBlock) {
            return ProposalState.Active;
        } else if (votes.forVotes <= votes.againstVotes || votes.forVotes < quorumVotes) {
            return ProposalState.Defeated;
        } else if (core.eta == 0) {
            return ProposalState.Succeeded;
        } else if (core.executed) {
            return ProposalState.Executed;
        } else if (block.timestamp >= core.eta + 14 days) {
            return ProposalState.Expired;
        } else {
            return ProposalState.Queued;
        }
    }

    /// @notice Get proposal details
    /// @param proposalId Proposal ID
    function getProposal(uint256 proposalId)
        external
        view
        returns (
            address proposer,
            string memory title,
            string memory description,
            uint256 forVotes,
            uint256 againstVotes,
            uint256 startBlock,
            uint256 endBlock
        )
    {
        ProposalCore memory core = proposalCore[proposalId];
        ProposalVotes memory votes = proposalVotes[proposalId];

        return (
            core.proposer,
            proposalTitles[proposalId],
            proposalDescriptions[proposalId],
            votes.forVotes,
            votes.againstVotes,
            core.startBlock,
            core.endBlock
        );
    }

    /// @notice Get proposal actions
    /// @param proposalId Proposal ID
    function getProposalActions(uint256 proposalId)
        external
        view
        returns (
            address[] memory targets,
            bytes[] memory calldatas
        )
    {
        return (
            proposalTargets[proposalId],
            proposalCalldatas[proposalId]
        );
    }

    /// @notice Get vote receipt
    /// @param proposalId Proposal ID
    /// @param voter Voter address
    function getReceipt(uint256 proposalId, address voter)
        external
        view
        returns (
            bool hasVoted,
            uint8 support,
            uint256 votes
        )
    {
        Receipt memory receipt = receipts[proposalId][voter];
        return (receipt.hasVoted, receipt.support, receipt.votes);
    }

    /// @notice Set voting delay (guardian only)
    /// @param newDelay New delay in blocks
    function setVotingDelay(uint256 newDelay) external {
        require(msg.sender == guardian, "Only guardian");
        require(newDelay >= 1, "Delay too low");
        votingDelay = newDelay;
    }

    /// @notice Set voting period (guardian only)
    /// @param newPeriod New period in blocks
    function setVotingPeriod(uint256 newPeriod) external {
        require(msg.sender == guardian, "Only guardian");
        require(newPeriod >= 5760, "Period too low"); // At least 1 day
        require(newPeriod <= 100800, "Period too high"); // At most 14 days
        votingPeriod = newPeriod;
    }

    /// @notice Set proposal threshold (guardian only)
    /// @param newThreshold New threshold
    function setProposalThreshold(uint256 newThreshold) external {
        require(msg.sender == guardian, "Only guardian");
        proposalThreshold = newThreshold;
    }

    /// @notice Set quorum votes (guardian only)
    /// @param newQuorum New quorum
    function setQuorumVotes(uint256 newQuorum) external {
        require(msg.sender == guardian, "Only guardian");
        quorumVotes = newQuorum;
    }

    /// @notice Set timelock delay (guardian only)
    /// @param newDelay New delay in seconds
    function setTimelockDelay(uint256 newDelay) external {
        require(msg.sender == guardian, "Only guardian");
        require(
            newDelay >= MIN_TIMELOCK_DELAY && newDelay <= MAX_TIMELOCK_DELAY,
            "Invalid delay"
        );
        timelockDelay = newDelay;
    }

    /// @notice Set guardian (current guardian only)
    /// @param newGuardian New guardian address
    function setGuardian(address newGuardian) external {
        require(msg.sender == guardian, "Only guardian");
        require(newGuardian != address(0), "Invalid guardian");
        guardian = newGuardian;
    }
}
