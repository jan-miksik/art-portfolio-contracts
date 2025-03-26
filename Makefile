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

all: clean remove install update build

# Default values -> local network
NETWORK_ARGS := --rpc-url http://localhost:8545 --private-key $(DEFAULT_ANVIL_KEY) --broadcast

TREZOR_ARGS := --trezor --mnemonic-indexes $(TREZOR_INDEX) --sender $(TREZOR_ADDRESS)

ifeq ($(findstring --network sepolia,$(ARGS)),--network sepolia)
	NETWORK_ARGS := --rpc-url $(SEPOLIA_RPC_URL) --private-key $(SEPOLIA_PRIVATE_KEY) --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv
	NETWORK_ARGS_TREZOR := --rpc-url $(SEPOLIA_RPC_URL) $(TREZOR_ARGS) --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv
endif

ifeq ($(findstring --network base,$(ARGS)),--network base)
	NETWORK_ARGS := --rpc-url $(BASE_RPC_URL) --private-key $(BASE_PRIVATE_KEY) --broadcast --verify --etherscan-api-key $(BASE_SCAN_API_KEY) -vvvv
	NETWORK_ARGS_TREZOR := --rpc-url $(BASE_RPC_URL) $(TREZOR_ARGS) --broadcast --verify --etherscan-api-key $(BASE_SCAN_API_KEY) -vvvv
endif

# Deployment commands
deploy-local:
	@forge script script/DeployVariousPicturesCollection.s.sol:DeployVariousPicturesCollection $(NETWORK_ARGS)

# Sepolia
deploy-sepolia:
	@forge script script/DeployVariousPicturesCollection.s.sol:DeployVariousPicturesCollection --network sepolia $(NETWORK_ARGS)

deploy-sepolia-trezor:
	@forge script script/DeployVariousPicturesCollection.s.sol:DeployVariousPicturesCollection --network sepolia $(NETWORK_ARGS_TREZOR)

# Base
deploy-base:
	@forge script script/DeployVariousPicturesCollection.s.sol:DeployVariousPicturesCollection --network base $(NETWORK_ARGS)

deploy-base-trezor:
	@forge script script/DeployVariousPicturesCollection.s.sol:DeployVariousPicturesCollection --network base $(NETWORK_ARGS_TREZOR)


# Verification
verify-contract :; forge verify-contract --chain-id ${CHAIN_ID} --num-of-optimizations 200 --watch ${CONTRACT_ADDRESS} ${CONTRACT_NAME} ${ETHERSCAN_API_KEY}

# Documentation
doc :; forge doc --serve --port 4000
 