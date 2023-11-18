pragma solidity ^0.8.18;

import {FootyDAO} from "../src/FootyDAO.sol";
import {Test, console} from "forge-std/Test.sol";

// VERY BASIC TEST for hackathon
contract TestFootyDAO is Test {
    FootyDAO public footyDAO;

    address footyDAOAdmin = vm.addr(1);
    address user1 = vm.addr(2);
    address user2 = vm.addr(3);
    address user3 = vm.addr(4);
    address user4 = vm.addr(5);
    address user5 = vm.addr(6);
    address user6 = vm.addr(7);
    address user7 = vm.addr(8);
    address user8 = vm.addr(9);
    address user9 = vm.addr(10);
    address user10 = vm.addr(11);

    address creator1 = vm.addr(12);
    address creator2 = vm.addr(13);
    address creator3 = vm.addr(14);

    function setUp() public {
        vm.prank(footyDAOAdmin);
        footyDAO = new FootyDAO(0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496);
        _dealToAll();
    }

    function testGameJoinAndClosure() public {
        vm.prank(user1);
        // user 1 creates a game
        footyDAO.createSportEvent(
            block.timestamp + 7 days,
            block.timestamp + 8 days,
            1 days,
            1 ether,
            2 ether,
            5
        );

        // user 2 joins the game
        vm.prank(user2);
        footyDAO.joinSportEventSingle{value: 3 ether}(1);
        // user 3 joins the game
        vm.prank(user3);
        footyDAO.joinSportEventSingle{value: 3 ether}(1);

        // get all events
        FootyDAO.SportEvent memory event1 = (footyDAO.getAllSportEventsData())[
            0
        ];

        // check if the event is created
        require(event1.creator == user1, "Invalid creator");
        require(event1.startTime == block.timestamp + 7 days, "Invalid start");
        require(event1.endTime == block.timestamp + 8 days, "Invalid end");
        require(
            event1.registrationWindow == 1 days,
            "Invalid registration window"
        );
        require(event1.stake == 1 ether, "Invalid stake");
        require(event1.cost == 2 ether, "Invalid cost");
        require(event1.maxAttendance == 5, "Invalid max attendance");
        require(event1.participants.length == 2, "Invalid participants");
        require(event1.waitingList.length == 0, "Invalid waiting list");
        require(event1.takenWaitingList == 0, "Invalid taken waiting list");
        require(event1.tokenIds.length == 0, "Invalid token ids");

        // check participants is ok
        require(event1.participants[0] == user2, "Invalid participant 1");
        require(event1.participants[1] == user3, "Invalid participant 2");

        // user 4 joins the game for 2 people
        address[] memory users = new address[](2);
        users[0] = user4;
        users[1] = user5;
        vm.prank(user4);
        footyDAO.joinSportEventMany{value: 6 ether}(1, users);

        // recheck only participants
        event1 = (footyDAO.getAllSportEventsData())[0];
        require(event1.participants.length == 4, "Invalid participants");
        require(event1.waitingList.length == 0, "Invalid waiting list");
        require(event1.takenWaitingList == 0, "Invalid taken waiting list");
        require(event1.participants[2] == user4, "Invalid participant 1");
        require(event1.participants[3] == user5, "Invalid participant 2");

        // user 6 joins the game for 2 people
        users[0] = user6;
        users[1] = user7;
        vm.prank(user6);
        footyDAO.joinSportEventMany{value: 6 ether}(1, users);

        // recheck only participants
        event1 = (footyDAO.getAllSportEventsData())[0];
        require(event1.participants.length == 5, "Invalid participants");
        require(event1.waitingList.length == 1, "Invalid waiting list");

        // check waiting list users
        require(event1.waitingList[0] == user7, "Invalid waiting list user");

        // check last participant
        require(event1.participants[4] == user6, "Invalid participant 2");

        // before balance check balance of user 6
        uint256 balanceUser6 = user6.balance;
        // user 6 exits the game
        vm.prank(user6);
        footyDAO.exitSportEvent(1);

        // check balance of user 6
        uint256 balanceUser6After = user6.balance;
        require(
            balanceUser6After > balanceUser6,
            "User 6 balance should be higher"
        );

        // recheck only participants
        event1 = (footyDAO.getAllSportEventsData())[0];
        require(event1.participants.length == 5, "Invalid participants");
        require(event1.waitingList.length == 1, "Invalid waiting list");
        require(event1.takenWaitingList == 1, "Invalid taken waiting list");

        // check last participan is user7
        require(event1.participants[4] == user7, "Invalid participant 5");

        address[] memory didntJoin = new address[](2);
        didntJoin[0] = user7;
        didntJoin[1] = user3;

        // before close check the balance of a random participant who joined

        uint256 balanceUser4 = user4.balance;
        // before close check the balance of a participant who didnt join
        uint256 balance0Before = didntJoin[0].balance;
        uint256 balance1Before = didntJoin[1].balance;

        // admin closes the game at a correct time
        uint256 sp = vm.snapshot();
        vm.warp(block.timestamp + 9 days);
        vm.prank(user1);
        footyDAO.closeSportEvent(1, didntJoin);

        // check the balance of a random participant who joined
        uint256 balanceUser4After = user4.balance;
        require(
            balanceUser4After == balanceUser4 + event1.stake,
            "User 4 balance should be higher"
        );

        // check the balance of a participant who didnt join
        uint256 balance0After = didntJoin[0].balance;
        uint256 balance1After = didntJoin[1].balance;
        require(
            balance0After == balance0Before,
            "User 0 balance should be the same"
        );
        require(
            balance1After == balance1Before,
            "User 1 balance should be the same"
        );
    }

    function testMemoryStuff() public {
        vm.prank(user1);
        // user 1 creates a game
        footyDAO.createSportEvent(
            block.timestamp + 7 days,
            block.timestamp + 8 days,
            1 days,
            1 ether,
            2 ether,
            5
        );

        vm.prank(user2);
        // user 2 creates a game
        footyDAO.createSportEvent(
            block.timestamp + 7 days,
            block.timestamp + 8 days,
            1 days,
            1 ether,
            2 ether,
            5
        );

        // user 2 joins for 4 people to game 1
        address[] memory users = new address[](4);
        users[0] = user2;
        users[1] = user3;
        users[2] = user4;
        users[3] = user5;

        vm.prank(user2);
        footyDAO.joinSportEventMany{value: 12 ether}(1, users);

        // user 3 joins for 5 people to game 2
        users = new address[](5);
        users[0] = user3;
        users[1] = user4;
        users[2] = user5;
        users[3] = user6;
        users[4] = user7;

        vm.prank(user3);
        footyDAO.joinSportEventMany{value: 15 ether}(2, users);

        // both games are closed
        vm.warp(block.timestamp + 9 days);
        vm.prank(user1);
        footyDAO.closeSportEvent(1, new address[](0));

        vm.prank(user2);
        footyDAO.closeSportEvent(2, new address[](0));

        // memories are added into market place
        vm.prank(creator1);
        footyDAO.putMemoryOnSale("memory1", 1, 5 ether);

        vm.prank(creator2);
        footyDAO.putMemoryOnSale("memory2", 2, 5 ether);

        vm.prank(creator3);
        footyDAO.putMemoryOnSale("memory3", 1, 3 ether);

        vm.prank(creator1);
        footyDAO.putMemoryOnSale("memory5", 1, 1 ether);

        vm.prank(creator2);
        footyDAO.putMemoryOnSale("memory6", 2, 20 ether);

        // get one event and all its memories
        (
            FootyDAO.SportEvent memory event1,
            FootyDAO.Memory[] memory memories
        ) = (footyDAO.getSportEventData(1));

        // check if event is correct
        require(event1.creator == user1, "Invalid creator");
        require(
            event1.registrationWindow == 1 days,
            "Invalid registration window"
        );
        require(event1.stake == 1 ether, "Invalid stake");
        require(event1.cost == 2 ether, "Invalid cost");
        require(event1.maxAttendance == 5, "Invalid max attendance");
        require(event1.participants.length == 4, "Invalid participants");
        require(event1.waitingList.length == 0, "Invalid waiting list");

        // check if memories are correct
        require(memories.length == 3, "Invalid memories");
        require(memories[0].owner == creator1, "Invalid owner");
        require(memories[1].owner == creator3, "Invalid owner");
        require(memories[2].owner == creator1, "Invalid owner");

        // check token ids
        require(event1.tokenIds.length == 3, "Invalid token ids");
        require(event1.tokenIds[0] == 1, "Invalid token id");
        require(event1.tokenIds[1] == 3, "Invalid token id");
        require(event1.tokenIds[2] == 4, "Invalid token id");

        // non participant fails to buy a memory
        vm.expectRevert("User not in game");
        vm.prank(user8);
        footyDAO.purchaseMemory(1);

        FootyDAO.Memory[] memory indexesOwned = footyDAO.getMemoriesOfUser(
            address(footyDAO)
        );
        require(indexesOwned.length == 5, "Invalid memories owned");

        // check creator balance before sale
        uint256 balanceCreator1 = creator1.balance;
        // participant buys a memory
        vm.prank(user2);
        footyDAO.purchaseMemory{value: 5 ether}(1);

        // check creator balance after sale
        uint256 balanceCreator1After = creator1.balance;
        require(
            balanceCreator1After > balanceCreator1,
            "Invalid creator balance"
        );

        require(footyDAO.ownerOf(1) == user2, "Invalid owner");

        // check if memory is bought
        (, FootyDAO.Memory[] memory memories2) = (
            footyDAO.getSportEventData(1)
        );
        require(memories2.length == 2, "Invalid memories");

        // finish sale time
        vm.warp(block.timestamp + 8 days);
        (, memories2) = (footyDAO.getSportEventData(1));
        require(memories2.length == 0, "Invalid memories");
    }

    function _dealToAll() internal {
        vm.deal(user1, 100 ether);
        vm.deal(user2, 100 ether);
        vm.deal(user3, 100 ether);
        vm.deal(user4, 100 ether);
        vm.deal(user5, 100 ether);
        vm.deal(user6, 100 ether);
        vm.deal(user7, 100 ether);
        vm.deal(user8, 100 ether);
        vm.deal(user9, 100 ether);
        vm.deal(user10, 100 ether);
    }
}
