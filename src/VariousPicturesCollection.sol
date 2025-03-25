// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/ReentrancyGuard.sol';
import '@openzeppelin/contracts/interfaces/IERC2981.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/Base64.sol';
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

error EmptyTokenURI();
error ZeroAddress();
error NonexistentToken();
error NoEtherToWithdraw();
error NoTokensToWithdraw();
error TokenTransferFailed();
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

contract VariousPicturesCollection is ERC721, IERC2981, Ownable, ERC721Burnable, ReentrancyGuard {
    event NFTMinted(address indexed to, uint256 indexed tokenId, string name, string description, string image);
    event NFTMintedWithURI(address indexed to, uint256 indexed tokenId, string tokenURImetadata);
    event RoyaltyUpdated(uint256 oldRoyaltyBasisPoints, uint256 newRoyaltyBasisPoints);
    event RoyaltyReceiverUpdated(address indexed previousReceiver, address indexed newReceiver);
    event MetadataURIUpdated(string previousURI, string newURI);
    event NFTBurned(uint256 indexed tokenId, address indexed burner);

    constructor(
        string memory name,
        string memory symbol,
        string memory contractMetadataURI,
        uint256 initialRoyaltyBasisPoints
    ) ERC721(name, symbol) Ownable(msg.sender) {
        if (bytes(contractMetadataURI).length == 0) revert EmptyMetadata();
        if (initialRoyaltyBasisPoints > MAX_ROYALTY_BASIS_POINTS) revert RoyaltyTooHigh();
        
        _contractMetadataURI = contractMetadataURI;
        _royaltyBasisPoints = initialRoyaltyBasisPoints;
        _royaltyReceiver = msg.sender;
    }



    /** MINTING **/
    
    uint256 private _nftCounter;

    function mintedNFTs() public view returns (uint256) {
        return _nftCounter;
    }

    function safeMintWithMetadata(
        string memory name,
        string memory image
    ) public onlyOwner {
        safeMintWithMetadata(owner(), name, "", image);
    }

    /**
     * @dev Mints a new NFT
     * @param to The address that will receive the minted NFT (optional, defaults to contract owner)
     * @param name The name of the NFT
     * @param description A detailed description of the NFT (optional, defaults to empty string)
     * @param image The URI pointing to the NFT's image
     */
    function safeMintWithMetadata(
        address to,
        string memory name,
        string memory description,
        string memory image
    ) public onlyOwner {
        if (to == address(0)) revert ZeroAddress();
        _validateMetadata(name, description, image);
        
        uint256 tokenId;
        unchecked {
            tokenId = _nftCounter++;
        }
        
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, createTokenURI(name, description, image));
        
        emit NFTMinted(to, tokenId, name, description, image);
    }

    /**
     * @dev Mints a new NFT with a complete tokenURImetadata, 
     * @dev the metadata in this function are more customisable, however it comes with higher technical complexity
     * @param to The address that will receive the minted NFT
     * @param tokenURImetadata The complete URI containing the NFT's metadata
     */
    function safeMintWithURI(address to, string memory tokenURImetadata) public onlyOwner nonReentrant {
        if (bytes(tokenURImetadata).length == 0) revert EmptyTokenURI();
        if (to == address(0)) revert ZeroAddress();
        
        uint256 tokenId = _nftCounter;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, tokenURImetadata);
        _nftCounter++;

        emit NFTMintedWithURI(to, tokenId, tokenURImetadata);
    }



    /** PAYOUT **/

    using Address for address payable;
    using SafeERC20 for IERC20;

    function withdraw() public onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        if (balance == 0) revert NoEtherToWithdraw();
        Address.sendValue(payable(owner()), balance);
    }

    /**
     * @dev withdraws ERC20 tokens from the contract
     * @param token The ERC20 token to withdraw
     * @param to The address that will receive the tokens
     * @notice Uses SafeERC20 to handle non-standard ERC20 tokens
     */
    function withdrawERC20Token(IERC20 token, address to) external onlyOwner nonReentrant {
        uint256 amount = token.balanceOf(address(this));
        if (amount == 0) revert NoTokensToWithdraw();
        if (to == address(0)) revert ZeroAddress();
        
        token.safeTransfer(to, amount);
    }  

    function checkERC20Balance(IERC20 token) external view returns (uint256) {
        return token.balanceOf(address(this));
    }



    /** ROYALTIES **/

    /**
     * @dev _royaltyReceiver is accepted by some marketplaces.
     * @dev _royaltyBasisPoints is the royalty percentage in basis points (e.g., 500 = 5%)
     * @dev MAX_ROYALTY_BASIS_POINTS is the maximum royalty percentage (10000 = 100%)
     * @notice the real royalty percentage may depend on the marketplace limits
     * @notice marketplaces can have own way how implementing royalties
     */
    address private _royaltyReceiver;
    uint256 private _royaltyBasisPoints;
    uint256 private constant MAX_ROYALTY_BASIS_POINTS = 10000;

    function setRoyaltyReceiver(address newReceiver) public onlyOwner {
        if (newReceiver == address(0)) revert ZeroAddress();
        if (newReceiver == _royaltyReceiver) revert SameRoyaltyReceiver();
        
        address oldReceiver = _royaltyReceiver;
        _royaltyReceiver = newReceiver;
        emit RoyaltyReceiverUpdated(oldReceiver, newReceiver);
    }

    function getRoyaltyReceiver() public view returns (address) {
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

    /// @dev EIP2981 standard Interface return. Adds to ERC721 and ERC165 Interface returns.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, IERC165)
        returns (bool)
    {
        return (interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId));
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



    /** METADATA **/

    string private _contractMetadataURI;

    /**
     * @dev Updates the contract metadata URI.
     * @param newURI The new metadata URI to set.
     * @notice If the _royaltyReceiver is changed in the new URI it should be updated 
     * manually by the owner or maintainer in the contract as well, by setRoyaltyReceiver function.
     * Marketplaces may use own internal setup
     */
    function updateContractMetadataURI(string memory newURI) public onlyOwner {
        if (bytes(newURI).length == 0) revert EmptyURI();
        
        string memory oldURI = _contractMetadataURI;
        _contractMetadataURI = newURI;
        emit MetadataURIUpdated(oldURI, newURI);
    }

    /**
     * @dev This URI is used by NFT marketplaces, unless they use own internal setup.
     * @return The collection contract metadata URI.
     */
    function contractURI() public view returns (string memory) {
        return _contractMetadataURI;
    }

    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev Sets the token URI for a specific NFT token.
     * @param tokenId The ID of the NFT token.
     * @param tokenURImetadata The URI containing the NFT's metadata.
     */
    function _setTokenURI(uint256 tokenId, string memory tokenURImetadata) internal {
        _tokenURIs[tokenId] = tokenURImetadata;
    }

    /**
     * @dev Returns the token URI for a specific NFT token.
     * @param tokenId The ID of the NFT token.
     * @return The URI containing the NFT's metadata.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (_ownerOf(tokenId) == address(0)) revert NonexistentToken();
        
        string memory tokenURImetadata = _tokenURIs[tokenId];
        return tokenURImetadata;
    }

    /**
     * @dev Creates a token URI for a new NFT.
     * @param name The name of the NFT.
     * @param description A detailed description of the NFT.
     * @param image The URI of the NFT's image.
     * @return The token URI for the new NFT.
     */
    function createTokenURI(
        string memory name,
        string memory description,
        string memory image
    ) public pure returns (string memory) {
        if (bytes(name).length == 0) revert EmptyName();
        if (bytes(image).length == 0) revert EmptyImage();

        return string.concat(
            'data:application/json;base64,',
            Base64.encode(
                abi.encodePacked(
                    '{"name":"', name, 
                    '","description":"', description, 
                    '","image":"', image, '"}'
                )
            )
        );
    }

    uint256 private constant MAX_NAME_LENGTH = 256;
    uint256 private constant MAX_DESCRIPTION_LENGTH = 4096;
    uint256 private constant MAX_IMAGE_URI_LENGTH = 512;

    /**
     * @dev Validates the metadata for a new NFT.
     * @param name The name of the NFT.
     * @param description The description of the NFT.
     * @param imageURI The URI of the NFT's image.
     */
    function _validateMetadata(string memory name, string memory description, string memory imageURI) internal pure {
        if (bytes(name).length == 0) revert EmptyName();
        if (bytes(imageURI).length == 0) revert EmptyImage();
        if (bytes(name).length > MAX_NAME_LENGTH) revert NameTooLong();
        if (bytes(description).length > MAX_DESCRIPTION_LENGTH) revert DescriptionTooLong();
        if (bytes(imageURI).length > MAX_IMAGE_URI_LENGTH) revert ImageURITooLong();
    }
}