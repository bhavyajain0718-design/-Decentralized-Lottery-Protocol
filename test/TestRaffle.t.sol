//SPDX-License-Identifier:MIT
pragma solidity ^0.8.19;

import {Test,console} from "forge-std/Test.sol";
import {Raffle} from "../src/Raffle.sol";
import {DeployRaffle} from "../script/DeployRaffle.s.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";
import {Vm} from "forge-std/Vm.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";


contract TestRaffle is Test {


    //** EVENTS */
    event EnteredRaffle(
            address indexed PlayerEntered
        );
        
    Raffle public raffle ;
    HelperConfig public helperConfig;
    address public PLAYER = makeAddr("player");
    address public PLAYER_1 = makeAddr("player_1");
    uint256 public constant STARTING_USER_BALANCE = 10 ether;
    uint256 public entryFee;
    uint256 public interval;
    address public vrfCoordinator;
    bytes32 public keyHash;
    uint256 public subscriptionId;
    uint32 public callbackGasLimit;
    address public link;

    function setUp()external{
    DeployRaffle deployer = new DeployRaffle();
    (raffle,helperConfig) = deployer.run();
    (entryFee,interval,vrfCoordinator,keyHash,subscriptionId,callbackGasLimit,link) = helperConfig.ActiveNetworkConfig();
    }

    function testRaffleInitializesInOpenState() public{
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }

                ////////////////////
                ////Enter Raffle////
                ////////////////////
    function testEnterRaffle__entryFee() public{
        vm.expectRevert();
        vm.prank(PLAYER);
        raffle.enterRaffle {value : 0 ether}();
    }

    function testEnterRaffle__arrayUpdated() public{
        hoax(PLAYER,STARTING_USER_BALANCE); 
        raffle.enterRaffle{value : entryFee}();
        assertEq(PLAYER,raffle.getArrayOfPlayers(0));
    }

    function testEmitsAnEvent() public{

        hoax(PLAYER,STARTING_USER_BALANCE); 

        vm.expectEmit(true,false,false,false,address(raffle)); //() parameters--> 3 indexed,1 un indexed, address of the emitter
        emit EnteredRaffle(PLAYER);      // we emit the event ourselves that we expected to be emitted by the contract
        raffle.enterRaffle{value : entryFee}(); //run the function which causes emitting.

    }

    function testPlayerCantEnterWhenCalculating() public{
        hoax(PLAYER,STARTING_USER_BALANCE);
        raffle.enterRaffle{value : entryFee}();
        vm.warp(block.timestamp+interval+1);
        raffle.performUpkeep("");
        assert(raffle.getRaffleState() == Raffle.RaffleState.CALCULATING);
    
        vm.expectRevert();
        hoax(PLAYER_1,STARTING_USER_BALANCE);
        raffle.enterRaffle{value : entryFee}();
    }

            ///////////////////////
            ///CHECKUPKEEP_TEST///
            ///////////////////////
    function testCheckUpkeepFailsIfItHasNoBalance()public{

        //ARRANGE
        //make everything else true except the balance stmt 
        vm.warp(block.timestamp+interval+1); // sets the time interval > than than i_interval;
        vm.roll(block.number+1); // changes to the next block with same states keeping the previous block with old state;

        //ACT
        (bool UpkeepNeeded,) = raffle.checkUpKeep("");

        //ASSERT
        assert(!UpkeepNeeded);

    }

    function testCheckUpkeepFailsIfStateIsNotOpen() public{
        hoax(PLAYER,STARTING_USER_BALANCE);
        raffle.enterRaffle{value : entryFee}();
        vm.warp(block.timestamp+interval+1);
        vm.roll(block.number+1);
        raffle.performUpkeep("");

        (bool upkeepNeeded,) = raffle.checkUpKeep("");
        assert(!upkeepNeeded); //assert not false ==> assert true ==> test should pass ///// same as assert(upkeepNeeded == false);
    }

    function testCheckUpkeepFailsIfEnoughTimeHasntPassed()public{
        hoax(PLAYER,STARTING_USER_BALANCE);
        raffle.enterRaffle{value : entryFee}();

        (bool upkeepNeeded,) = raffle.checkUpKeep("");
        assert(!upkeepNeeded); //assert not false ==> assert true ==> test should pass
    }
    
    function testCheckUpkeepTrueIfParametersAreGood()public{
        hoax(PLAYER,STARTING_USER_BALANCE);
        raffle.enterRaffle{value: entryFee}();
        vm.warp(block.timestamp+interval+1);
        vm.roll(block.number+1);

        (bool upkeepNeeded,) = raffle.checkUpKeep("");
        assert(upkeepNeeded == true);
    }

            /////////////////////////
            ///PerformUpkeep_Test///
            ////////////////////////

    function testPerformUpKeepCanOnlyWorkIfUpKeepNeeded()public{
        hoax(PLAYER,STARTING_USER_BALANCE);
        raffle.enterRaffle{value: entryFee}();
        vm.warp(block.timestamp+interval+1);
        vm.roll(block.number+1);

        raffle.performUpkeep("");

     //   assert(raffle.getRaffleState() == Raffle.RaffleState.CALCULATING);
        
    }

    function testPerformUpKeepRevertsIfCheckUpKeepFalse()public{
        uint256 currentBalance;
        uint256 players;
        uint256 raffleState;
        
        //IMPORTANT AND NEW
        vm.expectRevert(abi.encodeWithSelector(Raffle.Raffle__UpKeepNotNeeded.selector,currentBalance,players,raffleState));
        raffle.performUpkeep("");
    }

    function testPerformUpKeepUpdatesRaffleStateAndEmitsEvent()public RaffleEnteredAndTimePassed{
         vm.recordLogs();
         raffle.performUpkeep("");
         Vm.Log[] memory entries = vm.getRecordedLogs();
         bytes32 requestId = entries[1].topics[0];

         Raffle.RaffleState rState = raffle.getRaffleState();

        assert(uint256(rState) == 1);
         assert(uint256(requestId)>0);
    }

            /////////////////////////
            ///Fulfil_random_words///
            ////////////////////////

    function testFulfilRandomWordsOnlyAfterPerformUpkeep(uint256 randomRequestIds)public RaffleEnteredAndTimePassed{
        vm.expectRevert();
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(randomRequestIds,address(raffle));
    }

    function testFulfillRandomWordsPicksTheWinnerResetsAndSendsMoney()public RaffleEnteredAndTimePassed{
        //vm.deal(address(raffle), 5e16); // 0.05 ETH

               // Arrange
        uint256 additionalEntrances = 3;
        uint256 startingIndex = 1; // We have starting index be 1 so we can start with address(1) and not address(0)

        for (uint256 i = startingIndex; i < startingIndex + additionalEntrances; i++) {
            address player = address(uint160(i));
            hoax(player, 1 ether); // deal 1 eth to the player
            raffle.enterRaffle{value: entryFee}();
        }

        // Act
        vm.recordLogs();
        raffle.performUpkeep(""); // emits requestId
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1]; // get the requestId from the logs

        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(uint256(requestId), address(raffle));
        console.log(raffle.getRecentWinner());
        // assert(raffle.getRecentWinner() != address(0));
        // assert(raffle.getRaffleState() == Raffle.RaffleState(0));
        // assert(raffle.getPlayersLength() == 0);
    //    assertEq(raffle.getRecentWinner().balance,prize +STARTING_USER_BALANCE-entryFee);


        
    }




modifier RaffleEnteredAndTimePassed(){
    hoax(PLAYER,STARTING_USER_BALANCE);
        raffle.enterRaffle{value: entryFee}();
        vm.warp(block.timestamp+interval+1);
        vm.roll(block.number+1);
    _;
}


}