//SPDX-License-Identifier:MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol"; 
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {Subscription,FundSubscriptionId,addConsumer} from "./Subscription.s.sol";

contract DeployRaffle is Script{
    function run() external returns(Raffle,HelperConfig){
        

        HelperConfig helperConfig = new HelperConfig();
        // deconstructing this to paramateres , could simply be written as NewteorkConfig config =helperConfig.ActiveNetworkConfig();
        (uint256 entryFee,uint256 interval,address vrfCoordinator,bytes32 keyHash,uint256 subscriptionId,uint32 callbackGasLimit,address link) = helperConfig.ActiveNetworkConfig();

        if(subscriptionId == 0){
            //we have to create A subscription;
            Subscription CreateSubscription = new Subscription();
            subscriptionId = CreateSubscription.createSubscription(vrfCoordinator);
              //after creating it we need to fund it
            FundSubscriptionId fundSubscription = new FundSubscriptionId();
            fundSubscription.FundSubscription(vrfCoordinator,subscriptionId,link);

        }
        
        vm.startBroadcast();
        Raffle raffle = new Raffle(entryFee,interval,vrfCoordinator,keyHash,subscriptionId,callbackGasLimit);
        vm.stopBroadcast();

        addConsumer addconsumer = new addConsumer();
        addconsumer.addConsumerToSub(vrfCoordinator,subscriptionId,address(raffle));

        return(raffle,helperConfig);
    }
}