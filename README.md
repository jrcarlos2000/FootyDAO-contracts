## small tweak

change the following file : node_modules/@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol

```solidity
  function supportsInterface(bytes4 interfaceId) public pure virtual override returns (bool) {
    return interfaceId == type(IAny2EVMMessageReceiver).interfaceId || interfaceId == type(IERC165).interfaceId;
  }
```

## Sample Cross Chain Transactions

https://ccip.chain.link/address/0x52E058E5CD5D9a25117bCe2c467c521667b345b1

