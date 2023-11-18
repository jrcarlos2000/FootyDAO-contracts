pragma solidity ^0.8.18;

import "./IFootyDAO.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract FootyDAOSingleChain is IFootyDAO, ERC721, Ownable {
    mapping(uint256 => SportEvent) public sportEvents;
    mapping(uint256 => Memory) public memoryByTokenId;
    mapping(uint256 => uint256[]) public memoryTokenIdsOfSportEvent;

    uint256 constant MEMORY_SALE_OPEN_TIME = 7 days;
    uint256 constant MEMORY_SALE_FEE = 100; // 1% basis points
    uint256 constant CANCELATION_FEE = 1000; // 10% basis points

    uint256 public sportEventCount = 1;
    uint256 private _tokenIds;

    constructor() ERC721("FootyDAOMemory", "FTY") Ownable(msg.sender) {
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
    ) external {
        require(_startTime > block.timestamp, "Invalid start time");
        require(_endTime > _startTime, "Invalid end time");
        require(_registrationWindow > 0, "Invalid registration window");
        sportEvents[sportEventCount] = SportEvent(
            msg.sender,
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
    ) external payable {
        for (uint256 i = 0; i < _users.length; i++) {
            _joinSportEventSingle(
                _sportEventId,
                _users[i],
                msg.value / _users.length
            );
        }
    }

    function joinSportEventSingle(uint256 _sportEventId) external payable {
        _joinSportEventSingle(_sportEventId, msg.sender, msg.value);
    }

    function exitSportEvent(uint256 _sportEventId) external {
        SportEvent memory sportEvent = sportEvents[_sportEventId];
        require(sportEvent.startTime > 0, "Invalid game");
        require(
            sportEvent.waitingList.length > sportEvent.takenWaitingList,
            "No waiting list"
        );
        (bool isInList, uint256 index) = _findInList(
            msg.sender,
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

        payable(msg.sender).transfer(transferAmount);
    }

    function closeSportEvent(
        uint256 _sportEventId,
        address[] calldata notJoinedList
    ) external {
        SportEvent memory sportEvent = sportEvents[_sportEventId];
        require(sportEvent.creator == msg.sender, "Invalid creator");
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
        SportEvent memory sportEvent = sportEvents[_sportEventId];
        require(
            sportEvent.endTime + MEMORY_SALE_OPEN_TIME > block.timestamp,
            "Invalid game or time"
        );
        _mint(address(this), _tokenIds);
        memoryByTokenId[_tokenIds] = Memory(
            msg.sender,
            _tokenIds,
            _price,
            _sportEventId,
            _cid
        );
        sportEvents[_sportEventId].tokenIds.push(_tokenIds);
        _tokenIds++;
    }

    function purchaseMemory(uint256 _tokenId) external payable {
        Memory memory _memory = memoryByTokenId[_tokenId];
        (bool isInList, ) = _findInList(
            msg.sender,
            sportEvents[_memory.sportEventId].participants
        );
        require(isInList, "User not in game");
        require(_isTokenOnSale(_tokenId), "Memory not for sale");
        require(_memory.price == msg.value, "Invalid amount sent");
        uint256 fee = (msg.value * MEMORY_SALE_FEE) / 10000;
        uint256 amount = msg.value - fee;
        payable(memoryByTokenId[_tokenId].owner).transfer(amount);
        this.transferFrom(address(this), msg.sender, _tokenId);
    }

    function claimMemory(uint256 _tokenId) external {
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

    function dummyMint() external {
        _mint(msg.sender, _tokenIds);
        _tokenIds++;
    }
}
