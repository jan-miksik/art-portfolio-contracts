// SPDX-License-Identifier: MIT
// create a script to deploy the VariousPicturesCollection contract

pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import "../src/VariousPicturesCollection.sol";  // Adjust this path as needed

contract DeployVariousPicturesCollection is Script {
    string constant COLLECTION_NAME = "Various Pictures";
    string constant COLLECTION_SYMBOL = "VP";
    string constant COLLECTION_URI = "https://arweave.net/metadata";

    function run() external returns (VariousPicturesCollection) {
        vm.startBroadcast();

        VariousPicturesCollection collection = new VariousPicturesCollection(
            COLLECTION_NAME,
            COLLECTION_SYMBOL,
            COLLECTION_URI
        );

        vm.stopBroadcast();

        return collection;
    }
}
