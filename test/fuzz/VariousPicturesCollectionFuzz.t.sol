// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import {VariousPicturesCollection} from "../../src/VariousPicturesCollection.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract VariousPicturesCollectionFuzzTest is Test {
    VariousPicturesCollection public collection;
    address public owner;
    address public user;
    string public constant COLLECTION_NAME = "Test Collection";
    string public constant COLLECTION_SYMBOL = "TEST";
    string public constant CONTRACT_METADATA_URI = "ipfs://test";
    uint256 public constant INITIAL_ROYALTY = 500; // 5%

    function setUp() public {
        owner = makeAddr("owner");
        user = makeAddr("user");
        vm.startPrank(owner);
        collection =
            new VariousPicturesCollection(COLLECTION_NAME, COLLECTION_SYMBOL, CONTRACT_METADATA_URI, INITIAL_ROYALTY);
        vm.stopPrank();
    }

    function testFuzz_mintWithMetadata(address to, string memory name, string memory description, string memory image)
        public
    {
        vm.assume(to != address(0));
        vm.assume(to.code.length == 0); // Only EOAs, not contracts
        vm.assume(bytes(name).length > 0 && bytes(name).length <= 256);
        vm.assume(bytes(description).length <= 4096);
        vm.assume(bytes(image).length > 0 && bytes(image).length <= 512);

        vm.startPrank(owner);
        uint256 initialSupply = collection.mintedNFTs();
        collection.safeMintWithMetadata(to, name, description, image);
        assertEq(collection.mintedNFTs(), initialSupply + 1);
        assertEq(collection.ownerOf(initialSupply), to);
        vm.stopPrank();
    }

    function testFuzz_royalty_calculation(uint256 salePrice) public view {
        vm.assume(salePrice > 0);
        vm.assume(salePrice <= type(uint256).max / INITIAL_ROYALTY);
        (address receiver, uint256 royaltyAmount) = collection.royaltyInfo(0, salePrice);
        assertEq(receiver, owner);
        assertEq(royaltyAmount, (salePrice * INITIAL_ROYALTY) / 10000);
    }

    function testFuzz_updateContractMetadataURI(string memory newURI) public {
        vm.assume(bytes(newURI).length > 0);
        vm.startPrank(owner);
        collection.updateContractMetadataURI(newURI);
        assertEq(collection.contractURI(), newURI);
        vm.stopPrank();
    }

    function testFuzz_createTokenURI(string memory name, string memory description, string memory image) public view {
        vm.assume(bytes(name).length > 0 && bytes(name).length <= 256);
        vm.assume(bytes(description).length <= 4096);
        vm.assume(bytes(image).length > 0 && bytes(image).length <= 512);

        string memory uri = collection.createTokenURI(name, description, image);
        assertTrue(bytes(uri).length > 0);
        bytes memory prefix = "data:application/json;base64,";
        bytes memory uriBytes = bytes(uri);
        bool hasPrefix = true;
        for (uint256 i = 0; i < prefix.length; i++) {
            if (i >= uriBytes.length || uriBytes[i] != prefix[i]) {
                hasPrefix = false;
                break;
            }
        }
        assertTrue(hasPrefix);
    }
}
