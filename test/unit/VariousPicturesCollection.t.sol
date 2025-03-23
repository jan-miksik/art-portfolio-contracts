// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {VariousPicturesCollection} from "../../src/VariousPicturesCollection.sol"; 
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";

// Add the error declaration
error EmptyTokenURI();

contract MockERC20 is IERC20 {
    mapping(address => uint256) private _balances;
    
    function mint(address to, uint256 amount) external {
        _balances[to] += amount;
    }
    
    function transfer(address to, uint256 amount) external returns (bool) {
        _balances[msg.sender] -= amount;
        _balances[to] += amount;
        return true;
    }
    
    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }
    
    // Implement other IERC20 functions as needed (can be empty for testing)
    function allowance(address, address) external pure returns (uint256) { return 0; }
    function approve(address, uint256) external pure returns (bool) { return false; }
    function transferFrom(address, address, uint256) external pure returns (bool) { return false; }
    function totalSupply() external pure returns (uint256) { return 0; }
}

contract VariousPicturesCollectionTest is Test {
    VariousPicturesCollection collection;
    MockERC20 mockToken;
    address owner;
    address user;

    // Common test values
    string constant COLLECTION_NAME = "Various Pictures";
    string constant COLLECTION_SYMBOL = "VP";
    string constant COLLECTION_URI = "https://arweave.net/metadata";
    string constant TEST_NAME = "Test NFT";
    string constant TEST_DESCRIPTION = "Test Description";
    string constant TEST_IMAGE = "ipfs://image";

    function setUp() public {
        owner = makeAddr("owner");  // Creates a new address that can receive NFTs
        user = makeAddr("user");
        
        vm.prank(owner);  // Deploy contract as owner
        collection = new VariousPicturesCollection(
            COLLECTION_NAME,
            COLLECTION_SYMBOL,
            COLLECTION_URI
        );
        mockToken = new MockERC20();
    }

    function testOwnerIsMessageSender() public {
        assertEq(collection.owner(), owner);
    }



    /** MINTING **/

    function testMintWithMetadata() public {
        vm.prank(owner);
        collection.safeMintWithMetadata(user, TEST_NAME, TEST_DESCRIPTION, TEST_IMAGE);
        
        assertEq(collection.mintedNFTs(), 1);
        assertEq(collection.ownerOf(0), user);
    }

    function testMintWithURI() public {
        string memory uri = "data:application/json;base64,test";
        
        vm.prank(owner);
        collection.safeMintWithURI(user, uri);
        
        assertEq(collection.mintedNFTs(), 1);
        assertEq(collection.ownerOf(0), user);
        assertEq(collection.tokenURI(0), uri);
    }

    /** Test overloaded safeMintWithMetadata functions **/

    function test_safeMintWithMetadata_NameAndImage() public {
        vm.prank(owner);
        collection.safeMintWithMetadata(
            TEST_NAME,
            TEST_IMAGE
        );

        assertEq(collection.mintedNFTs(), 1);
        assertEq(collection.ownerOf(0), owner);
        
        string memory expectedUri = collection.createTokenURI(TEST_NAME, "", TEST_IMAGE);
        assertEq(collection.tokenURI(0), expectedUri);
    }

    function test_safeMintWithMetadata_ToAddressNameAndImage() public {
        vm.prank(owner);
        collection.safeMintWithMetadata(
            user,
            TEST_NAME,
            TEST_IMAGE
        );

        assertEq(collection.mintedNFTs(), 1);
        assertEq(collection.ownerOf(0), user);
        
        string memory expectedUri = collection.createTokenURI(TEST_NAME, "", TEST_IMAGE);
        assertEq(collection.tokenURI(0), expectedUri);
    }

    function test_safeMintWithMetadata_NameDescriptionAndImage() public {
        vm.prank(owner);
        collection.safeMintWithMetadata(
            TEST_NAME,
            TEST_DESCRIPTION,
            TEST_IMAGE
        );

        assertEq(collection.mintedNFTs(), 1);
        assertEq(collection.ownerOf(0), owner);
        
        string memory expectedUri = collection.createTokenURI(TEST_NAME, TEST_DESCRIPTION, TEST_IMAGE);
        assertEq(collection.tokenURI(0), expectedUri);
    }

    function test_safeMintWithMetadata_ToAddressNameDescriptionAndImage() public {
        vm.prank(owner);
        collection.safeMintWithMetadata(
            user,
            TEST_NAME,
            TEST_DESCRIPTION,
            TEST_IMAGE
        );

        assertEq(collection.mintedNFTs(), 1);
        assertEq(collection.ownerOf(0), user);
        
        string memory expectedUri = collection.createTokenURI(TEST_NAME, TEST_DESCRIPTION, TEST_IMAGE);
        assertEq(collection.tokenURI(0), expectedUri);
    }

    /** Test error conditions **/

    function testFail_safeMintWithMetadata_EmptyName() public {
        vm.prank(owner);
        collection.safeMintWithMetadata(
            "",
            TEST_IMAGE
        );
    }

    function testFail_safeMintWithMetadata_EmptyImage() public {
        vm.prank(owner);
        collection.safeMintWithMetadata(
            TEST_NAME,
            ""
        );
    }

    function testFail_safeMintWithMetadata_ZeroAddress() public {
        vm.prank(owner);
        collection.safeMintWithMetadata(
            address(0),
            TEST_NAME,
            TEST_IMAGE
        );
    }

    function test_Revert_MintWithEmptyURI() public {
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSignature("EmptyTokenURI()"));
        collection.safeMintWithURI(address(1), "");
    }

    function test_Revert_MintToZeroAddress() public {
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSignature("ZeroAddress()"));
        collection.safeMintWithURI(address(0), "test");
    }



    /** PAYOUT **/

    function testWithdrawEther() public {
        // Fund the contract
        vm.deal(address(collection), 1 ether);
        
        uint256 initialBalance = address(this).balance;

        vm.prank(owner);
        collection.withdraw();
        uint256 finalBalance = address(this).balance;
        
        assertEq(finalBalance - initialBalance, 0 ether);
    }

    function test_Revert_WithdrawNoEther() public {
        vm.expectRevert(abi.encodeWithSignature("NoEtherToWithdraw()"));
        vm.prank(owner);
        collection.withdraw();
    }

    function testWithdrawERC20() public {
        // Fund the contract with ERC20 tokens
        vm.prank(owner);
        mockToken.mint(address(collection), 100);
        
        vm.prank(owner);
        collection.withdrawERC20Token(IERC20(address(mockToken)), user);
        
        assertEq(mockToken.balanceOf(user), 100);
        assertEq(mockToken.balanceOf(address(collection)), 0);
    }

    function test_Revert_WithdrawNoERC20() public {
        vm.expectRevert(abi.encodeWithSignature("NoTokensToWithdraw()"));
        vm.prank(owner);
        collection.withdrawERC20Token(IERC20(address(mockToken)), user);
    }

    function testCheckERC20Balance() public {
        mockToken.mint(address(collection), 100);
        assertEq(collection.checkERC20Balance(IERC20(address(mockToken))), 100);
    }



    /** ROYALTIES **/

    function testRoyaltyInfo() public {
        (address receiver, uint256 royaltyAmount) = collection.royaltyInfo(0, 100);
        assertEq(receiver, collection.getRoyaltyReceiver());
        assertEq(royaltyAmount, 5); // 5% of 100
    }

    function testSetRoyaltyReceiver() public {
        vm.prank(owner);
        collection.setRoyaltyReceiver(user);
        assertEq(collection.getRoyaltyReceiver(), user);
    }

    function test_Revert_SetRoyaltyReceiverToZeroAddress() public {
        vm.expectRevert(abi.encodeWithSignature("ZeroAddress()"));
        vm.prank(owner);
        collection.setRoyaltyReceiver(address(0));
    }

    function test_Revert_SetSameRoyaltyReceiver() public {
        address currentReceiver = collection.getRoyaltyReceiver();
        vm.expectRevert(abi.encodeWithSignature("SameRoyaltyReceiver()"));
        vm.prank(owner);
        collection.setRoyaltyReceiver(currentReceiver);
    }

    

    /** METADATA **/

    function testInitialContractURI() public {
        assertEq(collection.contractURI(), COLLECTION_URI);
    }

    function testUpdateContractMetadataURI() public {
        string memory newURI = "https://arweave.net/newmetadata";
        
        vm.prank(owner);
        collection.updateContractMetadataURI(newURI);
        
        assertEq(collection.contractURI(), newURI);
    }

    function test_Revert_UpdateContractMetadataURIEmpty() public {
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSignature("EmptyURI()"));
        collection.updateContractMetadataURI("");
    }

    // function test_Revert_UpdateContractMetadataURINotOwner() public {
    //     vm.prank(user);
    //     vm.expectRevert("Ownable: caller is not the owner");
    //     collection.updateContractMetadataURI("https://arweave.net/newmetadata");
    // }

    function testConstructorParameters() public {
        assertEq(collection.name(), COLLECTION_NAME);
        assertEq(collection.symbol(), COLLECTION_SYMBOL);
        assertEq(collection.contractURI(), COLLECTION_URI);
    }

    function test_Revert_ConstructorEmptyMetadata() public {
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSignature("EmptyMetadata()"));
        new VariousPicturesCollection(
            COLLECTION_NAME,
            COLLECTION_SYMBOL,
            ""
        );
    }

    receive() external payable {} // Allow contract to receive ETH

}
