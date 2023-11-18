## small tweak

change the following file : node_modules/@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol

```solidity
  function supportsInterface(bytes4 interfaceId) public pure virtual override returns (bool) {
    return interfaceId == type(IAny2EVMMessageReceiver).interfaceId || interfaceId == type(IERC165).interfaceId;
  }
```
