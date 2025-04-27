// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @author: Jan Miksik

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC2981} from "@openzeppelin/contracts/interfaces/IERC2981.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {ERC721Burnable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

error EmptyTokenURI();
error ZeroAddress();
error NoEtherToWithdraw();
error NoTokensToWithdraw();
error SameRoyaltyReceiver();
error EmptyName();
error EmptyImage();
error EmptyMetadata();
error EmptyURI();
error RoyaltyTooHigh();
error SameRoyaltyBasisPoints();
error NameTooLong();
error DescriptionTooLong();
error ImageURITooLong();
error TokenDoesNotExist(uint256 tokenId);

contract VariousPicturesCollection is ERC721, IERC2981, Ownable, ERC721Burnable, ReentrancyGuard, ERC721URIStorage {
    event NFTMinted(address indexed to, uint256 indexed tokenId, string name, string description, string image);
    event NFTMintedWithURI(address indexed to, uint256 indexed tokenId, string tokenURImetadata);
    event RoyaltyUpdated(uint256 oldRoyaltyBasisPoints, uint256 newRoyaltyBasisPoints);
    event RoyaltyReceiverUpdated(address indexed previousReceiver, address indexed newReceiver);
    event MetadataURIUpdated(string previousURI, string newURI);
    event EtherWithdrawn(address indexed to, uint256 amount);
    event ERC20TokenWithdrawn(address indexed token, address indexed to, uint256 amount);
    event TokenURIUpdated(uint256 indexed tokenId, string previousURI, string newURI);

    constructor(
        string memory collectionName,
        string memory collectionSymbol,
        string memory collectionContractMetadataURI,
        uint256 initialRoyaltyBasisPoints
    ) ERC721(collectionName, collectionSymbol) Ownable(msg.sender) {
        if (bytes(collectionContractMetadataURI).length == 0) revert EmptyMetadata();
        if (initialRoyaltyBasisPoints > MAX_ROYALTY_BASIS_POINTS) revert RoyaltyTooHigh();

        _contractMetadataURI = collectionContractMetadataURI;
        _royaltyBasisPoints = initialRoyaltyBasisPoints;
        _royaltyReceiver = msg.sender;
    }

    /*//////////////////////////////////////////////////////////////
                           MINTING
    //////////////////////////////////////////////////////////////*/
    uint256 private _nftCounter;

    function mintedNFTs() external view returns (uint256) {
        return _nftCounter;
    }

    function safeMintWithMetadata(string memory nftName, string memory image) external onlyOwner {
        safeMintWithMetadata(owner(), nftName, "", image);
    }

    /**
     * @dev Mints a new NFT, using overloading to make some parameters optional
     * @param to The address that will receive the minted NFT (optional, defaults to contract owner)
     * @param nftName The name of the NFT
     * @param description A detailed description of the NFT (optional, defaults to empty string)
     * @param image The URI pointing to the NFT's image
     */
    function safeMintWithMetadata(address to, string memory nftName, string memory description, string memory image)
        public
        nonReentrant
        onlyOwner
    {
        if (to == address(0)) revert ZeroAddress();
        _validateMetadata(nftName, description, image);

        uint256 tokenId = _nftCounter;
        _nftCounter++;

        _setTokenURI(tokenId, createTokenURI(nftName, description, image));
        _safeMint(to, tokenId);

        emit NFTMinted(to, tokenId, nftName, description, image);
    }

    /**
     * @dev Mints a new NFT with a complete tokenURImetadata
     * @dev the metadata in this function are more customisable, however it comes with "you must know how to do it" UX
     * @param to The address that will receive the minted NFT
     * @param tokenURImetadata The complete URI containing the NFT's metadata
     */
    function safeMintWithURI(address to, string memory tokenURImetadata) external nonReentrant onlyOwner {
        if (bytes(tokenURImetadata).length == 0) revert EmptyTokenURI();
        if (to == address(0)) revert ZeroAddress();

        uint256 tokenId = _nftCounter;
        _nftCounter++;

        _setTokenURI(tokenId, tokenURImetadata);
        _safeMint(to, tokenId);

        emit NFTMintedWithURI(to, tokenId, tokenURImetadata);
    }

    /*//////////////////////////////////////////////////////////////
                           PAYOUT
    //////////////////////////////////////////////////////////////*/
    using Address for address payable;
    using SafeERC20 for IERC20;

    function withdraw() external nonReentrant onlyOwner {
        uint256 balance = address(this).balance;
        // slither-disable-next-line incorrect-equality
        if (balance == 0) revert NoEtherToWithdraw();
        Address.sendValue(payable(owner()), balance);
        emit EtherWithdrawn(owner(), balance);
    }

    /**
     * @dev withdraws ERC20 tokens from the contract
     * @param token The ERC20 token to withdraw
     * @param to The address that will receive the tokens
     * @notice Uses SafeERC20 to handle non-standard ERC20 tokens
     */
    function withdrawERC20Token(IERC20 token, address to) external nonReentrant onlyOwner {
        uint256 amount = token.balanceOf(address(this));
        // slither-disable-next-line incorrect-equality
        if (amount == 0) revert NoTokensToWithdraw();
        if (to == address(0)) revert ZeroAddress();

        token.safeTransfer(to, amount);
        emit ERC20TokenWithdrawn(address(token), to, amount);
    }

    function checkERC20Balance(IERC20 token) external view returns (uint256) {
        return token.balanceOf(address(this));
    }

    /*//////////////////////////////////////////////////////////////
                           ROYALTIES
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev _royaltyReceiver is accepted by some marketplaces.
     * @dev _royaltyBasisPoints is the royalty percentage in basis points (e.g., 500 = 5%)
     * @dev MAX_ROYALTY_BASIS_POINTS is the maximum royalty percentage (10000 = 100%)
     * @notice the real royalty percentage may depend on the marketplace limits
     * @notice marketplaces can have own way how implementing royalties
     */
    address private _royaltyReceiver;
    uint256 private _royaltyBasisPoints;
    uint256 private constant MAX_ROYALTY_BASIS_POINTS = 1e4;

    function setRoyaltyReceiver(address newReceiver) external onlyOwner {
        if (newReceiver == address(0)) revert ZeroAddress();
        if (newReceiver == _royaltyReceiver) revert SameRoyaltyReceiver();

        address oldReceiver = _royaltyReceiver;
        _royaltyReceiver = newReceiver;
        emit RoyaltyReceiverUpdated(oldReceiver, newReceiver);
    }

    function getRoyaltyReceiver() external view returns (address) {
        return _royaltyReceiver;
    }

    /**
     * @dev first parameter in royaltyInfo is tokenId - the NFT asset queried for royalty information
     * @param salePrice - the sale price of the NFT asset specified by tokenId
     */
    function royaltyInfo(uint256, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        return (_royaltyReceiver, (salePrice * _royaltyBasisPoints) / MAX_ROYALTY_BASIS_POINTS);
    }

    /**
     * @dev Updates the royalty percentage in basis points
     * @param newBasisPoints The new royalty percentage in basis points (e.g., 500 = 5%).
     */
    function updateRoyaltyBasisPoints(uint256 newBasisPoints) external onlyOwner {
        if (newBasisPoints > MAX_ROYALTY_BASIS_POINTS) revert RoyaltyTooHigh();
        if (newBasisPoints == _royaltyBasisPoints) revert SameRoyaltyBasisPoints();

        uint256 oldRoyaltyBasisPoints = _royaltyBasisPoints;
        _royaltyBasisPoints = newBasisPoints;
        emit RoyaltyUpdated(oldRoyaltyBasisPoints, newBasisPoints);
    }

    /*//////////////////////////////////////////////////////////////
                           METADATA
    //////////////////////////////////////////////////////////////*/
    string private _contractMetadataURI;

    /**
     * @dev Updates the contract metadata URI.
     * @param newURI The new metadata URI to set.
     * @notice If the _royaltyReceiver is changed in the new URI it should be updated
     * manually by the owner or maintainer in the contract as well, by setRoyaltyReceiver function.
     * Marketplaces may use own internal setup
     */
    function updateContractMetadataURI(string memory newURI) external onlyOwner {
        if (bytes(newURI).length == 0) revert EmptyURI();

        string memory oldURI = _contractMetadataURI;
        _contractMetadataURI = newURI;
        emit MetadataURIUpdated(oldURI, newURI);
    }

    /**
     * @dev This URI is used by NFT marketplaces, unless they use own internal setup.
     * @return The collection contract metadata URI.
     */
    function contractURI() external view returns (string memory) {
        return _contractMetadataURI;
    }

    /**
     * @dev The following function is override required by Solidity.
     * @param tokenId token id of the NFT
     * @return The metadata URI of tokenId
     * @notice Reverts if the token doesn't exist
     */
    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        if (_ownerOf(tokenId) == address(0)) revert TokenDoesNotExist(tokenId);
        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets the token URI for a specific token ID
     * @param tokenId The ID of the token to update
     * @param newURI The new URI to set for the token
     * @notice Only the contract owner can call this function
     * @notice Reverts if the token doesn't exist or if the new URI is empty
     */
    function setTokenURI(uint256 tokenId, string memory newURI) external onlyOwner {
        if (_ownerOf(tokenId) == address(0)) revert TokenDoesNotExist(tokenId);
        if (bytes(newURI).length == 0) revert EmptyURI();

        string memory oldURI = tokenURI(tokenId);
        _setTokenURI(tokenId, newURI);
        emit TokenURIUpdated(tokenId, oldURI, newURI);
    }

    /**
     * @dev Creates a token URI for a new NFT.
     * @param nftName The name of the NFT.
     * @param description A detailed description of the NFT.
     * @param image The URI of the NFT's image.
     * @return The token URI for the new NFT.
     */
    function createTokenURI(string memory nftName, string memory description, string memory image)
        public
        pure
        returns (string memory)
    {
        if (bytes(nftName).length == 0) revert EmptyName();
        if (bytes(image).length == 0) revert EmptyImage();

        string memory jsonContent =
            string(abi.encodePacked('{"name":"', nftName, '","description":"', description, '","image":"', image, '"}'));

        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(jsonContent))));
    }

    uint256 private constant MAX_NAME_LENGTH = 256;
    uint256 private constant MAX_DESCRIPTION_LENGTH = 4096;
    uint256 private constant MAX_IMAGE_URI_LENGTH = 512;

    /**
     * @dev Validates the metadata for a new NFT.
     * @param nftName The name of the NFT.
     * @param description The description of the NFT.
     * @param imageURI The URI of the NFT's image.
     */
    function _validateMetadata(string memory nftName, string memory description, string memory imageURI)
        internal
        pure
    {
        if (bytes(nftName).length == 0) revert EmptyName();
        if (bytes(imageURI).length == 0) revert EmptyImage();
        if (bytes(nftName).length > MAX_NAME_LENGTH) revert NameTooLong();
        if (bytes(description).length > MAX_DESCRIPTION_LENGTH) revert DescriptionTooLong();
        if (bytes(imageURI).length > MAX_IMAGE_URI_LENGTH) revert ImageURITooLong();
    }

    /// @dev EIP2981 standard Interface return. Adds to ERC721, ERC165 and ERC721URIStorage Interface returns.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, IERC165, ERC721URIStorage)
        returns (bool)
    {
        return (interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId));
    }
}
