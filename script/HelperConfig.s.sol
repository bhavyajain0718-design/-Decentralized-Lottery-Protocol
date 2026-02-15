//SPDX-License-Identifier:MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "../test/Mocks/LinkToken.sol";
import {Subscription,FundSubscriptionId,addConsumer} from "./Subscription.s.sol";


contract HelperConfig is Script{

    uint96 public constant MOCK_BASE_FEE = 0.25 ether;
    uint96 public constant MOCK_GAS_PRICE_LINK = 1e9;
    // LINK / ETH price
    int256 public constant MOCK_WEI_PER_UINT_LINK = 4e15;

    struct NetworkConfig{
        uint256 entryFee;
        uint256 interval;
        address vrfCoordinator;
        bytes32 keyHash;
        uint256 subscriptionId;
        uint32 callbackGasLimit;
        address link;
    }

    NetworkConfig public ActiveNetworkConfig;

    constructor(){
        if(block.chainid==11155111){
            ActiveNetworkConfig = getSepoliaEthConfig();
        }
        else {
            ActiveNetworkConfig = getOrCreateAnvilEthConfig();
        }
    }

    function getSepoliaEthConfig() public pure returns(NetworkConfig memory){
        return
            NetworkConfig({
                entryFee: 0.01 ether,
                interval:30,
                vrfCoordinator:0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
                keyHash:0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
                subscriptionId:92760697130839576020109932459334141908785135216619459986048778001369828873881,
                callbackGasLimit:500000,
                link:0x779877A7B0D9E8603169DdbD7836e478b4624789

        });
    
    }

    function getOrCreateAnvilEthConfig() public returns(NetworkConfig memory){
        if (ActiveNetworkConfig.vrfCoordinator != address(0)){
            return ActiveNetworkConfig;
        }

        

    
        vm.startBroadcast();
        // for vrf cordinator on anvil --> mock
        VRFCoordinatorV2_5Mock vrfCoordinatorV2Mock = new VRFCoordinatorV2_5Mock(MOCK_BASE_FEE,MOCK_GAS_PRICE_LINK,MOCK_WEI_PER_UINT_LINK);
        // for link mock on anvil
        LinkToken link = new LinkToken();
        vm.stopBroadcast();
        

        return
            NetworkConfig({
                entryFee: 0.01 ether,
                interval:30,
                vrfCoordinator:address(vrfCoordinatorV2Mock),
                keyHash:0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
                subscriptionId:0,
                callbackGasLimit:500000,
                link:address(link)

        });
    }
}
