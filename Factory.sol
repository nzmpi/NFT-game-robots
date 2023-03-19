//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Utils.sol";

/**
* @title A contract to mint robots
* Each address can only mint once either with eth or with the reward tokens
* @dev To mint a unique robot !!pseudorandom!! is used
*/
contract Factory is Utils {

    function mintRobotWithEth() public payable virtual {
        if (hasMinted[msg.sender] != 0) revert AlreadyMinted();
        require(msg.value >= mintingFeeInEth, "Not enough eth to mint!");
        uint256 dna = _generateRandomDna();
        _buildRobot(dna);

        // return excess eth
        if (msg.value - mintingFeeInEth > 0) {
            (bool sent, ) = msg.sender.call{value: msg.value - mintingFeeInEth}("");
            if(!sent) revert FailedEthTransfer();
        }
    }

    function mintRobotWithToken() external virtual {
        if (hasMinted[msg.sender] != 0) revert AlreadyMinted();
        token.transferFrom(msg.sender, address(this), mintingFeeInToken);
        uint256 dna = _generateRandomDna();
        _buildRobot(dna);
    }

    // pseudorandom is used to generate dna
    function _generateRandomDna() internal view virtual returns (uint256) {
        return uint256(keccak256(abi.encodePacked(msg.sender)));        
    }

    // last digit of dna is 'attack' and next digit is 'defence'
    function _buildRobot(uint256 dna) internal virtual {
        uint8 _attack = uint8(dna%10)+1;
        dna = dna/10; 
        uint8 _defence = uint8(dna%10)+1;
        uint256 robotId = nft.mint(msg.sender, _attack, _defence, 0);
        hasMinted[msg.sender] = 1;
        emit robotMintEvent(robotId, _attack, _defence);
    }

    // have to be here and not in Utils.sol 
    // to be able to call mintRobotWithEth()
    receive() external payable {
        mintRobotWithEth();
    }
}
