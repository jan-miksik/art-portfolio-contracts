// SPDX-License-Identifier: MIT
// create a script to deploy the VariousPicturesCollection contract

pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import "../src/VariousPicturesCollection.sol";  // Adjust this path as needed

contract DeployVariousPicturesCollection is Script {
    function run() external returns (VariousPicturesCollection) {
        vm.startBroadcast();

        VariousPicturesCollection collection = new VariousPicturesCollection();

        vm.stopBroadcast();

        return collection;
    }
}
