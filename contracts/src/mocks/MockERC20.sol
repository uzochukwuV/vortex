// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Mock ERC20 Token
/// @notice Mock ERC20 token for testnet deployment
/// @dev Allows anyone to mint tokens for testing purposes
contract MockERC20 is ERC20, Ownable {
    uint8 private _decimals;

    /// @notice Constructor to create a mock token
    /// @param name Token name
    /// @param symbol Token symbol
    /// @param decimals_ Token decimals
    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals_
    ) ERC20(name, symbol) Ownable(msg.sender) {
        _decimals = decimals_;
    }

    /// @notice Override decimals function
    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    /// @notice Mint tokens to any address (testnet only)
    /// @param to Address to mint tokens to
    /// @param amount Amount to mint
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    /// @notice Mint tokens to caller (convenient for testing)
    /// @param amount Amount to mint
    function mintTo(uint256 amount) external {
        _mint(msg.sender, amount);
    }

    /// @notice Burn tokens from caller
    /// @param amount Amount to burn
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }
}
