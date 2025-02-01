// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Counter} from "../src/Counter.sol";

contract Deploy is Script {
    function run() external returns (Counter) {
        vm.startBroadcast();

        Counter counter = new Counter();

        vm.stopBroadcast();

        return counter;
    }
}
