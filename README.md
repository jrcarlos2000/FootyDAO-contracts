# ⚽ FootyDAO ⚽ : Uniting Sports Fans and Content Creators 

![Mask group](https://github.com/jrcarlos2000/FootyDAO-contracts/assets/75360886/44fa02f7-1eee-419e-a3e7-208b2ae7d2b0)

## Overview
FootyDAO leverages blockchain technology to revolutionize the sports world by connecting fans, players, and content creators. It offers a decentralized platform for hosting and joining sports games, establishing game rules, and fostering trust through history-based profiles. Additionally, FootyDAO provides a temporary marketplace for content sharing, facilitates live streaming of games to earn tokens, and details weekly rewards in FAN Tokens.

## Key Features
- **Decentralized Games**: Easily host or join blockchain-based sports games.
- **Trust Building**: Develop credible profiles based on your gaming history.
- **Marketplace**: A temporary hub for content creators and players.
- **FAN Token Rewards**: Weekly rewards system based on set criteria.
- **Live Streaming** : Broadcast games and earn tokens. (COMING SOON) 

## Multichain Capabilities
FootyDAO's multichain structure allows participants to join games from any blockchain. It also supports credit card transactions through on-ramp solutions.

## Repositories 🔐
- UI -> https://github.com/technophile-04/footyDAO-multichain
- Server -> https://github.com/jrcarlos2000/FootyDAO-api

## Live Application 👀
Experience FootyDAO live at [FootyDAO App](https://footy-dao.vercel.app/). 

## Design Resources 🇹🇷
Explore our design concepts [on Figma - FootyDAO](https://www.figma.com/file/CKBHdH4XdB1NaRWQEHiO54/FootyDAO?type=design&node-id=446-42&mode=design&t=l1m6Af4oEJJGtpDP-0)

## Pitch Deck ✨
View our pitch deck [here](https://pitch.com/v/FootyDAO-qkhhkg)

## Blockchain Contracts and Interoperability

- Base FootyDAO Contract - Optimism Goerli: Optimism : [Address](https://goerli-optimism.etherscan.io/address/0xA63184B6e04EF4f9D516feaF6Df65dF602B07a13)
### Chainlink CCIP transactions - Interoperability 
- Arbitrum Goerli , Mumbai , Base Goerli  ->  Optimism Goerli : [CCIP LINK](https://ccip.chain.link/address/0xA63184B6e04EF4f9D516feaF6Df65dF602B07a13)
### Chainlink Functions: Manage FAN token distribution on the Chiliz network : 
- Showcased [here](https://mumbai.polygonscan.com/address/0x7043dfb5db32ef820d0bb23e6f168c94e8be8fb2)
  
   - 📁 --> call `demoDistribute(:address)` and you will get some FAN tokens minted on chiliz network through functions.


## Deployments
FootyDAO is deployed across multiple testnets including Optimism Goerli, Polygon Mumbai, Arbitrum Goerli, and more.

- [Optimism Goerli Address](https://goerli-optimism.etherscan.io/address/0xA63184B6e04EF4f9D516feaF6Df65dF602B07a13)
- [Base Goerli Address](https://goerli.basescan.org/address/0x74E01d145AE90a431c7E90b6bDBFd61f007ea921)
- [Polygon Mumbai Address](https://mumbai.polygonscan.com/address/0xb5964669ae1E5617c62DE976c05CA3D1A63f9Ca4)
- [Arbitrum Goerli Address](https://goerli.arbiscan.io/address/0x659867Cc60b6aC93c112e55F384898017b2e4919)
- [Linea Testnet Address](https://explorer.goerli.linea.build/address/0x99370A50eFdB6Aab5CcaF741522FF0C07843DF49/contracts#address-tabs)
- [Celo Alfajores Address](https://explorer.celo.org/alfajores/address/0xf0a206dcaf5668fa5c824a01a2039d4cf07b771c)
- [Scroll Sepolia Address](https://sepolia.scrollscan.com/address/0x86695F03264E4676B896cdD590e013815f3493b2)


## Technology Stack
Chainlink CCIP and Functions
Chiliz Fan Tokens
IPFS
API3

## Technical Note

For developers, a small tweak is needed in the Chainlink CCIP contracts to avoid interface clashes. 
Modify the CCIPReceiver.sol in the ` node_modules/@chainlink/contracts-ccip/src/v0.8/ccip/applications/ directory as follows:

```solidity
  function supportsInterface(bytes4 interfaceId) public pure virtual override returns (bool) {
    return interfaceId == type(IAny2EVMMessageReceiver).interfaceId || interfaceId == type(IERC165).interfaceId;
  }
```

⚽⚽ FootyDAO is committed to transparent, decentralized, and fan-engaging sports experiences. Join us in this exciting journey ⚽⚽

