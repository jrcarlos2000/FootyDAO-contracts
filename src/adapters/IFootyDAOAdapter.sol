pragma solidity ^0.8.18;

contract IFootyDAOAdapter {
    error NotEnoughBalance(uint256 currentBalance, uint256 calculatedFees);
    event MessageSent(
        bytes32 indexed messageId,
        uint64 indexed destinationChainSelector,
        address receiver,
        address feeToken,
        uint256 fees
    );

    enum Action {
        CreateSportEvent,
        JoinSportEventSingle,
        JoinSportEventMany,
        ExitSportEvent,
        CloseSportEvent,
        PutMemoryOnSale,
        PurchaseMemory,
        ClaimMemory
    }

    struct FootyDAOMessage {
        Action action;
        bytes data;
    }
}
