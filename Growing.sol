//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Factory.sol";

/**
 * @title A contract to create new robots
 */
contract Growing is Factory {
    /** 
     * Takes 2 robots and combines them into new one
     * @dev 2 robots and 'combiningFee' tokens must be approved
     */
    function combineRobots(uint256 robotId1, uint256 robotId2) external virtual returns (uint256 robotId) {
        if (nft.ownerOf(robotId1) != msg.sender) revert NotOwnerOf(robotId1);
        if (nft.ownerOf(robotId2) != msg.sender) revert NotOwnerOf(robotId2);

        nft.safeTransferFrom(msg.sender, address(this), robotId1);
        nft.safeTransferFrom(msg.sender, address(this), robotId2);
        token.transferFrom(msg.sender, address(this), combiningFee);
        (uint8 attack1, uint8 defence1,) = nft.getStats(robotId1);
        (uint8 attack2, uint8 defence2,) = nft.getStats(robotId2);
        
        // _max10 returns 10 or less
        uint8 newAttack = _max10(attack1 + attack2);
        uint8 newDefence = _max10(defence1 + defence2);
        robotId = nft.mint(msg.sender, newAttack, newDefence, 0);
        
        // Burns 2 initial robots and (tokens-Tax)
        nft.burn(robotId1);
        nft.burn(robotId2);
        token.burn(combiningFee*(1000-10*combiningTax)/1000);
        emit combineRobotsEvent(robotId1, robotId2, robotId, newAttack, newDefence);
    }

    /**
     * Takes 2 robots and creates a new one
     * @dev 2 robots and 'multiplyingFee' tokens must be approved
     */
    function multiplyRobots(uint256 robotId1, uint256 robotId2) external virtual returns (uint256 robotId) {
        if (nft.ownerOf(robotId1) != msg.sender) revert NotOwnerOf(robotId1);
        if (nft.ownerOf(robotId2) != msg.sender) revert NotOwnerOf(robotId2);

        (uint8 attack1, uint8 defence1, uint32 readyTime1) = nft.getStats(robotId1);
        (uint8 attack2, uint8 defence2, uint32 readyTime2) = nft.getStats(robotId2);
        if (readyTime1 >= block.timestamp) revert NotReadyToMultiply(robotId1);
        if (readyTime2 >= block.timestamp) revert NotReadyToMultiply(robotId2);

        token.transferFrom(msg.sender, address(this), multiplyingFee);
        token.burn(multiplyingFee*(1000-10*multiplyingTax)/1000);

        uint8 newAttack = (attack1 + attack2)/2;
        uint8 newDefence = (defence1 + defence2)/2;
        uint32 newReadyTime = uint32(block.timestamp) + multiplyingCooldown;
        robotId = nft.mint(msg.sender, newAttack, newDefence, newReadyTime);

        nft.updateReadyTime(robotId1, newReadyTime);
        nft.updateReadyTime(robotId2, newReadyTime);
        emit multiplyRobotsEvent(robotId1, robotId2, robotId, newAttack, newDefence, newReadyTime);
    }
}