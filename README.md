## Repositories 🔐

- UI -> https://github.com/technophile-04/footyDAO-multichain
- Server -> https://github.com/jrcarlos2000/FootyDAO-api

## Live APP 👀

https://footy-dao.vercel.app/

## Figma 🇹🇷

https://www.figma.com/file/CKBHdH4XdB1NaRWQEHiO54/FootyDAO?type=design&node-id=446-42&mode=design&t=l1m6Af4oEJJGtpDP-0

## Pitch Deck ✨

https://pitch.com/v/FootyDAO-qkhhkg


## Base FootyDAO contract - Optimism Goerli

https://goerli-optimism.etherscan.io/address/0xA63184B6e04EF4f9D516feaF6Df65dF602B07a13

## Chainlink CCIP transactions - Interoperability

Arbitrum Goerli , Mumbai , Base Goerli  ->  Optimism Goerli

https://ccip.chain.link/address/0x52E058E5CD5D9a25117bCe2c467c521667b345b1

## Chainlink CCIP x Functions - Used to send rewards on chiliz network on schedule

https://mumbai.polygonscan.com/address/0x7043dfb5db32ef820d0bb23e6f168c94e8be8fb2

- call `demoDistribute(:address)` and you will get some FAN tokens minted on chiliz network through functions.

## Deployments 

- Optimism Goerli : https://goerli-optimism.etherscan.io/address/0xA63184B6e04EF4f9D516feaF6Df65dF602B07a13
- Base Goerli : https://goerli.basescan.org/address/0x74E01d145AE90a431c7E90b6bDBFd61f007ea921
- Polygon Mumbai : https://mumbai.polygonscan.com/address/0xb5964669ae1E5617c62DE976c05CA3D1A63f9Ca4
- Arbitrum Goerli : https://goerli.arbiscan.io/address/0x659867Cc60b6aC93c112e55F384898017b2e4919

## Technologies used

- Chainlink CCIP
- Chainlink Functions
- Chiliz Fan Tokens
- IPFS
- API3

### small tweak

Change the following file : `node_modules/@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol`

Due to a clash with ERC721 supportsInterface function, we need to add the following to the CCIPReceiver contract

```solidity
  function supportsInterface(bytes4 interfaceId) public pure virtual override returns (bool) {
    return interfaceId == type(IAny2EVMMessageReceiver).interfaceId || interfaceId == type(IERC165).interfaceId;
  }
```