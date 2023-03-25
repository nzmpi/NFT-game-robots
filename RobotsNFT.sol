//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "solady/src/auth/OwnableRoles.sol";

/**
 * @title A simple NFT with OwnableRoles
 * @dev only an address with 'minterRole' can mint
 */
contract RobotsNFT is ERC721, OwnableRoles {
    uint256 constant minterRole = _ROLE_0;
    uint256 newRobotId;
    uint256 public totalSupply;

    struct Robot {
       uint8 attack; // value is in [1;10]
       uint8 defence; // value is in [1;10]
       uint32 readyTime;
    }

    // robotId => Robot
    mapping (uint256 => Robot) public robots;

    constructor () ERC721("Robots", "RBTS") {
        _initializeOwner(msg.sender);
    }

    function setMinter(address _newMinter) external onlyOwner {
        _grantRoles(_newMinter, minterRole);
    }

    function removeMinter(address _oldMinter) external onlyOwner {
        _removeRoles(_oldMinter, minterRole);
    }

    function mint(address _to, uint8 _attack, uint8 _defence, uint32 _readyTime) external onlyRoles(minterRole) returns (uint256) {
        _safeMint(_to, newRobotId);
        robots[newRobotId] = Robot(_attack, _defence, _readyTime);
        ++totalSupply;
        unchecked {return ++newRobotId-1;} // saves gas, no underflow, because '++' is always before '-1'
    }

    /**
     * @dev delete can be removed to keep stats of burned robots, 
     * also requires an update in getStats(uint256)
     */
    function burn(uint256 robotId) external {
        require(ownerOf(robotId) == msg.sender, "Not the owner!");
        _burn(robotId);
        unchecked {--totalSupply;} // saves gas, no underflow, because cannot burn nonexisting robot
        delete robots[robotId];
    }

    function updateReadyTime(uint256 robotId, uint32 newReadyTime) external onlyRoles(minterRole) {
        require(_exists(robotId), "The robot doesn't exist!");
        robots[robotId].readyTime = newReadyTime;
    }

    function getStats(uint256 robotId) external view returns (uint8 attack, uint8 defence, uint32 readyTime) {
        require(_exists(robotId), "The robot doesn't exist!"); // remove, if 'delete robots[]' in burn(uint256) is removed
        return (robots[robotId].attack, robots[robotId].defence, robots[robotId].readyTime);
    }
}