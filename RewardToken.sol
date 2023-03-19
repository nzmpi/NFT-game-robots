//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "solady/src/auth/OwnableRoles.sol";

/**
* @title A simple reward token with OwnableRoles
* @dev only an address with 'minterRole' can mint
*/
contract RewardToken is ERC20, OwnableRoles {
    uint256 constant minterRole = _ROLE_0;
    uint256 constant INITIAL_OWNER_BALANCE = 100 ether;
    
    constructor () ERC20("RewardToken", "RWT") {
        _initializeOwner(msg.sender);
        _mint(msg.sender, INITIAL_OWNER_BALANCE);
    }

    function setMinter(address _newMinter) external onlyOwner {
        _grantRoles(_newMinter, minterRole);
    }

    function removeMinter(address _oldMinter) external onlyOwner {
        _removeRoles(_oldMinter, minterRole);
    }    

    function mint(address account, uint256 amount) external onlyRoles(minterRole) {
        _mint(account, amount);
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }
}