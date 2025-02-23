// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {VariousPicturesCollection} from "../src/VariousPicturesCollection.sol";
import {DeployVariousPicturesCollection} from "../script/DeployVariousPicturesCollection.s.sol";
contract VariousPicturesCollectionTest is Test {
    VariousPicturesCollection collection;
    
    function setUp() public {
        DeployVariousPicturesCollection deployer = new DeployVariousPicturesCollection();
        collection = deployer.run();
    }

    function testOwnerIsMessageSender() public view {
        assertEq(collection.owner(), msg.sender);
    }
}
