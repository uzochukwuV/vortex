// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import "../interfaces/IAggregatorV3.sol";

/// @title Mock V3 Aggregator
/// @notice Mock Chainlink V3 Aggregator for testnet price feeds
/// @dev Implements IAggregatorV3 interface for testing
contract MockV3Aggregator is IAggregatorV3 {
    uint8 public override decimals;
    string public override description;
    uint256 public override version = 1;

    int256 private _latestAnswer;
    uint80 private _latestRound;
    uint256 private _latestTimestamp;

    mapping(uint80 => int256) private _answers;
    mapping(uint80 => uint256) private _timestamps;
    mapping(uint80 => uint256) private _startedAt;

    /// @notice Constructor to initialize the mock aggregator
    /// @param decimals_ Number of decimals for the price feed
    /// @param initialAnswer Initial price answer
    constructor(uint8 decimals_, int256 initialAnswer) {
        decimals = decimals_;
        description = "Mock Chainlink Aggregator";
        _updateAnswer(initialAnswer);
    }

    /// @notice Get data about the latest round
    function latestRoundData()
        external
        view
        override
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        return (
            _latestRound,
            _latestAnswer,
            _latestTimestamp,
            _latestTimestamp,
            _latestRound
        );
    }

    /// @notice Get data about a specific round
    function getRoundData(uint80 roundId_)
        external
        view
        override
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        return (
            roundId_,
            _answers[roundId_],
            _startedAt[roundId_],
            _timestamps[roundId_],
            roundId_
        );
    }

    /// @notice Update the latest answer (for testing)
    /// @param answer New price answer
    function updateAnswer(int256 answer) external {
        _updateAnswer(answer);
    }

    /// @notice Update answer with specific round ID and timestamp
    /// @param roundId Round ID to update
    /// @param answer Price answer
    /// @param timestamp Timestamp for the round
    /// @param startedAt Started timestamp for the round
    function updateRoundData(
        uint80 roundId,
        int256 answer,
        uint256 timestamp,
        uint256 startedAt
    ) external {
        _latestRound = roundId;
        _latestAnswer = answer;
        _latestTimestamp = timestamp;
        _answers[roundId] = answer;
        _timestamps[roundId] = timestamp;
        _startedAt[roundId] = startedAt;
    }

    /// @notice Internal function to update the answer
    function _updateAnswer(int256 answer) private {
        _latestRound++;
        _latestAnswer = answer;
        _latestTimestamp = block.timestamp;
        _answers[_latestRound] = answer;
        _timestamps[_latestRound] = block.timestamp;
        _startedAt[_latestRound] = block.timestamp;
    }
}
