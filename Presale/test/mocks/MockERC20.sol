
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20 {
    constructor(string memory name, string memory symbol, uint256 initialSupply) ERC20(name, symbol) {
        // Mint the initial supply to the contract deployer
        _mint(msg.sender, initialSupply);
    }

    /// @notice Mint additional tokens for testing purposes
    /// @param account The address to mint tokens to
    /// @param amount The amount of tokens to mint
    function mint(address account, uint256 amount) external {
        _mint(account, amount);
    }
}