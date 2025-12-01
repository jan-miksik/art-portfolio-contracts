# About

The contract is meant for personal art creation and publishing NFTs, because of that some parts of the contract may give a centralized impression. The contract allow gradual minting of NFTs.

The general idea is once the image for the NFT is created, the owner mints the NFT and then lists it on marketplace, adds to auction or anything else.

The contract doesn't limit NFT amounts. The collection is meant for releasing NFTs gradually over time without any specific vision about the final amount.

## Technology Stack

### Core Technologies

- **Solidity**: `^0.8.20` - Smart contract programming language
- **Foundry**: Modern, fast, and portable toolkit for Ethereum application development
  - **Forge**: Testing framework and build tool
  - **Anvil**: Local Ethereum node for development
  - **Cast**: Swiss army knife for interacting with EVM smart contracts
  - [Foundry Book](https://book.getfoundry.sh/)

### Smart Contract Libraries

- **OpenZeppelin Contracts**: Battle-tested, community-audited smart contract library
  - `ERC721` - Non-fungible token standard implementation
  - `ERC721URIStorage` - Extension for storing token URIs
  - `ERC721Burnable` - Extension that allows token burning
  - `Ownable` - Access control with owner role
  - `ReentrancyGuard` - Protection against reentrancy attacks
  - `IERC2981` - Royalty standard interface
  - `SafeERC20` - Safe wrapper for ERC20 token operations
  - `Base64` - Base64 encoding utilities
  - `Address` - Address type utilities

### Standards Compliance

- **ERC-721**: Non-Fungible Token Standard
- **ERC-2981**: NFT Royalty Standard
- **ERC-165**: Standard Interface Detection

### Development Tools

- **Pre-commit Hooks**: Automated code quality checks
  - Forge formatting (`forge fmt`)
  - Forge build verification
  - Forge test execution
  - YAML validation

- **GitHub Actions**: Continuous Integration
  - Automated testing on push/PR
  - Foundry toolchain installation
  - Code formatting checks
  - Build verification

### Security & Audit Tools

- **Slither**: Static analysis framework for Solidity
  - Detects vulnerabilities and code quality issues
  - [GitHub Repository](https://github.com/crytic/slither)

- **Aderyn**: Advanced Solidity static analyzer
  - Comprehensive security analysis
  - [GitHub Repository](https://github.com/Cyfrin/aderyn)

### Testing

- **Unit Tests**: Comprehensive test suite covering all contract functions
- **Fuzz Tests**: Property-based testing with 1000 runs per test
- **Integration Tests**: Deployment script testing
- **Test Coverage**: Full coverage report generation available


## Roles

**Owner**: Author of the NFTs or maintainer of the contract. Can mint NFTs. Has responsibility for collection metadata, can eventually update them if necessary. Can renounce or move ownership of the contract to somebody else. Can set up Royalty receiver. Can change royalties percent.

**Collector**: Owns NFTs of the Various Pictures Collection. Buys these NFTs primarily through marketplaces. Can burn NFTs. Should pay royalties if selling NFTs, however this is not enforced and if collector and the marketplace allow it, it is possible to sell without royalties.

**Outsider**: Does not own NFTs of the Various Pictures Collection. Should not be able to do any writing operation on the contract.


## Deployment

The project includes deployment scripts for multiple networks:

- **Local Development**: `make deploy-local`
- **Sepolia Testnet**: `make deploy-sepolia`
- **Base Mainnet**: `make deploy-base`
- **Base Sepolia**: `make deploy-base-sepolia`

Deployment requires environment variables (see `.env.example` or Makefile for details).

## Audit

audit of the contracts:
[Art Portfolio Security audit.pdf](https://github.com/jan-miksik/art-portfolio-contracts/blob/652bb8e187cdb8020f41b277ab2c6f75f6ab6a63/Art%20Portfolio%20Security%20audit.pdf)


## Acknowledgments

### Tools & Resources

- **[Foundry](https://book.getfoundry.sh/)** - Development framework
- **[Cyfrin Updraft](https://updraft.cyfrin.io/courses)** - Smart contract security courses
- **[Slither](https://github.com/crytic/slither)** - Static analysis tool
- **[Aderyn](https://github.com/Cyfrin/aderyn)** - Advanced static analyzer
- **[OpenZeppelin](https://www.openzeppelin.com/)** - Smart contract library

## License

MIT License - see [LICENSE](LICENSE) file for details.
