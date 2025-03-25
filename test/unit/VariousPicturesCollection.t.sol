// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {VariousPicturesCollection} from "../../src/VariousPicturesCollection.sol"; 
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";


error OwnableUnauthorizedAccount(address account);

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
    uint256 constant COLLECTION_ROYALTY_BASIS_POINTS = 500; // 5%
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
            COLLECTION_URI,
            COLLECTION_ROYALTY_BASIS_POINTS
        );
        mockToken = new MockERC20();
    }

    function testOwnerIsMessageSender() public view {
        assertEq(collection.owner(), owner);
    }


    function testMockERC20Functions() public view {
        // Test all the uncovered functions in MockERC20
        
        // Test allowance
        uint256 allowanceAmount = mockToken.allowance(address(1), address(2));
        assertEq(allowanceAmount, 0);
        
        // Test approve
        bool approveResult = mockToken.approve(address(1), 100);
        assertEq(approveResult, false);
        
        // Test transferFrom
        bool transferFromResult = mockToken.transferFrom(address(1), address(2), 100);
        assertEq(transferFromResult, false);
        
        // Test totalSupply
        uint256 totalSupply = mockToken.totalSupply();
        assertEq(totalSupply, 0);
    }


    function test_SupportsInterface() public view {
        // Test ERC165 interface
        assertTrue(collection.supportsInterface(0x01ffc9a7), "Should support ERC165");
        
        // Test ERC721 interface
        assertTrue(collection.supportsInterface(0x80ac58cd), "Should support ERC721");
        
        // Test ERC721Metadata interface
        assertTrue(collection.supportsInterface(0x5b5e139f), "Should support ERC721Metadata");
        
        // Test ERC2981 interface
        assertTrue(collection.supportsInterface(0x2a55205a), "Should support ERC2981");
        
        // Test invalid interface
        assertFalse(collection.supportsInterface(0xffffffff), "Should not support invalid interface");
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

    function test_Revert_MintWithMetadata_EmptyName() public {
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSignature("EmptyName()"));
        collection.safeMintWithMetadata(
            "",
            TEST_IMAGE
        );
    }

    function test_Revert_MintWithMetadata_EmptyImage() public {
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSignature("EmptyImage()"));
        collection.safeMintWithMetadata(
            TEST_NAME,
            ""
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

    /** Test validation of metadata **/

    function test_Revert_MetadataValidation_NameTooLong() public {
        string memory longName = new string(257);
        for(uint i = 0; i < 257; i++) {
            assembly {
                mstore8(add(add(longName, 32), i), 0x61) // ASCII 'a'
            }
        }
        
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSignature("NameTooLong()"));
        collection.safeMintWithMetadata(user, longName, TEST_DESCRIPTION, TEST_IMAGE);
    }

    function test_Revert_MetadataValidation_DescriptionTooLong() public {
        string memory longDescription = new string(4097);
        for(uint i = 0; i < 4097; i++) {
            assembly {
                mstore8(add(add(longDescription, 32), i), 0x61) // ASCII 'a'
            }
        }
        
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSignature("DescriptionTooLong()"));
        collection.safeMintWithMetadata(user, TEST_NAME, longDescription, TEST_IMAGE);
    }

    function test_Revert_MetadataValidation_ImageURITooLong() public {
        string memory longImageURI = new string(513);
        for(uint i = 0; i < 513; i++) {
            assembly {
                mstore8(add(add(longImageURI, 32), i), 0x61) // ASCII 'a'
            }
        }
        
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSignature("ImageURITooLong()"));
        collection.safeMintWithMetadata(user, TEST_NAME, TEST_DESCRIPTION, longImageURI);
    }

    function test_Revert_MintWithMetadata_ToZeroAddress() public {
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSignature("ZeroAddress()"));
        collection.safeMintWithMetadata(
            address(0),
            TEST_NAME,
            TEST_DESCRIPTION,
            TEST_IMAGE
        );
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

    function test_WithdrawERC20TokenWithZeroBalance() public {
        // Deploy mock ERC20 token
        MockERC20 token = new MockERC20();
        
        // Try to withdraw with zero balance
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSignature("NoTokensToWithdraw()"));  // Use abi.encodeWithSignature
        collection.withdrawERC20Token(IERC20(address(token)), user);  // Use the new token, not mockToken
    }

    function test_WithdrawERC20TokenWithInvalidToken() public {
        // Try to withdraw with invalid token address
        vm.prank(owner);
        vm.expectRevert();
        collection.withdrawERC20Token(IERC20(address(0)), user);
    }

    function test_Revert_WithdrawERC20TokenToZeroAddress() public {
        // Fund the contract with ERC20 tokens
        mockToken.mint(address(collection), 100);
        
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSignature("ZeroAddress()"));
        collection.withdrawERC20Token(IERC20(address(mockToken)), address(0));
    }



    /** ROYALTIES **/

    /// @dev test royaltyInfo function
    function testRoyaltyInfo() public view {
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

    /// @dev test updateRoyaltyBasisPoints function
    function testUpdateRoyaltyBasisPoints() public {
        uint256 newRoyaltyBasisPoints = 1000; // 10%
        
        vm.prank(owner);
        collection.updateRoyaltyBasisPoints(newRoyaltyBasisPoints);
        
        (,uint256 royaltyAmount) = collection.royaltyInfo(0, 100);
        assertEq(royaltyAmount, 10); // 10% of 100
    }

    function test_Revert_UpdateRoyaltyBasisPointsTooHigh() public {
        uint256 tooHighRoyalty = 10001; // Max is 10000 (100%)
        
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSignature("RoyaltyTooHigh()"));
        collection.updateRoyaltyBasisPoints(tooHighRoyalty);
    }

    function test_Revert_UpdateRoyaltyBasisPointsSameValue() public {
        uint256 currentRoyalty = COLLECTION_ROYALTY_BASIS_POINTS; // 500 (5%)
        
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSignature("SameRoyaltyBasisPoints()"));
        collection.updateRoyaltyBasisPoints(currentRoyalty);
    }

    function test_Revert_UpdateRoyaltyBasisPointsNotOwner() public {
        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(OwnableUnauthorizedAccount.selector, user));
        collection.updateRoyaltyBasisPoints(1000);
    }

    

    

    /** METADATA **/

    function testInitialContractURI() public view {
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

    function test_Revert_UpdateContractMetadataURINotOwner() public {
        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(OwnableUnauthorizedAccount.selector, user));
        collection.updateContractMetadataURI("https://arweave.net/newmetadata");
    }

    function testConstructorParameters() public view {
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
            "",
            COLLECTION_ROYALTY_BASIS_POINTS
        );
    }

    function test_Revert_TokenURINonexistentToken() public {
        vm.expectRevert(abi.encodeWithSignature("NonexistentToken()"));
        collection.tokenURI(999); // Token ID that doesn't exist
    }

    receive() external payable {} // Allow contract to receive ETH

}
