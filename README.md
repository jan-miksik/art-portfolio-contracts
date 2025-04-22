## About

The contract is meant for personal art creation and publishing NFTs, because of that some parts of the contract may give a centralized impression. The contract should allow gradual minting of NFTs, which will have stored metadata on-chain. This makes the minting process easier and ensures higher immutability of NFT metadata.

The general idea is once the image for the NFT is created, the owner mints the NFT and then lists it on marketplace, adds to auction or anything else.

The contract doesn't limit NFT amounts. The collection is meant for releasing NFTs gradually over time without any specific vision about the final amount.

### Roles
 **Owner**: Author of the NFTs or maintainer of the contract. Can mint NFTs. Has responsibility for collection metadata, can eventually update them if necessary. Can renounce or move ownership of the contract to somebody else. Can set up Royalty receiver. Can change royalties percent.

 **Collector**: Owns NFTs of the Various Pictures Collection. Buys these NFTs primarily through marketplaces. Can burn NFTs. Should pay royalties if selling NFTs, however this is not enforced and if collector and the marketplace allow it, it is possible to sell without royalties.

 **Outsider**: Does not own NFTs of the Various Pictures Collection. Should not be able to do any writing operation on the contract.


### Thanks to tools and courses
- foundry https://book.getfoundry.sh/
- cyfrin https://updraft.cyfrin.io/courses
