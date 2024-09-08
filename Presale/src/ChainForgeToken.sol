// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ChainForgeToken is ERC20 {
    uint256 public constant TOTAL_SUPPLY = 1000000 * 1e18; // 1,000,000 CFT with 18 decimals

    constructor() ERC20("ChainForgeToken", "CFT") {
        _mint(msg.sender, TOTAL_SUPPLY); // Mint all tokens to the contract owner
    }
}
