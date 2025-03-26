## About

The contract is meant for own art creation and publishing NFTs, because of that some parts of the contract may do centralised impression. The contract should allow gradual minting of NFTs, which will have stored metadata on-chain. That makes the minting process itself easier and ensure higher immutability of NFT metadata.

The general idea is once the image for the NFT is created, the owner mint the NFT and then list it on marketplace, add to auction or anything else

The contract doesn’t limit NFT amounts. The collection is meant to releasing slowly NFTs during time without any specific vision about final amount

## what to do
1. setup env variables - rename .env.exmaple -> .env (the actuall env should always stay on local machine)
2. `$ make all` should install and prepeare all the stuff, details are in Makefile
3a. `$ make deploy-sepolia` deploy contract to Sepolia
3b. `$ make deploy-sepolia-trezor` deploy contract to Sepolia with Trezor hardware wallet
3c. `$ make deploy-base-trezor` deploy contract to Base with Trezor hardware wallet


## Thanks to tools and courses
- foundry https://book.getfoundry.sh/
- cyfrin https://updraft.cyfrin.io/courses
