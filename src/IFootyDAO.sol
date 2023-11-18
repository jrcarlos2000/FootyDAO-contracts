pragma solidity ^0.8.18;

interface IFootyDAO {
    event MessageReceived(
        bytes32 indexed messageId,
        uint64 indexed sourceChainSelector,
        address sender
    );

    struct SportEvent {
        address creator;
        uint256 startTime;
        uint256 endTime;
        uint256 registrationWindow;
        uint256 stake;
        uint256 cost;
        uint256 maxAttendance;
        address[] participants;
        address[] waitingList;
        uint256 takenWaitingList;
        uint256[] tokenIds;
        bool closed;
    }
    struct Memory {
        address owner;
        uint256 tokenId;
        uint256 price;
        uint256 sportEventId;
        string tokenURI;
    }
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
