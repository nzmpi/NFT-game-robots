# Robots [NFT game]

A small upgradeable P2E NFT game with custom ERC20 and ERC721 tokens.

## About

- This game allows to mint NFT robots with a custom ERC20 token ['Reward Token'](https://github.com/nzmpi/NFT-game-robots/blob/main/RewardToken.sol)
or with eth. 

- Players can combine two robots into stronger one by burning them.

- Players can multiply two robots to get a new robot with average stats. 

- Players can only mint 1 robot per address! But they can sell and buy robots using [the Robot market](https://github.com/nzmpi/NFT-game-robots/blob/main/RobotMarket.sol) 
or initialize an auction and bid on it.

- Players can create an arena and fight with other players. The winner gets the 'Fighting Fee' and additional new minted 'Reward Tokens'.

## Contracts

### RewardToken

The Reward Token is a standard ERC20 token with OwnableRoles from [the solady library](https://github.com/Vectorized/solady). 
This library allows to implement 'Minter Role', which will only allow the game contract to mint new tokens. 
Deploying provides the deployer with initial 100 'Reward Token'. 

### RobotsNFT

RobotsNFT is a ERC721 token with an additional struct:

    struct Robot {
       uint8 attack; 
       uint8 defence;
       uint32 readyTime;
    }

Every NFT has its own struct, that keeps all stats:

    mapping (uint256 => Robot) public robots;
    
This contract is also deployed with OwnableRoles.

### Utils

 - Utils is a base contract. 
 - It is upgradeable and can receive NFTs using safeTransfer.
 - The contract uses 'UUPSUpgradeable' from the OZ library.
 - This contract stores all variables, structs, mappings, events, errors and basic functions.

To deploy the game one needs to deploy it with Proxy and with RewardToken and RobotsNFT's addresses.

### Factory

 - Factory inherits Utils.
 - Players can mint robots using the reward token or eth.
 - If a player by accident sends more eth than needed, the contract will return excess eth.
 - If a player sends eth to this contract directly, the contract will try to mint a new robot with eth. 

And repeat

    until finished

End with an example of getting some data out of the system or using it
for a little demo

## Running the tests

Explain how to run the automated tests for this system

### Sample Tests

Explain what these tests test and why

    Give an example

### Style test

Checks if the best practices and the right coding style has been used.

    Give an example

## Deployment

Add additional notes to deploy this on a live system

## Built With

  - [Contributor Covenant](https://www.contributor-covenant.org/) - Used
    for the Code of Conduct
  - [Creative Commons](https://creativecommons.org/) - Used to choose
    the license

## Contributing

Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code
of conduct, and the process for submitting pull requests to us.

## Versioning

We use [Semantic Versioning](http://semver.org/) for versioning. For the versions
available, see the [tags on this
repository](https://github.com/PurpleBooth/a-good-readme-template/tags).

## Authors

  - **Billie Thompson** - *Provided README Template* -
    [PurpleBooth](https://github.com/PurpleBooth)

See also the list of
[contributors](https://github.com/PurpleBooth/a-good-readme-template/contributors)
who participated in this project.

## License

This project is licensed under the [CC0 1.0 Universal](LICENSE.md)
Creative Commons License - see the [LICENSE.md](LICENSE.md) file for
details

## Acknowledgments

  - Hat tip to anyone whose code is used
  - Inspiration
  - etc

