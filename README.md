

# Ethernaut – Unique NFT Attack

## Technical Attack Description

This repository demonstrates an exploit of a vulnerable NFT minting contract that relies on flawed **EOA-only authorization** and incorrect assumptions about **state finality during ERC721 callbacks**, combined with **EIP-7702 delegated execution**.

The target contract attempts to restrict minting to EOAs using:

```solidity
require(tx.origin == msg.sender, "not an EOA");
```

and enforces uniqueness via:

```solidity
require(balanceOf(msg.sender) == 0, "only one unique NFT allowed");
```

These checks assume:

1. `tx.origin == msg.sender` implies a direct EOA call
2. `balanceOf` reflects finalized ownership state during execution

Both assumptions are invalid.

---

## Why EIP-7702 Breaks the EOA Check

Under **EIP-7702**, an EOA can temporarily delegate its execution authority to a smart contract.
When a transaction is executed under such a delegation:

* `tx.origin` remains the EOA
* `msg.sender` is also the EOA
* execution logic is controlled by a contract

As a result, contract-based logic can execute **while appearing indistinguishable from a direct EOA call**, fully bypassing the intended EOA-only restriction.

---

## Why the Uniqueness Check Fails

The NFT contract relies on:

```solidity
balanceOf(msg.sender) == 0
```

to enforce that each EOA can mint only one NFT.

However, during the ERC721 mint process, the `onERC721Received` hook is invoked **before the mint is fully finalized**. At this point:

* the first NFT has not yet been fully accounted for
* `balanceOf(msg.sender)` still returns `0`

This allows a **reentrant call** to `mintNFTEOA()` to succeed, even though a mint is already in progress.

---

## Attack Flow (EIP-7702)

1. **Deploy `SimpleDelegateContract`**
   The attacker deploys a delegate contract with the target NFT contract address hardcoded.

2. **Prepare Mint Call**
   A call to the vulnerable `mintNFTEOA()` function is prepared.

3. **Sign Delegation (EIP-7702)**
   The attacker signs an EIP-7702 delegation authorizing the delegate contract to execute transactions on behalf of their EOA.

4. **Execute Mint via Delegation**
   The delegate contract executes the mint call under the delegation.
   The `tx.origin == msg.sender` check passes because both resolve to the attacker’s EOA.

5. **ERC721 Callback Reentrancy**
   During the first mint, the `onERC721Received` hook of the delegate contract is invoked.

6. **Second Mint Before Finalization**
   Inside the hook, the delegate contract calls `mintNFTEOA()` again *before the first mint has completed*.
   At this moment:

   * `balanceOf(msg.sender) == 0`
   * the uniqueness check passes
   * a second NFT is minted

7. **Invariant Violation**
   Multiple NFTs are minted to the same EOA within a single transaction, violating the intended “one NFT per EOA” invariant.

8. **Verify Exploit Success**
   The script asserts that the attacker received multiple NFTs.

9. **Revoke Delegation**
   A new delegation to the zero address is attached and exercised via a trivial transaction, clearing the previous delegation.

---

## How to Use This Repository

### Prerequisites

* [Foundry](https://book.getfoundry.sh/getting-started/installation)
* An RPC endpoint and attacker private key configured in `.env`:

```text
ATTACKER_PK=<your_private_key>
RPC_URL=<your_rpc_url>
```

---

### Installation

```sh
git clone <repo_url>
cd ethernaut-unique-nft
forge install
```

---

### Running the Attack Script

```sh
forge clean
forge script script/AttackNFT.s.sol \
  --broadcast \
  --rpc-url $(cat .env | grep RPC_URL | cut -d'=' -f2)
```

The script:

* deploys the delegate contract
* executes the delegated exploit
* verifies successful over-minting

---

## Customization

* Update the target NFT address in:

  * `SimpleDelegateContract.sol`
  * `AttackNFT.s.sol`
* Adjust the maximum reentry count in `SimpleDelegateContract.sol` to mint additional NFTs if permitted by the target contract.


---

## Notes

* This repository is provided **for educational and security research purposes only**
* Do **not** use against mainnet contracts or with real funds

---

## License

MIT
