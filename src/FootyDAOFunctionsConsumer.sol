// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {FunctionsClient} from "@chainlink/contracts/src/v0.8/functions/dev/v1_0_0/FunctionsClient.sol";
import {ConfirmedOwner} from "@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";
import {FunctionsRequest} from "@chainlink/contracts/src/v0.8/functions/dev/v1_0_0/libraries/FunctionsRequest.sol";
import {CCIPReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {RrpRequesterV0} from "@api3/airnode-protocol/contracts/rrp/requesters/RrpRequesterV0.sol";

contract FootyDAOFunctionsConsumer is FunctionsClient {
    // ---- CHAINLINK ----
    using FunctionsRequest for FunctionsRequest.Request;

    string postRequestSrc;
    uint64 subscriptionId;

    bytes32 public latestRequestId;
    bytes public latestResponse;
    bytes public latestError;

    event OCRResponse(bytes32 indexed requestId, bytes result, bytes err);
    // ---- --------- ----

    uint256 distributionCount = 0;

    constructor(
        address _functionsRouter,
        uint64 _subscriptionId
    ) FunctionsClient(_functionsRouter) {
        subscriptionId = _subscriptionId;
    }

    function setPostRequestSrc(string memory source) public {
        postRequestSrc = source;
    }

    function fulfillRequest(
        bytes32 requestId,
        bytes memory response,
        bytes memory err
    ) internal override {
        latestResponse = response;
        latestError = err;
        emit OCRResponse(requestId, response, err);
    }

    function distruteChilizRewards(
        address[] memory users,
        uint256 amount,
        uint256 fanTokenId
    ) public {
        FunctionsRequest.Request memory req;
        req.initializeRequestForInlineJavaScript(postRequestSrc);
        string[] memory args = new string[](4);
        string memory usersString = "";

        for (uint256 i = 0; i < users.length; i++) {
            usersString = string.concat(
                usersString,
                Strings.toHexString(uint256(uint160(users[i])), 20)
            );
            if (i < users.length - 1) {
                usersString = string.concat(usersString, ",");
            }
        }

        args[0] = usersString;
        args[1] = Strings.toString(amount);
        args[2] = Strings.toString(fanTokenId);
        args[3] = Strings.toString(distributionCount);
        req.setArgs(args);
        latestRequestId = _sendRequest(
            req.encodeCBOR(),
            subscriptionId,
            200_000,
            "fun-polygon-mumbai-1"
        );
        distributionCount++;
    }
}

contract FootyDAOFunctionsCCIPConector is CCIPReceiver, RrpRequesterV0 {
    // ----- AIRNDODE -----
    bytes32 public endpoint2Id;
    address public airnode;
    address public sponsorWallet;

    mapping(bytes32 => bool) public airnodeRequests;
    mapping(bytes32 => uint256) public requestToResult;

    event RequestMade(bytes32 indexed requestId, uint256 numberOfnumbers);
    event Response(bytes32 indexed requestId, uint256[] responses);

    /// --------------------

    FootyDAOFunctionsConsumer public functionsConsumer;
    address[] public users;

    uint256 availableFanTokenCount = 0;
    uint256 availableMaxAmountToDistribute = 0;
    uint256 lastRandomUserIndex = type(uint256).max;

    constructor(
        address _ccipRouter,
        address _functionsConsumer,
        address _airnode,
        address _airnodePolygon,
        bytes32 _reqEndpoint
    ) CCIPReceiver(_ccipRouter) RrpRequesterV0(_airnode) {
        functionsConsumer = FootyDAOFunctionsConsumer(_functionsConsumer);
        airnode = _airnodePolygon;
        endpoint2Id = _reqEndpoint;
    }

    function setUpAirnode(address payable _sponsorWallet) external {
        sponsorWallet = _sponsorWallet;
    }

    function setAvailableFanTokenCount(
        uint256 _availableFanTokenCount
    ) external {
        availableFanTokenCount = _availableFanTokenCount;
    }

    function setAvailableMaxAmountToDistribute(
        uint256 _availableMaxAmountToDistribute
    ) external {
        availableMaxAmountToDistribute = _availableMaxAmountToDistribute;
    }

    function _ccipReceive(
        Client.Any2EVMMessage memory any2EvmMessage
    ) internal override {
        address[] memory _users = abi.decode(any2EvmMessage.data, (address[]));
        users = new address[](_users.length);
        for (uint256 i = 0; i < _users.length; i++) {
            users[i] = _users[i];
        }
        _requestAndDistribute();
    }

    // for DEMO purposes
    function demoDistribute() public {
        address[] memory _users = new address[](2);
        _users[0] = 0xDe3089d40F3491De794fBb1ECA109fAc36F889d0;
        _users[1] = 0x030F89E68d4B15E51C2Adebdb6fD20896e264e1e;
        users = new address[](2);
        users[0] = 0xDe3089d40F3491De794fBb1ECA109fAc36F889d0;
        users[1] = 0x030F89E68d4B15E51C2Adebdb6fD20896e264e1e;
        _requestAndDistribute();
    }

    function _requestAndDistribute() internal {
        bytes32 requestId = airnodeRrp.makeFullRequest(
            airnode,
            endpoint2Id,
            address(this),
            sponsorWallet,
            address(this),
            this.fulfillArray.selector,
            abi.encode(bytes32("1u"), bytes32("size"), 2)
        );

        airnodeRequests[requestId] = true;
        emit RequestMade(requestId, 2);
    }

    function fulfillArray(
        bytes32 requestId,
        bytes calldata data
    ) external onlyAirnodeRrp {
        // require(airnodeRequests[requestId], "Request not made");
        airnodeRequests[requestId] = false;
        uint256[] memory twoQRNG = abi.decode(data, (uint256[]));
        uint256 userLen = users.length;
        uint256 randomIndex = twoQRNG[0] % userLen;
        uint256 randomFanTokenId = twoQRNG[1] % availableFanTokenCount;
        uint256 randomAmount = 10000; // TODO random
        address[] memory usersToDist = new address[](1);
        usersToDist[0] = users[randomIndex];
        lastRandomUserIndex = randomIndex;
        functionsConsumer.distruteChilizRewards(
            usersToDist,
            randomAmount,
            randomFanTokenId
        );
    }
}
