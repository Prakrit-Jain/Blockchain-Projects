// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import "../src/DEFIStaking.sol";

contract DEFIStakingScript is Script {
    DEFIStaking staking;
    // please change the address here for the defi token before running the script
    address token = address(1);

    function run() public {
        vm.broadcast();
        staking = new DEFIStaking(token);
    }
}
