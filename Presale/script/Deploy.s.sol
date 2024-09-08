// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import { ChainForgeToken } from "../src/ChainForgeToken.sol";
import { Presale } from "../src/Presale.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Deploy is Script {
    ChainForgeToken public cft;
    Presale public presale;
    address USDT;

    function setUp() public {
        // USDT contract address on BNB
        USDT = 0x337610d27c682E347C9cD60BD4b3b107C9d34dDd;
    }


    function run() public {
        vm.startBroadcast();
        
        cft = new ChainForgeToken();
        presale = new Presale(IERC20(address(cft)), IERC20(USDT));

        vm.stopBroadcast();
    }
}
