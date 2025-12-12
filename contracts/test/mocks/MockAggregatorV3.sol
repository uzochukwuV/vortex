// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import "../../src/interfaces/IAggregatorV3.sol";

contract MockAggregatorV3 is IAggregatorV3 {
    uint8 public decimals;
    string public description;
    uint256 public version = 1;

    int256 private _answer;
    uint256 private _updatedAt;
    uint80 private _roundId;

    constructor(uint8 _decimals, int256 _initialAnswer) {
        decimals = _decimals;
        _answer = _initialAnswer;
        _updatedAt = block.timestamp;
        _roundId = 1;
        description = "Mock Price Feed";
    }

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        return (_roundId, _answer, _updatedAt, _updatedAt, _roundId);
    }

    function updateAnswer(int256 newAnswer) external {
        _answer = newAnswer;
        _updatedAt = block.timestamp;
        _roundId++;
    }

    function getRoundData(uint80 /* _roundId */)
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        return (_roundId, _answer, _updatedAt, _updatedAt, _roundId);
    }
}