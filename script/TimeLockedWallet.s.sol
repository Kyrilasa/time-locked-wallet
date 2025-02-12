// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {TimeLockedWallet} from "../src/TimeLockedWallet.sol";
import {console} from "forge-std/console.sol";

contract DeployScript is Script {

    TimeLockedWallet public wallet;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();
        
        wallet = new TimeLockedWallet();
        console.log("TimeLockedWallet deployed to:", address(wallet));
        
        vm.stopBroadcast();
    }
}