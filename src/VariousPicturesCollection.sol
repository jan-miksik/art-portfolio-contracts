// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import "openzeppelin-contracts/contracts/interfaces/IERC2981.sol";
import "openzeppelin-contracts/contracts/utils/Strings.sol";
import "openzeppelin-contracts/contracts/utils/Base64.sol";
import "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/contracts/utils/Address.sol";

error EmptyTokenURI();
error ZeroAddress();
error NonexistentToken();
error NoEtherToWithdraw();
error NoTokensToWithdraw();
error TokenTransferFailed();
error SameRoyaltyReceiver();

contract VariousPicturesCollection is ERC721, IERC2981, Ownable, ReentrancyGuard {
    constructor() ERC721('Various Pictures', 'VP') Ownable(msg.sender) {
        _royaltyReceiver = owner();
    }

    /** MINTING **/
    
    uint256 private _nftCounter;

    function mintedNFTs() public view returns (uint256) {
        return _nftCounter;
    }

    /**
     * @dev Mints a new NFT with specified metadata components
     * @param to The address that will receive the minted NFT
     * @param name The name of the NFT
     * @param description A detailed description of the NFT
     * @param image The URI pointing to the NFT's image
     * @notice Only the contract owner can call this function
     * @notice All parameters must be non-empty strings
     */
    function safeMintWithMetadata(
        address to,
        string memory name,
        string memory description,
        string memory image
    ) public onlyOwner nonReentrant {
        string memory uri = createTokenURI(name, description, image);
        safeMintWithURI(to, uri);
    }

    /**
     * @dev Mints a new NFT with a complete tokenURI
     * @param to The address that will receive the minted NFT
     * @param tokenURImetadata The complete URI containing the NFT's metadata
     * @notice Only the contract owner can call this function
     * @notice The tokenURI must be a non-empty string
     * @notice The recipient address cannot be the zero address
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

    /// @dev Collection metadata based on opensea standards
    function contractURI() public view returns (string memory) {
        bytes memory dataURI = abi.encodePacked(
            '{',
            '"name": "Various pictures",',
            '"description": "Various pictures and different topics",',
            '"image": "ipfs://bafybeidr3ssynrir4wez5bayz36qxk557irrrkwsplxeq3xdwieysxzlqq",', // TODO
            '"external_link": "https://janmiksik.ooo",',
            '"seller_fee_basis_points": 500,',
            '"fee_recipient": "',
            Strings.toHexString(uint160(_royaltyReceiver), 20),
            '"',
            '}'
        );
        return
            string(
                abi.encodePacked(
                    'data:application/json;base64,',
                    Base64.encode(dataURI)
                )
            );
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
        require(bytes(name).length > 0, "Name cannot be empty");
        require(bytes(description).length > 0, "Description cannot be empty");
        require(bytes(image).length > 0, "Image URI cannot be empty");

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