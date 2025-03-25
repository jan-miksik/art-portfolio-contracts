// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {DeployVariousPicturesCollection} from "../script/DeployVariousPicturesCollection.s.sol";
import {VariousPicturesCollection} from "../src/VariousPicturesCollection.sol";

contract DeployVariousPicturesCollectionTest is Test {
    DeployVariousPicturesCollection deployer;
    
    // Test values
    uint256 constant ROYALTY_BASIS_POINTS = 250; // 2.5%
    string constant NAME = "Various Pictures";
    string constant SYMBOL = "VPIC";
    string constant CONTRACT_METADATA_URI = "ipfs://QmTest";

    uint256 constant MAX_ROYALTY_BASIS_POINTS = 10000;

    function setUp() public {
        deployer = new DeployVariousPicturesCollection();
    }

    function test_DeploymentSuccess() public {
        // Set up environment variables that the deployment script expects
        vm.setEnv("INITIAL_ROYALTY_BASIS_POINTS", vm.toString(ROYALTY_BASIS_POINTS));
        vm.setEnv("COLLECTION_NAME", NAME);
        vm.setEnv("COLLECTION_SYMBOL", SYMBOL);
        vm.setEnv("CONTRACT_METADATA_URI", CONTRACT_METADATA_URI);

        // Deploy the contract
        VariousPicturesCollection collection = deployer.run();
        
        // Verify the contract was deployed with correct parameters
        assertEq(collection.name(), NAME, "Incorrect name");
        assertEq(collection.symbol(), SYMBOL, "Incorrect symbol");
        assertEq(collection.contractURI(), CONTRACT_METADATA_URI, "Incorrect contract URI");
        
        // Test royalty info for a theoretical NFT worth 10000 wei
        (address receiver, uint256 royaltyAmount) = collection.royaltyInfo(1, 1 ether);
        assertEq(receiver, msg.sender, "Incorrect royalty receiver");
        assertEq(royaltyAmount, (1 ether * ROYALTY_BASIS_POINTS) / MAX_ROYALTY_BASIS_POINTS, "Incorrect royalty amount");
    }

    function testFuzz_DeploymentRevertOnInvalidRoyalty(uint256 invalidRoyalty) public {
        // Assume royalty is greater than 10000 (100%)
        vm.assume(invalidRoyalty > MAX_ROYALTY_BASIS_POINTS);
        
        // Set up environment variables with invalid royalty
        vm.setEnv("INITIAL_ROYALTY_BASIS_POINTS", vm.toString(invalidRoyalty));
        vm.setEnv("COLLECTION_NAME", NAME);
        vm.setEnv("COLLECTION_SYMBOL", SYMBOL);
        vm.setEnv("CONTRACT_METADATA_URI", CONTRACT_METADATA_URI);

        // This should revert with RoyaltyTooHigh()
        vm.expectRevert(abi.encodeWithSignature("RoyaltyTooHigh()"));
        deployer.run();
    }
} 