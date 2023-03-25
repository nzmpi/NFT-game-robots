//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Fighting.sol";

/**
 * @title An example of an update
 */
contract V2 is Fighting {
    
    function _generateRandomDna() internal view override virtual returns (uint256) {
        return uint256(keccak256(abi.encodePacked(msg.sender, blockhash(block.number - 1))));
    }
    
    function getVersion() external pure override virtual returns (string memory) {
        return "Version 2.0";
    }
}