//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./RewardToken.sol";
import "./RobotsNFT.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

/**
* @title A Utils contract 
* @dev This contract is upgradeable and can receive NFTs using safeTransfer
* This contract stores all variables, structs, mappings, events, errors and basic functions
*/
contract Utils is UUPSUpgradeable, OwnableUpgradeable, IERC721Receiver {
    /**
    * @dev Not using uint256 reduces number of storage slots, 
    * which reduces gas usage for a deployment 
    * @notice Taxes are in %, e.g. marketTax = 1 => contract gets 1% from every sale
    * @notice Fees are in ether, i.e. 10**18
    */
    uint8 public marketTax;
    uint8 public auctionTax;
    uint8 public fightingTax;
    uint8 public combiningTax;
    uint8 public multiplyingTax;
    uint32 public multiplyingCooldown; 
    uint128 public multiplyingFee;
    uint128 public fightingFee;
    uint128 public reward;
    uint128 public combiningFee;    
    uint128 public mintingFeeInEth;
    uint128 public mintingFeeInToken;    
    uint128 newArenaId;

    RewardToken public token;
    RobotsNFT public nft;

    struct Auction {
        uint32 endTime;
        address highestBidder;
        uint256 highestBid;
    }
    struct Arena {
        uint8 isArenaActive;
        uint8 isFighting;
        uint128 creatorsRobotId;
    }

    mapping (address => uint256) public hasMinted;  // minter => 0 or 1
    mapping (uint256 => uint256) public market;     // robotId => price
    mapping (uint256 => Auction) public auctions;   // robotId => Auction
    mapping (uint256 => Arena) arenas;              // arenaId => Arena
    mapping (uint256 => address) oldOwner;          // robotId => old owner of robot

    event combineRobotsEvent(uint256 robotId1, uint256 robotId2, uint256 newRobotId, uint8 attack, uint8 defence);
    event multiplyRobotsEvent(uint256 robotId1, uint256 robotId2, uint256 newRobotId, uint8 attack, uint8 defence, uint32 ReadyTime);
    event newCombiningTaxEvent(uint8 oldCombiningTax, uint8 newCombiningTax);
    event newCombiningFeeEvent(uint128 oldCombiningFee, uint128 newCombiningFee);
    event newMultiplyingTaxEvent(uint8 oldMultiplyingTax, uint8 newMultiplyingTax);
    event newMultiplyingFeeEvent(uint128 oldMultiplyingFee, uint128 newMultiplyingFee);
    event newMultiplyingCooldownEvent(uint32 oldMultiplyingCooldown, uint32 newMultiplyingCooldown);
    event robotMintEvent(uint256 robotId, uint8 attack, uint8 defence);
    event withdrawEvent(uint256 amountEth, uint256 amountToken);
    event newMintingFeeInEthEvent(uint128 oldMintingFeeInEth, uint128 newMintingFeeInEth);
    event newMintingFeeInTokenEvent(uint128 oldMintingFeeInToken, uint128 newMintingFeeInToken);
    event createArenaEvent(address indexed creator, uint256 robotId, uint128 arenaId);
    event removeArenaEvent(address indexed creator, uint128 arenaId);
    event fightingEvent(address indexed winner, uint256 winnerRobotId, address indexed loser, uint256 loserRobotId);
    event newFightingTaxEvent(uint8 oldFightingTax, uint8 newFightingTax);
    event newFightingFeeEvent(uint128 oldFightingFee, uint128 newFightingFee);
    event newRewardEvent(uint128 oldReward, uint128 newReward);
    event putOnMarketEvent(address indexed seller, uint256 robotId, uint256 price);
    event withdrawFromMarketEvent(address indexed seller, uint256 robotId);
    event buyRobotEvent(address indexed buyer, uint256 robotId, uint256 price);
    event putOnAuctionEvent(address indexed seller, uint256 robotId, uint256 startingPrice, uint32 auctionTime);
    event withdrawFromAuctionEvent(address indexed seller, uint256 robotId);
    event bidOnAuctionEvent(address indexed bidder, uint256 robotId, uint256 bid);
    event endAuctionEvent(address indexed ender, uint256 robotId);
    event newMarketTaxEvent(uint8 oldMarketTax, uint8 newMarketTax);
    event newAuctionTaxEvent(uint8 oldAuctionTax, uint8 newAuctionTax);
    event newRewardTokenEvent(address oldRewardToken, address newRewardToken);

    error TaxIsTooHigh();
    error FailedEthTransfer();
    error AlreadyMinted();
    error NotOwnerOf(uint256 robotId);
    error NotReadyToMultiply(uint256 robotId);
    error CannotSellForZero();
    error RobotIsNotOnMarket(uint256 robotId);
    error RobotIsNotOnAuction(uint256 robotId);
    error BidIsSmall(uint256 highestBid);
    error ArenaIsNotActive(uint128 arenaId);
    error SomeoneIsFighting(uint128 arenaId);

    // Initialize proxy, more info in UUPSUpgradeable.sol
    function initialize(address _token, address _nft) external initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
        token = RewardToken(_token);
        nft = RobotsNFT(_nft);
        marketTax = 1;
        auctionTax = 1;
        fightingTax = 1;
        combiningTax = 1;
        multiplyingTax = 1;
        multiplyingCooldown = 1 days;    
        mintingFeeInEth = 1 ether;
        mintingFeeInToken = 1 ether;
        combiningFee = 1 ether;
        multiplyingFee = 1 ether;
        fightingFee = 1 ether;
        reward = 1 ether;
    }

    // Only owner can withdraw eth and tokens from this contract
    function withdraw() external virtual onlyOwner {
        uint256 _amountEth = address(this).balance;
        uint256 _amountToken = token.balanceOf(address(this));

        if (_amountEth > 0) {
            (bool sent, ) = owner().call{value: _amountEth}("");
            if(!sent) revert FailedEthTransfer();
        }
        if (_amountToken > 0) {
            token.transfer(owner(), _amountToken);
        }
        emit withdrawEvent(_amountEth, _amountToken);
    }

    // Fucntions to set fees and taxes
    function setMintingFeeInEth(uint128 _newMintingFeeInEth) external onlyOwner {
        emit newMintingFeeInEthEvent(mintingFeeInEth, _newMintingFeeInEth);
        mintingFeeInEth = _newMintingFeeInEth;
    }

    function setMintingFeeInToken(uint128 _newMintingFeeInToken) external onlyOwner {
        emit newMintingFeeInTokenEvent(mintingFeeInToken, _newMintingFeeInToken);
        mintingFeeInToken = _newMintingFeeInToken;
    }

    function setCombiningFee(uint128 _newCombiningFee) external onlyOwner {
        emit newCombiningFeeEvent(combiningFee, _newCombiningFee);
        combiningFee = _newCombiningFee;
    }

    function setMultiplyingFee(uint128 _newMultiplyingFee) external onlyOwner {
        emit newMultiplyingFeeEvent(multiplyingFee, _newMultiplyingFee);
        multiplyingFee = _newMultiplyingFee;
    }

    function setFightingFee(uint128 _newFightingFee) external onlyOwner {
        emit newFightingFeeEvent(fightingFee, _newFightingFee);
        fightingFee = _newFightingFee;
    }

    function setMarketTax(uint8 _newMarketTax) external onlyOwner {
        if (_newMarketTax > 100) revert TaxIsTooHigh();
        emit newMarketTaxEvent(marketTax, _newMarketTax);
        marketTax = _newMarketTax;
    }

    function setAuctionTax(uint8 _newAuctionTax) external onlyOwner {
        if (_newAuctionTax > 100) revert TaxIsTooHigh();
        emit newAuctionTaxEvent(auctionTax, _newAuctionTax);
        auctionTax = _newAuctionTax;
    }

    function setFightingTax(uint8 _newFightingTax) external onlyOwner {
        if (_newFightingTax > 100) revert TaxIsTooHigh();
        emit newFightingTaxEvent(fightingTax, _newFightingTax);
        fightingTax = _newFightingTax;
    }

    function setCombiningTax(uint8 _newCombiningTax) external onlyOwner {
        if (_newCombiningTax > 100) revert TaxIsTooHigh();
        emit newCombiningTaxEvent(combiningTax, _newCombiningTax);
        combiningTax = _newCombiningTax;
    }

    function setMultiplyingTax(uint8 _newMultiplyingTax) external onlyOwner {
        if (_newMultiplyingTax > 100) revert TaxIsTooHigh();
        emit newMultiplyingTaxEvent(multiplyingTax, _newMultiplyingTax);
        multiplyingTax = _newMultiplyingTax;
    }

    // Set new multiplying cooldown
    function setMultiplyingCooldown(uint32 _newCooldown) external onlyOwner {
        emit newMultiplyingCooldownEvent(multiplyingCooldown, _newCooldown);
        multiplyingCooldown = _newCooldown;
    }

    function setReward(uint128 _newReward) external onlyOwner {
        emit newRewardEvent(reward, _newReward);
        reward = _newReward;
    }

    function setRewardToken(address _newRewardToken) external onlyOwner {
        emit newRewardTokenEvent(address(token), _newRewardToken);
        token = RewardToken(_newRewardToken);
    }

    // Should be overridden in new versions 
    function getVersion() external pure virtual returns (string memory) {
        return "Version 1.0";
    }

    // Returns 10 or lower
    function _max10(uint8 x) internal pure returns (uint8) {
        return x > 10 ? 10 : x;
    }

    // have to be here to be able to receive ERC721 tokens using safeTransfer
    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    // have to be here to be able to upgrade
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}