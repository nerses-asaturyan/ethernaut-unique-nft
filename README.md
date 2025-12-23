# Ethernaut Unique NFT Attack

## Attack Flow

This repository demonstrates a reentrancy-based attack on a vulnerable NFT minting contract using a delegate contract and Foundry's delegation system. The attack leverages the ERC721 receiver hook to recursively mint multiple NFTs in a single transaction.

### Steps:
1. **Deploy SimpleDelegateContract**: The attacker deploys a delegate contract with the target NFT contract address hardcoded.
2. **Prepare Mint Call**: The attacker prepares a call to the vulnerable `mintNFTEOA()` function of the NFT contract.
3. **Sign Delegation**: The attacker signs a delegation allowing the delegate contract to execute transactions on their behalf.
4. **Execute Mint via Delegate**: The delegate contract executes the mint call. When the NFT is minted, the contract's `onERC721Received` hook is triggered.
5. **Reentrancy in onERC721Received**: Inside the hook, the contract checks a reentry counter and, if allowed, calls `mintNFTEOA()` again, recursively minting more NFTs.
6. **Verify Attack Success**: The script checks that the attacker received multiple NFTs.
7. **Revoke Delegation**: The attacker attaches a new delegation to the zero address and triggers a simple transfer to exercise the new authorization and revoke the previous delegation.

## How to Use This Repo

### Prerequisites
- [Foundry](https://book.getfoundry.sh/getting-started/installation) installed
- RPC node URL and attacker private key set in `.env` file:
  ```
  ATTACKER_PK=<your_private_key>
  RPC_URL=<your_rpc_url>
  ```

### Installation
1. Clone the repository:
	```sh
	git clone <repo_url>
	cd ethernaut-unique-nft
	```
2. Install dependencies:
	```sh
	forge install
	```

### Running the Attack Script
1. Clean previous builds:
	```sh
	forge clean
	```
2. Run the attack script:
	```sh
	forge script script/AttackNFT.s.sol --broadcast --rpc-url $(cat .env | grep RPC_URL | cut -d'=' -f2)
	```
	- The script will deploy the delegate contract, perform the attack, and verify the result.

### Customization
- You can change the target NFT contract address by editing the hardcoded address in `SimpleDelegateContract.sol` and `AttackNFT.s.sol`.
- Adjust the maximum reentry count in `SimpleDelegateContract.sol` to mint more NFTs if the vulnerability allows.

### Notes
- This repo is for educational and testing purposes only.
- Do not use on mainnet or with real funds.

## License
MIT