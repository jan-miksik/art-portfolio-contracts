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
contract VariousPicturesCollection is ERC721, IERC2981, Ownable, ReentrancyGuard {
    constructor(
        string memory name,
        string memory symbol,
        string memory contractMetadataURI
    ) ERC721(name, symbol) Ownable(msg.sender) {
        if (bytes(contractMetadataURI).length == 0) revert EmptyMetadata();
        _royaltyReceiver = owner();
        _contractMetadataURI = contractMetadataURI;
    }

    string private _contractMetadataURI;

    /** MINTING **/
    
    uint256 private _nftCounter;

    function mintedNFTs() public view returns (uint256) {
        return _nftCounter;
    }

    /**
     * @dev Mints a new NFT with specified metadata components to the owner
     * @param name The name of the NFT
     * @param image The URI pointing to the NFT's image
     * @notice safeMintWithMetadata using overloading to make some of the parameters optional
     */
    function safeMintWithMetadata(
        string memory name,
        string memory image
    ) public onlyOwner {
        safeMintWithMetadata(owner(), name, "", image);
    }

    /**
     * @dev Mints a new NFT with specified metadata
     * @param to The address that will receive the minted NFT (optional, defaults to contract owner)
     * @param name The name of the NFT
     * @param image The URI pointing to the NFT's image
     */
    function safeMintWithMetadata(
        address to,
        string memory name,
        string memory image
    ) public onlyOwner {
        safeMintWithMetadata(to, name, "", image);
    }

    /**
     * @dev Mints a new NFT with specified metadata components to the owner
     * @param name The name of the NFT
     * @param description A detailed description of the NFT (optional)
     * @param image The URI pointing to the NFT's image
     */
    function safeMintWithMetadata(
        string memory name,
        string memory description,
        string memory image
    ) public onlyOwner {
        safeMintWithMetadata(owner(), name, description, image);
    }

    /**
     * @dev Mints a new NFT with specified metadata components
     * @param to The address that will receive the minted NFT (optional, defaults to contract owner)
     * @param name The name of the NFT
     * @param description A detailed description of the NFT (optional)
     * @param image The URI pointing to the NFT's image
     */
    function safeMintWithMetadata(
        address to,
        string memory name,
        string memory description,
        string memory image
    ) public onlyOwner {
        string memory uri = createTokenURI(name, description, image);
        safeMintWithURI(to, uri);
    }

    /**
     * @dev Mints a new NFT with a complete tokenURI
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
    }



    /** PAYOUT **/

    function withdraw() public onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        if (balance == 0) revert NoEtherToWithdraw();
        Address.sendValue(payable(owner()), balance);
    }

    /**
     * @param token is the ERC20 token that will be withdrawn.
     * @param to is the address that will receive the tokens.
     */
    function withdrawERC20Token(IERC20 token, address to) external onlyOwner nonReentrant {
        uint256 amount = token.balanceOf(address(this));
        if (amount == 0) revert NoTokensToWithdraw();
        if (!token.transfer(to, amount)) revert TokenTransferFailed();
    }  

    function checkERC20Balance(IERC20 token) external view returns (uint256) {
        return token.balanceOf(address(this));
    }



    /** ROYALTIES **/

    /**
     * @dev _royaltyReceiver is accepted by some marketplaces.
     * @dev Other marketplaces may send royalty based on specification in contractURI metadata.
     */
    address private _royaltyReceiver = address(this);

    function _setRoyaltyReceiver(address newRoyaltyReceiver)
        internal
        onlyOwner
    {
        if (newRoyaltyReceiver == _royaltyReceiver) revert SameRoyaltyReceiver();
        if (newRoyaltyReceiver == address(0)) revert ZeroAddress();
        _royaltyReceiver = newRoyaltyReceiver;
    }

    function setRoyaltyReceiver(address newRoyaltyReceiver) external onlyOwner {
        _setRoyaltyReceiver(newRoyaltyReceiver);
    }

    function getRoyaltyReceiver() public view returns (address) {
        return _royaltyReceiver;
    }

    /**
     * @dev first parameter in royaltyInfo is tokenId - the NFT asset queried for royalty information
     * @param salePrice - the sale price of the NFT asset specified by tokenId
     * @notice `_royaltyReceiver, salePrice / 20` is optimized code of `_royaltyReceiver (salePrice * 500) / 10000)` for 5% royalty
     */
    function royaltyInfo(uint256, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        return (_royaltyReceiver, salePrice / 20);
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



    /** METADATA **/
    /**
     * @dev Updates the contract metadata URI.
     * @param newURI The new metadata URI to set.
     * @notice If the _royaltyReceiver is changed in the new URI it should be updated manually by the owner or maintainer in the contract as well, by setRoyaltyReceiver function.
     * Marketplaces may use own internal setup which should be aligned with the will of the owner or maintainer of the contract
     */
    function updateContractMetadataURI(string memory newURI) external onlyOwner {
        if (bytes(newURI).length == 0) revert EmptyURI();
        _contractMetadataURI = newURI;
    }

    function contractURI() public view returns (string memory) {
        return _contractMetadataURI;
    }

    mapping(uint256 => string) private _tokenURIs;

    function _setTokenURI(uint256 tokenId, string memory tokenURImetadata) internal {
        if (_ownerOf(tokenId) == address(0)) revert NonexistentToken();
        _tokenURIs[tokenId] = tokenURImetadata;
    }

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

    /// @dev Helper function to create TokenURI from metadata components
    function createTokenURI(
        string memory name,
        string memory description,
        string memory image
    ) public pure returns (string memory) {
        if (bytes(name).length == 0) revert EmptyName();
        if (bytes(image).length == 0) revert EmptyImage();

        bytes memory dataURI = abi.encodePacked(
            '{',
            '"name": "',
            name,
            '",',
            '"description": "',
            description,
            '",',
            '"image": "',
            image,
            '"',
            '}'
        );
        return string(
            abi.encodePacked(
                'data:application/json;base64,',
                Base64.encode(dataURI)
            )
        );
    }

    using Address for address payable;
}