//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./RobotMarket.sol";

/*
* @title A contract for fighting with robots
*/
contract Fighting is RobotMarket {

    // create an arena by paying 'fightingFee'
    // number of arenas is not limited
    function createArena(uint256 robotId) external virtual {
        address owner = nft.ownerOf(robotId);
        if (owner != msg.sender) revert NotOwnerOf(robotId);

        token.transferFrom(owner, address(this), fightingFee);
        arenas[newArenaId] = Arena(1, 0, robotId);
        emit createArenaEvent(owner, robotId, newArenaId);
        ++newArenaId;
    }

    function removeArena(uint128 arenaId) external virtual {
        Arena memory tempArena = arenas[arenaId];
        if (tempArena.isArenaActive == 0) revert ArenaIsNotActive(arenaId);

        uint256 robotId = tempArena.creatorRobotId;
        address owner = nft.ownerOf(robotId);
        require(owner == msg.sender, "Not the creator!");
        if (tempArena.isFighting == 1) revert SomeoneIsFighting(arenaId);

        delete arenas[arenaId];
        token.transfer(owner, fightingFee);
        emit removeArenaEvent(owner, arenaId);
    }

    // anyone can pick any free arena and fight the creator by paying 'fightingFee'
    function enterArena(uint128 arenaId, uint256 attackerRobotId) external virtual {
        address attacker = nft.ownerOf(attackerRobotId);
        if (attacker != msg.sender) revert NotOwnerOf(attackerRobotId);

        Arena memory tempArena = arenas[arenaId];
        if (tempArena.isArenaActive == 0) revert ArenaIsNotActive(arenaId);
        if (tempArena.isFighting == 1) revert SomeoneIsFighting(arenaId);

        token.transferFrom(attacker, address(this), fightingFee);
        arenas[arenaId].isFighting = 1;

        uint256 defenderRobotId = tempArena.creatorRobotId;
        address defender = nft.ownerOf(defenderRobotId);
        bool attackerIsWinner = _fighting(defenderRobotId, attackerRobotId, arenaId);
        
        // reward the winner with (2*fightingFee-tax) + mint 'reward'
        if (attackerIsWinner) {
            token.transfer(attacker, 2*fightingFee*(1000-10*fightingTax)/1000);
            token.mint(attacker, reward);
            emit fightingEvent(attacker, attackerRobotId, defender, defenderRobotId);
        } else {
            token.transfer(defender, 2*fightingFee*(1000-10*fightingTax)/1000);
            token.mint(defender, reward);
            emit fightingEvent(defender, defenderRobotId, attacker, attackerRobotId);
        }

        delete arenas[arenaId];        
    }

    // returns true if an attacker is a winner, false if a defender
    function _fighting(uint256 defenderRobotId, uint256 attackerRobotId, uint128 arenaId) internal view virtual returns (bool) {
        (uint8 defenderAttack, uint8 defenderDefence,) = nft.getStats(defenderRobotId);
        (uint8 attackerAttack, uint8 attackerDefence,) = nft.getStats(attackerRobotId);
        uint256 winner = 1;
        if (attackerAttack > defenderDefence) {
            unchecked {++winner;} // max can only be 2
        } 
        if (defenderAttack > attackerDefence) {
            unchecked {--winner;} // min can only be 0
        }
        if (winner == 2) return true; // only the attacker won
        if (winner == 0) return false; // only the defender won
        
        // if both won or both lost pseudorandom decides the winner
        uint256 rand = uint256(keccak256(abi.encodePacked(defenderRobotId, attackerRobotId, arenaId))) % 2;
        return rand == 0 ? true : false;
    }
}