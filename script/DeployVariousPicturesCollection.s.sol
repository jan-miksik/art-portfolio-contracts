// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {VariousPicturesCollection} from "../src/VariousPicturesCollection.sol";

contract DeployVariousPicturesCollection is Script {
    function run() public returns (VariousPicturesCollection) {
        // Read environment variables using vm.envUint/vm.envString
        uint256 initialRoyaltyBasisPoints = vm.envUint("INITIAL_ROYALTY_BASIS_POINTS");
        string memory name = vm.envString("COLLECTION_NAME");
        string memory symbol = vm.envString("COLLECTION_SYMBOL");
        string memory contractMetadataURI = vm.envString("COLLECTION_URI");

        // Start broadcasting transactions
        vm.startBroadcast();

        // Deploy the contract
        VariousPicturesCollection collection =
            new VariousPicturesCollection(name, symbol, contractMetadataURI, initialRoyaltyBasisPoints);

        vm.stopBroadcast();

        return collection;
    }
}
