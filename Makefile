-include .env

DEFAULT_ANVIL_KEY := 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

# Build & Test commands
build :; forge build
test :; forge test
coverage :; forge coverage
gas-report :; forge test --gas-report
format :; forge fmt
clean :; forge clean
snapshot :; forge snapshot

# Update dependencies
update :; forge update

# Remove modules and build artifacts
remove :; rm -rf .git/modules/* && \
	rm -rf lib && \
	rm -rf cache && \
	rm -rf out && \
	rm -rf broadcast

# Install dependencies
install :; forge install OpenZeppelin/openzeppelin-contracts --no-commit && \
	forge install foundry-rs/forge-std@v1.8.2 --no-commit

# Local development
anvil :; anvil -m 'test test test test test test test test test test test junk' --steps-tracing --block-time 1

# Development tools
install-precommit:
	pre-commit install

check: install
	pre-commit run --all-files

# You can also add this to your all target
all: clean remove install update build install-precommit

# Default values -> local network
NETWORK_ARGS := --rpc-url http://localhost:8545 --private-key $(DEFAULT_ANVIL_KEY) --broadcast

# Hardware wallet configurations
TREZOR_ARGS := --trezor --mnemonic-indexes $(TREZOR_INDEX) --sender $(TREZOR_ADDRESS)

# Network specific arguments
SEPOLIA_ARGS := --rpc-url $(SEPOLIA_RPC_URL) --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv
BASE_ARGS := --rpc-url $(BASE_RPC_URL) --broadcast --verify --etherscan-api-key $(BASE_SCAN_API_KEY) -vvvv

# Private key specific arguments
SEPOLIA_KEY_ARGS := $(SEPOLIA_ARGS) --private-key $(SEPOLIA_PRIVATE_KEY)
BASE_KEY_ARGS := $(BASE_ARGS) --private-key $(BASE_PRIVATE_KEY)

# Trezor specific arguments
SEPOLIA_TREZOR_ARGS := $(SEPOLIA_ARGS) $(TREZOR_ARGS)
BASE_TREZOR_ARGS := $(BASE_ARGS) $(TREZOR_ARGS)

# Deployment commands
deploy-local:
	@forge script script/DeployVariousPicturesCollection.s.sol:DeployVariousPicturesCollection $(NETWORK_ARGS)

# Sepolia
deploy-sepolia:
	@forge script script/DeployVariousPicturesCollection.s.sol:DeployVariousPicturesCollection $(SEPOLIA_KEY_ARGS)

deploy-sepolia-trezor:
	@forge script script/DeployVariousPicturesCollection.s.sol:DeployVariousPicturesCollection $(SEPOLIA_TREZOR_ARGS)

# Base
deploy-base:
	@forge script script/DeployVariousPicturesCollection.s.sol:DeployVariousPicturesCollection $(BASE_KEY_ARGS)

deploy-base-trezor:
	@forge script script/DeployVariousPicturesCollection.s.sol:DeployVariousPicturesCollection $(BASE_TREZOR_ARGS)


# Verification
verify-contract :; forge verify-contract --chain-id ${CHAIN_ID} --num-of-optimizations 200 --watch ${CONTRACT_ADDRESS} ${CONTRACT_NAME} ${ETHERSCAN_API_KEY}

# Documentation
doc :; forge doc --serve --port 4000
