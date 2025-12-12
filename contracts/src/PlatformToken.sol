// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Platform Token
/// @notice ERC20 governance and utility token for the perpetual DEX platform
/// @dev Used for governance voting, staking rewards, and fee discounts
contract PlatformToken is ERC20, Ownable {
    /// @notice Maximum supply cap
    uint256 public constant MAX_SUPPLY = 1_000_000_000 * 10**18; // 1 billion tokens
    
    /// @notice Emitted when tokens are minted
    event TokensMinted(address indexed to, uint256 amount);
    
    /// @notice Emitted when tokens are burned
    event TokensBurned(address indexed from, uint256 amount);
    
    /// @param initialSupply Initial token supply to mint to deployer
    constructor(uint256 initialSupply) ERC20("Perpetual DEX Token", "PDX") Ownable(msg.sender) {
        require(initialSupply <= MAX_SUPPLY, "Initial supply exceeds max supply");
        _mint(msg.sender, initialSupply);
        emit TokensMinted(msg.sender, initialSupply);
    }
    
    /// @notice Mint new tokens (only owner)
    /// @param to Address to receive tokens
    /// @param amount Amount to mint
    function mint(address to, uint256 amount) external onlyOwner {
        require(totalSupply() + amount <= MAX_SUPPLY, "Exceeds max supply");
        _mint(to, amount);
        emit TokensMinted(to, amount);
    }
    
    /// @notice Burn tokens from caller's balance
    /// @param amount Amount to burn
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
        emit TokensBurned(msg.sender, amount);
    }
}
