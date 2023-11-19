//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../src/YourContract.sol";
import "./DeployHelpers.s.sol";
import "../src/FootyDAO.sol";
import "../src/adapters/FootyDAOAdapter.sol";
import "../src/chiliz/WeekRewards.sol";
import "../src/MockToken.sol";
import "../src/FootyDAOSingleChain.sol";
import "../src/FootyDAOFunctionsConsumer.sol";

interface IFunctionsBillingRegistry {
    function addConsumer(uint64 subscriptionId, address consumer) external;
}

contract AirnodeHelper {
    function airnodeChain(uint256 chainid) public view returns (address) {
        if (chainid == 80001) {
            // mumbai
            return 0xa0AD79D995DdeeB18a14eAef56A549A04e3Aa1Bd;
        } else if (chainid == 11155111) {
            // sepolia
            return 0x2ab9f26E18B64848cd349582ca3B55c2d06f507d;
        } else if (chainid == 421613) {
            // arbitrum
            return 0xa0AD79D995DdeeB18a14eAef56A549A04e3Aa1Bd;
        } else if (chainid == 84531) {
            // base
            return 0x92E5125adF385d86beDb950793526106143b6Df1;
        } else if (chainid == 420) {
            // optimism testnet
            return 0xa0AD79D995DdeeB18a14eAef56A549A04e3Aa1Bd;
        }
    }
}

contract ChainlinkHelper {
    function chainSelector(uint256 chainid) public view returns (uint64) {
        if (chainid == 80001) {
            // mumbai
            return 12532609583862916517;
        } else if (chainid == 11155111) {
            // sepolia
            return 16015286601757825753;
        } else if (chainid == 421613) {
            // arbitrum
            return 6101244977088475029;
        } else if (chainid == 84531) {
            // base
            return 5790810961207155433;
        } else if (chainid == 420) {
            // optimism
            return 2664363617261496610;
        }
    }

    function chainRouter(uint256 chainid) public view returns (address) {
        if (chainid == 80001) {
            // mumbai
            return 0x70499c328e1E2a3c41108bd3730F6670a44595D1;
        } else if (chainid == 11155111) {
            // sepolia
            return 0xD0daae2231E9CB96b94C8512223533293C3693Bf;
        } else if (chainid == 421613) {
            // arbitrum
            return 0x88E492127709447A5ABEFdaB8788a15B4567589E;
        } else if (chainid == 84531) {
            // base
            return 0xA8C0c11bf64AF62CDCA6f93D3769B88BdD7cb93D;
        } else if (chainid == 420) {
            return 0xEB52E9Ae4A9Fb37172978642d4C141ef53876f26;
        }
    }

    function linkToken(uint256 chainid) public view returns (address) {
        if (chainid == 80001) {
            // mumbai
            return 0x326C977E6efc84E512bB9C30f76E30c160eD06FB;
        } else if (chainid == 11155111) {
            // sepolia
            return 0x779877A7B0D9E8603169DdbD7836e478b4624789;
        } else if (chainid == 421613) {
            // arbitrum
            return 0xd14838A68E8AFBAdE5efb411d5871ea0011AFd28;
        } else if (chainid == 84531) {
            // base
            return 0xD886E2286Fd1073df82462ea1822119600Af80b6;
        } else if (chainid == 420) {
            // optimism
            return 0xdc2CC710e42857672E7907CF474a69B63B93089f;
        }
    }
}

contract DeployScript is ScaffoldETHDeploy, ChainlinkHelper {
    address public footyDaoMain = 0x52E058E5CD5D9a25117bCe2c467c521667b345b1;

    function run() external {
        uint256 deployerPrivateKey = setupLocalhostEnv();

        vm.startBroadcast(deployerPrivateKey);

        // some random shit
        // _localCreateRandomGame(
        //     FootyDAO(0x17fe4C6E05Ca5c631d235e8fa51e507674B5e318)
        // );
        // return;
        // -----

        address footyDaoAddr;

        if (!isSupportedChainId(block.chainid)) {
            revert("Unsupported chain id");
        }

        if (block.chainid == 420) {
            FootyDAO footyDAO = new FootyDAO(chainRouter(block.chainid));
            footyDaoAddr = address(footyDAO);
            _localCreateRandomGame(footyDAO);
        } else if (block.chainid == 88882) {
            // deploy some test tokens TODO : comment out
            MockToken token1 = new MockToken("Token1", "TKN1");
            MockToken token2 = new MockToken("Token2", "TKN2");

            address[] memory tokens = new address[](2);
            tokens[0] = address(token1);
            tokens[1] = address(token2);
            WeekRewards weekRewards = new WeekRewards(tokens);

            // mint to the rewards contract
            token1.mint(address(weekRewards), 1000000000000000000000000);
            token2.mint(address(weekRewards), 1000000000000000000000000);

            footyDaoAddr = address(weekRewards);
        } else if (block.chainid == 245022926  || block.chainid == 59140 || block.chainid == 534351 || block.chainid == 44787 || block.chainid == 51 || block.chainid == 10200 || block.chainid == 5001) {
            console.logString("Deploying single");
            // other chains
            FootyDAOSingleChain footyDAO = new FootyDAOSingleChain();
            footyDaoAddr = address(footyDAO);
        } else {
            FootyDAOAdapter footyDAO = new FootyDAOAdapter();
            footyDAO.initialize(
                chainSelector(420),
                footyDaoMain,
                chainRouter(block.chainid),
                linkToken(block.chainid)
            );
            footyDaoAddr = address(footyDAO);
            // fund adapter with chainlink tokens
            IERC20 link = IERC20(linkToken(block.chainid));
            link.transfer(
                address(footyDAO),
                2 * 10 ** 18 // 2 chainlink tokens
            );

            _createRandomGame(footyDAO);
        }

        console.logString(
            string.concat(
                "FootyDAO or WeeklyRewards deployed at: ",
                vm.toString(footyDaoAddr)
            )
        );
        vm.stopBroadcast();
    }

    function isSupportedChainId(uint256 chainId) public pure returns (bool) {
        return
            chainId == 80001 ||
            chainId == 11155111 ||
            chainId == 421613 ||
            chainId == 84531 ||
            chainId == 88882 ||
            chainId == 245022926 ||
            chainId == 420 || 
            chainId == 59140 || chainId == 534351 
            || chainId == 44787 || chainId == 51 || chainId == 10200 || chainId == 5001;
    }

    function _createRandomGame(FootyDAOAdapter footyDAO) internal {
        footyDAO.createSportEvent(
            100000000000000000,
            100000000000000100,
            10000,
            100000000000,
            100000000000,
            10
        );
    }

    function _localCreateRandomGame(FootyDAO footyDAO) internal {
        footyDAO.createSportEvent(
            100000000000000000,
            100000000000000100,
            10000,
            100000000000,
            100000000000,
            10
        );
    }

    function test() public {}
}

contract DeployFunctionsConsumer is
    ScaffoldETHDeploy,
    ChainlinkHelper,
    AirnodeHelper
{
    address constant CHAINLINK_ROUTER =
        0x6E2dc0F9DB014aE19888F539E59285D2Ea04244C;
    uint64 subId = 818;

    address lastCcipConnector = 0xAf567b3A106B351B9407AD64c16E10eec5519279;

    function run() external {
        uint256 deployerPrivateKey = setupLocalhostEnv();
        vm.startBroadcast(deployerPrivateKey);

        if (block.chainid != 80001) {
            revert("Only mumbai");
        }
        // setup functions consumer

        FootyDAOFunctionsConsumer footyDaoFunctionsConsumer = new FootyDAOFunctionsConsumer(
                CHAINLINK_ROUTER,
                subId
            );

        FootyDAOFunctionsCCIPConector ccipConnector = new FootyDAOFunctionsCCIPConector(
                chainRouter(block.chainid),
                address(footyDaoFunctionsConsumer),
                airnodeChain(block.chainid),
                0x6238772544f029ecaBfDED4300f13A3c4FE84E1D,
                0x9877ec98695c139310480b4323b9d474d48ec4595560348a2341218670f7fbc2
            );

        ccipConnector.setAvailableFanTokenCount(1);
        ccipConnector.setAvailableMaxAmountToDistribute(1000000);
        IFunctionsBillingRegistry(CHAINLINK_ROUTER).addConsumer(
            subId,
            address(footyDaoFunctionsConsumer)
        );

        string memory fileRoot = vm.projectRoot();
        string memory filePath = string.concat(fileRoot, "/inline-requests/");
        filePath = string.concat(filePath, "distribute-rewards.js");
        string memory jsFile = vm.readFile(filePath);
        console.logString(jsFile);
        footyDaoFunctionsConsumer.setPostRequestSrc(jsFile);
        bytes memory lastResponse = footyDaoFunctionsConsumer.latestResponse();
        console.logBytes(lastResponse);

        // footyDaoFunctionsConsumer.demoDistribute();

        // FootyDAOFunctionsConsumer(lastConsumerContract)
        //     .distributeChilizRewards();
        vm.stopBroadcast();
    }
}
