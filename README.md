# Robots [NFT game]

An upgradeable P2E NFT game with custom ERC20 and ERC721 tokens.

## About

- This game allows to mint NFT robots with a custom ERC20 token ['Reward Token'](https://github.com/nzmpi/NFT-game-robots/blob/main/RewardToken.sol)
or with eth. 

- Players can combine two robots into stronger one by burning them.

- Players can multiply two robots to get a new robot with average stats. 

- Players can only mint 1 robot per address! But they can sell and buy robots using [the Robot market](https://github.com/nzmpi/NFT-game-robots/blob/main/RobotMarket.sol) 
or initialize an auction and bid on it.

- Players can create an arena and fight with other players. The winner gets two 'Fighting Fees' and additional new minted 'Reward Tokens'.

## Contracts

### RewardToken

 - The Reward Token is a standard ERC20 token with [OwnableRoles](https://github.com/Vectorized/solady/blob/main/src/auth/OwnableRoles.sol) from the solady library. 
 
 - This library allows to implement 'Minter Role', which will only allow the game contract to mint new tokens. 

 - Deploying provides the deployer with initial 100 'Reward Token'. 

### RobotsNFT

RobotsNFT is a ERC721 token with an additional struct:

    struct Robot {
       uint8 attack; 
       uint8 defence;
       uint32 readyTime;
    }

Every NFT has its own struct, that keeps all its stats:

    mapping (uint256 => Robot) public robots;
    
This contract is also deployed with OwnableRoles.

### Utils

 - Utils is a base contract. 
 - It is upgradeable and can receive NFTs using safeTransfer.
 - The contract uses [UUPSUpgradeable](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/proxy/utils/UUPSUpgradeable.sol) from the OZ library.
 - This contract stores all variables, structs, mappings, events, errors and basic functions.

### Factory

 - Factory inherits Utils.
 - Players can mint robots using the reward token or eth.
 - If a player by accident sends more eth than needed, the contract will return excess eth.
 - If a player sends eth to this contract directly, the contract will try to mint a new robot with eth. 

### Growing

 - Growing inherits Factory.
 - Players can combine two robots into stronger one by burning them.
 - Players can multiply two robots to get a new robot with average stats. 
 - Before calling any function a player should approve 'Fee' amount of the reward tokens, which (minus 'Tax') is burned.
 - To combine robots a player also needs to approve both robots.
 
 ### RobotMarket
 
 - RobotMarket inherits Growing.
 - Players can sell robots on the market or by creating an auction.
 - Other players can buy a robot or bid on auctions.
 - Every sale direct or through an auction pays a 'Tax'.
 
 ### Fighting
 
 - Fighting inherits RobotMarket.
 - Players can create an arena, which other players can join.
 - To create and join an arena players must pay 'Fee'.
 - The winner gets 2 'Fees' (minus 'Tax') and an additional reward.
 
To deploy the game one needs to deploy this contract with Proxy and with RewardToken and RobotsNFT's addresses.

After deploying the game, the owner of 'RewardToken' and 'RobotsNFT' needs to call 'setMinter' function in both contracts
with Proxy's address as an arg.

### V2

This contract is an example of an update of the game.

 - V2 inherits Fighting.
 - Provides a new way to generate 'dna' (but it's still *pseudorandom*).
 - Updating the game will keep all the values and mappings of the old contract.

