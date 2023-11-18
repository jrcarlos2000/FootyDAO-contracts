pragma solidity ^0.8.18;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title Week Rewards
 * @author Carlos Ramos
 * @notice Contract to be used to distribute weekly rewards to users
 */
contract WeekRewards is Ownable {
    mapping(uint256 => bool) hasBeenDistributed;
    event RewardsDistributed(
        address[] users,
        uint256 totalAmount,
        uint256 fanTokenId
    );
    address[] public fanTokens;

    constructor(address[] memory _fanTokens) Ownable(msg.sender) {
        fanTokens = _fanTokens;
    }

    function distributeRewards(
        address[] memory _users,
        uint256 _totalAmount,
        uint256 _fanTokenId,
        uint256 _requestId
    ) external {
        require(!hasBeenDistributed[_requestId], "Already distributed");
        hasBeenDistributed[_requestId] = true;
        uint256 allocatedPerUser = _totalAmount / _users.length;
        for (uint256 i = 0; i < _users.length; i++) {
            IERC20(fanTokens[_fanTokenId]).transfer(
                _users[i],
                allocatedPerUser
            );
        }
        emit RewardsDistributed(_users, _totalAmount, _fanTokenId);
    }

    function addFanToken(address _fanToken) external onlyOwner {
        fanTokens.push(_fanToken);
    }

    function numberOfFanTokens() external view returns (uint256) {
        return fanTokens.length;
    }
}
