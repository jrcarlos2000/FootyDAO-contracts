pragma solidity ^0.8.18;

import "./IFootyDAO.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {CCIPReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {IAny2EVMMessageReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IAny2EVMMessageReceiver.sol";

contract FootyDAO is IFootyDAO, ERC721, Ownable, CCIPReceiver {
    event SimpleCheckPoint(uint256 action);

    mapping(uint256 => SportEvent) public sportEvents;
    mapping(uint256 => Memory) public memoryByTokenId;
    mapping(uint256 => uint256[]) public memoryTokenIdsOfSportEvent;

    uint256 constant MEMORY_SALE_OPEN_TIME = 7 days;
    uint256 constant MEMORY_SALE_FEE = 100; // 1% basis points
    uint256 constant CANCELATION_FEE = 1000; // 10% basis points

    uint256 public sportEventCount = 1;
    uint256 private _tokenIds;

    bytes32 private s_lastReceivedMessageId; // Store the last received messageId.
    string private s_lastReceivedText; // Store the last received text.

    constructor(
        address router
    ) ERC721("FootyDAOMemory", "FTY") Ownable(msg.sender) CCIPReceiver(router) {
        _mint(msg.sender, _tokenIds);
        _tokenIds++;
    }

    function createSportEvent(
        uint256 _startTime,
        uint256 _endTime,
        uint256 _registrationWindow,
        uint256 _stake,
        uint256 _cost,
        uint256 _maxAttendance
    ) public {
        _createSportEvent(
            msg.sender,
            _startTime,
            _endTime,
            _registrationWindow,
            _stake,
            _cost,
            _maxAttendance
        );
    }

    function _createSportEvent(
        address _creator,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _registrationWindow,
        uint256 _stake,
        uint256 _cost,
        uint256 _maxAttendance
    ) internal {
        require(_startTime > block.timestamp, "Invalid start time");
        require(_endTime > _startTime, "Invalid end time");
        require(_registrationWindow > 0, "Invalid registration window");
        sportEvents[sportEventCount] = SportEvent(
            _creator,
            _startTime,
            _endTime,
            _registrationWindow,
            _stake,
            _cost,
            _maxAttendance,
            new address[](0),
            new address[](0),
            0,
            new uint256[](0)
        );
        sportEventCount++;
    }

    function joinSportEventMany(
        uint256 _sportEventId,
        address[] memory _users
    ) public payable {
        _joinSportEventMany(_sportEventId, _users, msg.value);
    }

    function _joinSportEventMany(
        uint256 _sportEventId,
        address[] memory _users,
        uint256 _value
    ) internal {
        for (uint256 i = 0; i < _users.length; i++) {
            _joinSportEventSingle(
                _sportEventId,
                _users[i],
                _value / _users.length
            );
        }
    }

    function joinSportEventSingle(uint256 _sportEventId) external payable {
        _joinSportEventSingle(_sportEventId, msg.sender, msg.value);
    }

    function exitSportEvent(uint256 _sportEventId) external {
        _exitSportEvent(_sportEventId, msg.sender);
    }

    function _exitSportEvent(uint256 _sportEventId, address _user) internal {
        SportEvent memory sportEvent = sportEvents[_sportEventId];
        require(sportEvent.startTime > 0, "Invalid game");
        require(
            sportEvent.waitingList.length > sportEvent.takenWaitingList,
            "No waiting list"
        );
        (bool isInList, uint256 index) = _findInList(
            _user,
            sportEvent.participants
        );
        require(isInList, "User not in game");
        sportEvent.participants[index] = sportEvent.participants[
            sportEvent.participants.length - 1
        ];
        sportEvent.participants[sportEvent.participants.length - 1] = sportEvent
            .waitingList[sportEvent.takenWaitingList];
        sportEvent.takenWaitingList++;
        sportEvents[_sportEventId] = sportEvent;

        // transfer stake and cost to the sender without cancelation fee
        uint256 transferAmount = sportEvent.stake + sportEvent.cost;
        transferAmount -= (transferAmount * CANCELATION_FEE) / 10000;

        payable(_user).transfer(transferAmount);
    }

    function closeSportEvent(
        uint256 _sportEventId,
        address[] memory notJoinedList
    ) external {
        _closeSportEvent(_sportEventId, notJoinedList, msg.sender);
    }

    function _closeSportEvent(
        uint256 _sportEventId,
        address[] memory notJoinedList,
        address creator
    ) internal {
        SportEvent memory sportEvent = sportEvents[_sportEventId];
        require(sportEvent.creator == creator, "Invalid creator");
        require(
            sportEvent.endTime > 0 && sportEvent.endTime < block.timestamp,
            "Invalid game or close time"
        );
        // todo add reentrancy guard
        for (uint256 i = 0; i < sportEvent.participants.length; i++) {
            (bool isInList, ) = _findInList(
                sportEvent.participants[i],
                notJoinedList
            );
            if (!isInList) {
                payable(sportEvent.participants[i]).transfer(sportEvent.stake);
            }
        }
    }

    function putMemoryOnSale(
        string calldata _cid,
        uint256 _sportEventId,
        uint256 _price
    ) external {
        _putMemoryOnSale(_cid, _sportEventId, _price, msg.sender);
    }

    function _putMemoryOnSale(
        string memory _cid,
        uint256 _sportEventId,
        uint256 _price,
        address _creator
    ) internal {
        SportEvent memory sportEvent = sportEvents[_sportEventId];
        require(
            sportEvent.endTime + MEMORY_SALE_OPEN_TIME > block.timestamp,
            "Invalid game or time"
        );
        _mint(address(this), _tokenIds);
        memoryByTokenId[_tokenIds] = Memory(
            _creator,
            _tokenIds,
            _price,
            _sportEventId,
            _cid
        );
        sportEvents[_sportEventId].tokenIds.push(_tokenIds);
        _tokenIds++;
    }

    function purchaseMemory(uint256 _tokenId) external payable {
        _purchaseMemory(_tokenId, msg.sender, msg.value);
    }

    function _purchaseMemory(
        uint256 _tokenId,
        address _buyer,
        uint256 _value
    ) internal {
        Memory memory _memory = memoryByTokenId[_tokenId];
        (bool isInList, ) = _findInList(
            _buyer,
            sportEvents[_memory.sportEventId].participants
        );
        require(isInList, "User not in game");
        require(_isTokenOnSale(_tokenId), "Memory not for sale");
        require(_memory.price == _value, "Invalid amount sent");
        uint256 fee = (_value * MEMORY_SALE_FEE) / 10000;
        uint256 amount = _value - fee;
        payable(memoryByTokenId[_tokenId].owner).transfer(amount);
        this.transferFrom(address(this), _buyer, _tokenId);
    }

    function claimMemory(uint256 _tokenId) public {
        Memory memory _memory = memoryByTokenId[_tokenId];
        require(_tokenId > 0 && _tokenId < _tokenIds, "Invalid token id");
        require(ownerOf(_tokenId) == address(this), "Memory not for sale");
        require(isGameSaleTime(_memory.sportEventId), "Invalid game or time");

        transferFrom(address(this), memoryByTokenId[_tokenId].owner, _tokenId);
    }

    // READERS

    function tokenURI(
        uint256 _tokenId
    ) public view override returns (string memory) {
        return string.concat("ipfs://", memoryByTokenId[_tokenId].tokenURI);
    }

    function getListOfParticipants(
        uint256 _sportEventId
    ) external view returns (address[] memory) {
        return sportEvents[_sportEventId].participants;
    }

    function getWaitingList(
        uint256 _sportEventId
    ) external view returns (address[] memory) {
        return sportEvents[_sportEventId].waitingList;
    }

    function getAllSportEventsData()
        external
        view
        returns (SportEvent[] memory)
    {
        SportEvent[] memory sportEventsData = new SportEvent[](
            sportEventCount - 1
        );
        for (uint256 i = 1; i < sportEventCount; i++) {
            sportEventsData[i - 1] = sportEvents[i];
        }
        return sportEventsData;
    }

    function getSportEventData(
        uint256 _sportEventId
    ) public view returns (SportEvent memory, Memory[] memory) {
        uint256[] memory tokenIdsOnSale = _getIdsOnSale(
            sportEvents[_sportEventId].tokenIds
        );
        Memory[] memory memories = new Memory[](tokenIdsOnSale.length);
        for (uint256 i = 0; i < tokenIdsOnSale.length; i++) {
            memories[i] = memoryByTokenId[tokenIdsOnSale[i]];
        }
        return (sportEvents[_sportEventId], memories);
    }

    function _getIdsOnSale(
        uint256[] memory _tokenIdsSearch
    ) internal view returns (uint256[] memory) {
        uint256[] memory validTokenIds = new uint256[](_tokenIdsSearch.length);
        uint256 validTokenIdsCount = 0;
        for (uint256 i = 0; i < _tokenIdsSearch.length; i++) {
            if (_isTokenOnSale(_tokenIdsSearch[i])) {
                validTokenIds[validTokenIdsCount] = _tokenIdsSearch[i];
                validTokenIdsCount++;
            }
        }
        uint256[] memory validTokenIdsFinal = new uint256[](validTokenIdsCount);
        for (uint256 i = 0; i < validTokenIdsCount; i++) {
            validTokenIdsFinal[i] = validTokenIds[i];
        }

        return validTokenIdsFinal;
    }

    function _isTokenOnSale(uint256 _tokenId) internal view returns (bool) {
        if (!(_tokenId > 0 && _tokenId < _tokenIds)) {
            return false;
        }
        if (ownerOf(_tokenId) != address(this)) {
            return false;
        }
        return isGameSaleTime(memoryByTokenId[_tokenId].sportEventId);
    }

    function isGameSaleTime(uint256 _sportEventId) public view returns (bool) {
        return
            sportEvents[_sportEventId].endTime + MEMORY_SALE_OPEN_TIME >
            block.timestamp;
    }

    function getLastReceivedMessageDetails()
        external
        view
        returns (bytes32 messageId, string memory text)
    {
        return (s_lastReceivedMessageId, s_lastReceivedText);
    }

    function _joinSportEventSingle(
        uint256 _sportEventId,
        address _user,
        uint256 _value
    ) internal {
        SportEvent memory sportEvent = sportEvents[_sportEventId];
        require(
            sportEvent.startTime > 0 &&
                sportEvent.startTime - sportEvent.registrationWindow >
                block.timestamp,
            "Invalid game or join time"
        );
        require(
            sportEvent.stake + sportEvent.cost == _value,
            "Invalid amount sent"
        );
        if (sportEvent.participants.length < sportEvent.maxAttendance) {
            sportEvents[_sportEventId].participants.push(_user);
        } else {
            sportEvents[_sportEventId].waitingList.push(_user);
        }
    }

    function _findInList(
        address toSearch,
        address[] memory SearchIn
    ) internal pure returns (bool, uint256) {
        for (uint256 i = 0; i < SearchIn.length; i++) {
            if (SearchIn[i] == toSearch) {
                return (true, i);
            }
        }
        return (false, 0);
    }

    function _ccipReceive(
        Client.Any2EVMMessage memory any2EvmMessage
    ) internal override {
        s_lastReceivedMessageId = any2EvmMessage.messageId;

        emit MessageReceived(
            any2EvmMessage.messageId,
            any2EvmMessage.sourceChainSelector,
            abi.decode(any2EvmMessage.sender, (address))
        );

        FootyDAOMessage memory footyDAOMessage = abi.decode(
            any2EvmMessage.data,
            (FootyDAOMessage)
        );

        if (footyDAOMessage.action == Action.CreateSportEvent) {
            (
                address _creator,
                uint256 _startTime,
                uint256 _endTime,
                uint256 _registrationWindow,
                uint256 _stake,
                uint256 _cost,
                uint256 _maxAttendance
            ) = abi.decode(
                    footyDAOMessage.data,
                    (
                        address,
                        uint256,
                        uint256,
                        uint256,
                        uint256,
                        uint256,
                        uint256
                    )
                );

            emit SimpleCheckPoint(_startTime);

            _createSportEvent(
                _creator,
                _startTime,
                _endTime,
                _registrationWindow,
                _stake,
                _cost,
                _maxAttendance
            );
        } else if (footyDAOMessage.action == Action.JoinSportEventSingle) {
            (uint256 _sportEventId, address _user, uint256 _value) = abi.decode(
                footyDAOMessage.data,
                (uint256, address, uint256)
            );
            _joinSportEventSingle(_sportEventId, _user, _value);
        } else if (footyDAOMessage.action == Action.CloseSportEvent) {
            (
                uint256 _sportEventId,
                address[] memory _notJoinedList,
                address _creator
            ) = abi.decode(footyDAOMessage.data, (uint256, address[], address));
            _closeSportEvent(_sportEventId, _notJoinedList, _creator);
        } else if (footyDAOMessage.action == Action.JoinSportEventMany) {
            (
                uint256 _sportEventId,
                address[] memory _users,
                uint256 _value
            ) = abi.decode(footyDAOMessage.data, (uint256, address[], uint256));
            _joinSportEventMany(_sportEventId, _users, _value);
        } else if (footyDAOMessage.action == Action.ExitSportEvent) {
            (uint256 _sportEventId, address _user) = abi.decode(
                footyDAOMessage.data,
                (uint256, address)
            );
            _exitSportEvent(_sportEventId, _user);
        } else if (footyDAOMessage.action == Action.PutMemoryOnSale) {
            (
                string memory _cid,
                uint256 _sportEventId,
                uint256 _price,
                address _creator
            ) = abi.decode(
                    footyDAOMessage.data,
                    (string, uint256, uint256, address)
                );

            _putMemoryOnSale(_cid, _sportEventId, _price, _creator);
        } else if (footyDAOMessage.action == Action.PurchaseMemory) {
            (uint256 _tokenId, address _buyer, uint256 _value) = abi.decode(
                footyDAOMessage.data,
                (uint256, address, uint256)
            );
            _purchaseMemory(_tokenId, _buyer, _value);
        } else if (footyDAOMessage.action == Action.ClaimMemory) {
            uint256 _tokenId = abi.decode(footyDAOMessage.data, (uint256));
            claimMemory(_tokenId);
        } else {
            revert("Invalid action");
        }
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public pure virtual override(CCIPReceiver, ERC721) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId) ||
            interfaceId == type(IAny2EVMMessageReceiver).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }

    function getMemoriesOfUser(
        address user
    ) external view returns (Memory[] memory memories) {
        memories = new Memory[](balanceOf(user));
        uint256 count = 0;
        for (uint256 i = 0; i < _tokenIds; i++) {
            if (ownerOf(i) == user) {
                memories[count] = memoryByTokenId[i];
                count++;
            }
        }
    }
}
