//SPDX-License-Identifier:MIT
pragma solidity ^0.8.19;

/**
*@title Decentralized Lottery / Raffle
*@author Bhavya Jain 
*@notice Allows users to participate in a fair lottery
*@dev Uses Chainlink VRF for randomness and Automation for execution
 */

import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";


contract Raffle is VRFConsumerBaseV2{

    error Raffle__NotEnoughEthSent();
    error Raffle__NotEnoughTimePassed();
    error Raffle__FailedToSendEth();
    error Raffle__RaffleNotOpen();
    error Raffle__UpKeepNotNeeded(uint256 currentBalance,uint256 players,uint256 raffleState);

    uint256 private immutable i_entryFee;
    uint256 private s_recentTimeStamp;
    address payable[] public s_players;
    uint256 private immutable i_interval; //Duration of te lottery in sec.
    VRFCoordinatorV2_5Mock private immutable i_vrfCoordinator;// address of the cordinator different from chain to chain
    bytes32 private immutable i_keyHash; // dependent on chain
    uint256 private immutable i_subscriptionId; // we want it to be given at the time of running the contract//
    uint16 private constant REQUEST_CONFIRMATIONS = 3;// since request confirmations isnt chain dependent 
    uint32 private constant NUM_WORDS = 1;
    uint32 private immutable i_callbackGasLimit;
    address private s_recentWinner;
    RaffleState private s_raffleState;


    event EnteredRaffle(
        address indexed PlayerEntered
    );

    event WinnerPicked(
        address indexed Winner
    );

    event RequestedRaffleWinner(
        uint256 indexed RequestId
    );

    enum RaffleState{
        OPEN,
        CALCULATING
    }
    constructor(uint256 entryFee,uint256 interval,address vrfCoordinator,bytes32 keyHash,uint256 subscriptionId, uint32 callbackGasLimit)
    VRFConsumerBaseV2(vrfCoordinator){
        i_entryFee = entryFee;
        i_interval = interval;
        s_recentTimeStamp = block.timestamp;
        i_vrfCoordinator = VRFCoordinatorV2_5Mock(vrfCoordinator);
        i_keyHash = keyHash; 
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        s_raffleState = RaffleState.OPEN;
    }

    function enterRaffle() external payable {
        if(msg.value < i_entryFee){
            revert Raffle__NotEnoughEthSent();
        }
        if(s_raffleState != RaffleState.OPEN){
            revert Raffle__RaffleNotOpen();
        }

        s_players.push(payable(msg.sender));
        emit EnteredRaffle(msg.sender);
        
    }

//FUNCTION THAT CHECKS IS IT TIME FOR OUR LOTTERY TO PERFORM UPKEEP ? 
    function checkUpKeep(bytes memory /*checkData */)public view returns(bool UpKeepNeeded,bytes memory /*performData */){
        //cheeck for 4 conditions
        bool timeHasPassed = (block.timestamp - s_recentTimeStamp) > i_interval;
        bool isOpen = RaffleState.OPEN == s_raffleState;
        bool isContractFunded = address(this).balance>0;
        bool doesContractHasPlayers = s_players.length>0;

        //upkeepneeded when all 4 are true simultaneously
        UpKeepNeeded = (timeHasPassed && isOpen && isContractFunded && doesContractHasPlayers);

        return(UpKeepNeeded,"0x0");
    }

    function performUpkeep(bytes calldata /*performData */)public{

       (bool UpKeepNeeded,) = checkUpKeep("");

        if (!UpKeepNeeded){
            revert Raffle__UpKeepNotNeeded(
                address(this).balance,
                s_players.length,
                uint256(s_raffleState)
            );
        }

        s_raffleState = RaffleState.CALCULATING;


//old version vrf v2 :
        // uint256 requestId = i_vrfCoordinator.requestRandomWords(
        //     i_keyHash,
        //     i_subscriptionId,
        //     REQUEST_CONFIRMATIONS,
        //     i_callbackGasLimit,
        //     NUM_WORDS
        // );

         uint256 requestId = i_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: i_keyHash,
                subId: i_subscriptionId,
                requestConfirmations: REQUEST_CONFIRMATIONS,
                callbackGasLimit: i_callbackGasLimit,
                numWords: NUM_WORDS,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    // Set nativePayment to true to pay for VRF requests with Sepolia ETH instead of LINK
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            })
        );

        emit RequestedRaffleWinner(requestId);// --> redundant as already emitted by vrfCoordinatormock
    }

    function fulfillRandomWords(uint256 RequestId,uint256[] memory randomWords)internal override{
         require(s_players.length > 0, "NO_PLAYERS");

    uint256 index = randomWords[0] % s_players.length;
    address payable winner = s_players[index];

    s_recentWinner = winner;
    s_raffleState = RaffleState.OPEN;
    s_players = new address payable[](0);
    s_recentTimeStamp = block.timestamp;

    emit WinnerPicked(winner);

    (bool success,) = winner.call{value: address(this).balance}("");
    require(success, "ETH_TRANSFER_FAILED");
    }
    

    /* GETTER FUNCTIONS */
    function getRaffleState() external view returns(RaffleState){   
        return(s_raffleState);
    }

    function getArrayOfPlayers(uint256 IndexOfPlayer) external view returns(address){
        return (s_players[IndexOfPlayer]);
    }

    function getRecentWinner() external view returns(address){
        return(s_recentWinner);
    }

    function getPlayersLength() external view returns(uint256){
        return (s_players.length);
    }

    function getLastTimeStamp() external view returns(uint256){
        return(s_recentTimeStamp);
    }


}