//SPDX-License-Identifier :MIT
pragma solidity ^0.8.19;

/**NatSpec
@notice - 3 things :
1.Create Subscriptio
2.Fund Subscription
3.Add consumer
*/

import {Script,console} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "../test/Mocks/LinkToken.sol";
import {DevOpsTools} from "@foundry-devops/src/DevOpsTools.sol";

contract Subscription is Script {

    function createSubscriptionUsingConfig() public returns (uint256){
        // to create the subscription we need VRF coordinator
        HelperConfig helperConfig = new HelperConfig();
        (,,address vrfCoordinator,, uint256 subscriptionId,,) = helperConfig.ActiveNetworkConfig();
        createSubscription(vrfCoordinator);//==> no need as we have done this we are deploying the contract
        //createSubscription(vrfCoordinator);
    }

    function createSubscription(address VRFCoordinator) public returns(uint256){
        console.log("Creating Subscription On ChainID",block.chainid);

        vm.startBroadcast();
        uint256 SubId = VRFCoordinatorV2_5Mock(VRFCoordinator).createSubscription(); //address vrfCoordinator from helper config getting converted to VRFCoordinatorV2Mock to use th function createSubscriptiton.
        vm.stopBroadcast();

        return (SubId);
        console.log("Your Sub Id : ",SubId);
    }

    function run() external returns (uint256){
        return createSubscriptionUsingConfig();
    }
}


contract FundSubscriptionId is Script {

    uint96 public constant FUND_AMOUNT = 3 ether;
    HelperConfig helperConfig = new HelperConfig();
    Subscription subscription = new Subscription();


    function fundSubscriptionUsingConfig() public{
        (,,address vrfCoordinator,,uint256 SubId,,address link) = helperConfig.ActiveNetworkConfig();
            FundSubscription(vrfCoordinator,SubId,link);
    }

    function FundSubscription(address vrfCoordinatorV2, uint256 subId, address link)public{
        //same functions as that frontend would do to fund the subscription
        console.log("Funding Subscription:",subId);
        console.log("using VRFCoordinator:",vrfCoordinatorV2);
        console.log("on chainId:",block.chainid);
        if(block.chainid == 31337){ // we are on a local chain
            vm.startBroadcast();
            VRFCoordinatorV2_5Mock(vrfCoordinatorV2).fundSubscription(subId,FUND_AMOUNT); // to fund our subscription on anvil
            vm.stopBroadcast();
        }
        else{
          vm.startBroadcast(); 
          LinkToken(link).transferAndCall(vrfCoordinatorV2,FUND_AMOUNT,abi.encode(subId)); // to fund our subscription on a real/test chainid
          vm.stopBroadcast();  
        }

    }

    function run() external{
        fundSubscriptionUsingConfig();
    }

 

}

contract addConsumer is Script{

    HelperConfig helperConfig = new HelperConfig();

    function addConsumerUsingConfig(address RaffleContract)public{
        (,,address vrfCoordinator,,uint256 SubId,,) = helperConfig.ActiveNetworkConfig();
            addConsumerToSub(vrfCoordinator,SubId,RaffleContract);
    }

    function addConsumerToSub(address vrfCoordinator,uint256 SubId,address raffle)public{
        vm.startBroadcast();
        VRFCoordinatorV2_5Mock(vrfCoordinator).addConsumer(SubId,raffle);
        vm.stopBroadcast();
    }

    function run()external{ //for this we are going to need the raffle contract as we need to add consumer i.e, the raffle contract
    //for that we need the most recently deployed raffle.sol==>foundty_devops
    address raffle = DevOpsTools.get_most_recent_deployment("Raffle",block.chainid);
    //now we can add consumer
    addConsumerUsingConfig(raffle);
    }
}