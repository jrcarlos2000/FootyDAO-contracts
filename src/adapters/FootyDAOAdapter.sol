pragma solidity ^0.8.18;

import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IFootyDAOAdapter} from "./IFootyDAOAdapter.sol";

/**
 * @title FootyDAO Adapter
 * @author Carlos Ramos
 * @notice Simple contract for hackathon purposes dont use in production
 */
contract FootyDAOAdapter is IFootyDAOAdapter {
    uint64 public baseChainSelector;
    address public baseChainContractAddr;
    IRouterClient public s_router;
    IERC20 public s_linkToken;

    function initialize(
        uint64 _baseChainSelector,
        address _baseChainContractAddr,
        address _router,
        address _link
    ) external {
        baseChainSelector = _baseChainSelector;
        baseChainContractAddr = _baseChainContractAddr;
        s_router = IRouterClient(_router);
        s_linkToken = IERC20(_link);
    }

    function setBaseChainContractAddr(address _baseChainContractAddr) external {
        baseChainContractAddr = _baseChainContractAddr;
    }

    function createSportEvent(
        uint256 _startTime,
        uint256 _endTime,
        uint256 _registrationWindow,
        uint256 _stake,
        uint256 _cost,
        uint256 _maxAttendance
    ) external {
        bytes memory data = abi.encode(
            FootyDAOMessage({
                action: Action.CreateSportEvent,
                data: abi.encode(
                    msg.sender,
                    _startTime,
                    _endTime,
                    _registrationWindow,
                    _stake,
                    _cost,
                    _maxAttendance
                )
            })
        );
        _sendCrossChainMessage(data);
    }

    function joinSportEventSingle(uint256 _sportEventId) external payable {
        bytes memory data = abi.encode(
            FootyDAOMessage({
                action: Action.JoinSportEventSingle,
                data: abi.encode(_sportEventId, msg.sender, msg.value)
            })
        );
        _sendCrossChainMessage(data);
    }

    function closeSportEvent(
        uint256 _sportEventId,
        address[] calldata _notJoinedList
    ) external {
        bytes memory data = abi.encode(
            FootyDAOMessage({
                action: Action.CloseSportEvent,
                data: abi.encode(_sportEventId, _notJoinedList, msg.sender)
            })
        );
        _sendCrossChainMessage(data);
    }

    function recoverChainlinkTokens() external {
        s_linkToken.transfer(msg.sender, s_linkToken.balanceOf(address(this)));
    }

    function _sendCrossChainMessage(
        bytes memory data
    ) internal returns (bytes32 messageId) {
        Client.EVM2AnyMessage memory evm2AnyMessage = Client.EVM2AnyMessage({
            receiver: abi.encode(baseChainContractAddr),
            data: data,
            tokenAmounts: new Client.EVMTokenAmount[](0),
            extraArgs: Client._argsToBytes(
                Client.EVMExtraArgsV1({gasLimit: 500_000, strict: false})
            ),
            feeToken: address(s_linkToken)
        });

        uint256 fees = s_router.getFee(baseChainSelector, evm2AnyMessage);

        if (fees > s_linkToken.balanceOf(address(this)))
            revert NotEnoughBalance(s_linkToken.balanceOf(address(this)), fees);

        s_linkToken.approve(address(s_router), fees);

        messageId = s_router.ccipSend(baseChainSelector, evm2AnyMessage);

        emit MessageSent(
            messageId,
            baseChainSelector,
            baseChainContractAddr,
            address(s_linkToken),
            fees
        );

        return messageId;
    }
}
