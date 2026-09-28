// SPDX-License-Identifier:MIT

pragma solidity 0.8.19;

import {Test} from "forge-std/Test.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {Raffle} from "src/Raffle.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {Vm} from "forge-std/Vm.sol";



contract Raffletest is Test{
    Raffle public raffle;
    HelperConfig public helperConfig;

    address public PLAYER = makeAddr("player");
    uint256 public constant STARTING_PLAYER_BALANCE = 10 ether;
 

 event RaffleEntered(address indexed player);
    event WinnerPicked(address indexed winner);


   uint256 entranceFee;
        uint256 interval;
        address vrfCoordinator;
        bytes32 gasLane;
        uint256 subscriptionId;
        uint32 callbackGasLimit;


    function setUp() external{

      DeployRaffle deployer = new DeployRaffle();
   (raffle , helperConfig) = deployer.deployContract(); // instead of run if u write this it will work as well coz run will anyways gonna call this function itself

   HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
   entranceFee = config.entranceFee;
  interval = config.interval;
  vrfCoordinator = config.vrfCoordinator;
  gasLane = config.gasLane;
  subscriptionId = config.subscriptionId;
  callbackGasLimit = config.callbackGasLimit;
  vm.deal(PLAYER,STARTING_PLAYER_BALANCE);


    }


    function testRaffleInitializationOpenState() public view{

        assert(raffle.getRaffleState()== Raffle.RaffleState.OPEN);

    }



function testRaffleRevertsWhenYouDontPayEnough() public{
    // Arrange
    vm.prank(PLAYER);
    // Act/Assert
    vm.expectRevert(Raffle.Raffle_SendMoreToEnterRaffle.selector); 
    //Raffle.Raffle_SendMoreToEnterRaffle.selector is telling Foundry which exact custom error the next transaction must revert with for the test to pass.
    // coz we have 2 reverts inside enterRaffle and we want to check particular one
        raffle.enterRaffle();
}



function testRaffleRecordsPlayerWhenTheyEnter() public{
    // Arrange
    vm.prank(PLAYER);
    // Act
    raffle.enterRaffle{value:entranceFee}();
    // Assert
    address playerRecorded = raffle.getPlayer(0);
    assert(playerRecorded == PLAYER);


}

// testing emit is a little bit funky although u can refer to foundry book for the cheatcode

function testEnteringRaffleEmitsEvent() public{
    // Arrange
    vm.prank(PLAYER);


    // Act
    vm.expectEmit(true,false,false,false,address(raffle)); // this is telling foundry we are expecting to emit an event from this address
emit RaffleEntered(PLAYER); // this is exactly the event that we are expecting to emit here


    // Assert
raffle.enterRaffle{value:entranceFee}();
}

/*
EMIT test learning

1.To test whether a contract emits an event correctly in Foundry, you use the vm.expectEmit cheatcode.
2. vm.expectEmit takes up to 5 arguments:
3. vm.expectEmit(checkTopic1, checkTopic2, checkTopic3, checkData, emitterAddress);

checkTopic1 (bool): Set to true if your event's first indexed parameter should be checked.

checkTopic2 (bool): Set to true if your event's second indexed parameter should be checked.

checkTopic3 (bool): Set to true if your event's third indexed parameter should be checked (Solidity allows up to 3 indexed topics per event).

checkData (bool): Set to true if you want to check non-indexed parameters (the rest of the event data).

emitterAddress (address): (Optional) The contract address that must emit the event.

also u gotta copy paste the event thing directly from raffle.sol to test( see at top).



also in the codebase of above function

The exact sequence feels completely counter-intuitive when you first see it, but here is why Foundry forces you to write it in that specific order:

Think of vm.expectEmit as Setting up a Detector
To catch the event, you have to configure the listener before the action takes place:


When raffle.enterRaffle{value: entranceFee}() runs, the EVM executes the internal function logic in real-time. The moment emit RaffleEntered(player) inside Raffle.sol triggers, the event log is instantly written to EVM execution state and finished.

If you put vm.expectEmit after raffle.enterRaffle(), the event has already happened and passed before Foundry was told to listen for it!

 */


function testDontAllowPlayersToEnterWhileRaffleIsCalculating() public{
    // Arrange (we gotta make sure to make the contract calculating here in the arrange itself)
    vm.prank(PLAYER);
    raffle.enterRaffle{value:entranceFee}();
    vm.warp(block.timestamp + interval + 1); // this cheatcode teleport the clock forward
    vm.roll(block.number + 1); 
    raffle.performUpKeep(""); // this is actually gonna set the enum to calculating

    // Act/ Assert
    vm.expectRevert(Raffle.Raffle_RaffleNotOpen.selector);
    vm.prank(PLAYER);
    raffle.enterRaffle{value:entranceFee}();

}
/*
vm.roll explanation

Every Ethereum-compatible chain (whether Mainnet, Sepolia, or Foundry's local Anvil network) processes transactions by grouping them into numbered blocks—Block #1, Block #2, Block #3, and so on.

By default, tests run in a local EVM instance starting at block number 1 (or whatever block the local network started at).

vm.roll(500) instantly changes the current environment's block.number to 500.

It is standard practice to use both together so the block environment matches reality (where time passing always correlates with new blocks being produced).

 */

function testCheckUpKeepReturnsFalseIfItHasNoBalance() public{
    // Arrange
    vm.warp(block.timestamp + interval +1);
    vm.roll(block.number +1);

    // Act
    (bool upKeepNeeded , ) = raffle.checkUpkeep ("");
     
     // Assert
     assert(!upKeepNeeded);
}

function testCheckUpKeepReturnsFalseIfRaffleIsntOpen() public{

// ARRANGE
     vm.prank(PLAYER);
    raffle.enterRaffle{value:entranceFee}();
    vm.warp(block.timestamp + interval + 1); 
    vm.roll(block.number + 1); 
    raffle.performUpKeep(""); 

// ACT
(bool upkeepNeeded,) = raffle.checkUpkeep("");

// Assert
assert(!upkeepNeeded);
}



// CHALLENGE AND HOMEWORK QUESTION(solns in github repo) as we have discovered from coverage debug these are not covered yet
// testCheckUpkeepReturnsFalseIfEnoughTimeHasPassed
//testCheckUpkeepReturnsTrueWhenParameterAreGood

function testPerformUpkeepCanOnlyRunIfCheckUpkeepIsTrue() public{
// Arrange
    vm.prank(PLAYER);
    raffle.enterRaffle{value:entranceFee}();
    vm.warp(block.timestamp + interval + 1); 
    vm.roll(block.number + 1); 

// Act/Assert
 raffle.performUpKeep(""); 

}

function testPerformUpkeepRevertsIfCheckUpkeepIsFalse() public{
    // Arrange
    uint256 currentBalance = 0;
    uint256 numPlayers = 0;
    Raffle.RaffleState rState = raffle.getRaffleState();
    vm.prank(PLAYER);
    raffle.enterRaffle{value:entranceFee}();
    currentBalance = currentBalance + entranceFee;
    numPlayers =1;

    // Act/Assert
    vm.expectRevert(abi.encodeWithSelector(Raffle.Raffle_UpkeepNotNeeded.selector ,currentBalance , numPlayers,rState));
// when we have custom error with paramater then thats how u write
    raffle.performUpKeep("");

}

// what if we need to get data from emitted events in our tests?

function testPerformUpkeepUpdatesRaffleStateAndEmitsRequestId() public{

// Arrange
    vm.prank(PLAYER);
    raffle.enterRaffle{value:entranceFee}();
    vm.warp(block.timestamp + interval + 1); 
    vm.roll(block.number + 1); 

    // Act
    vm.recordLogs();
    raffle.performUpkeep("");
    Vm.Log[] memory entries = vm.getRecordedLogs();
    // u can go to Vm.sol and can see the Log struct what all its gonna store
    // whenever we want to get RequestId in the raffle we would just need to find the event or log that was emitted and then grab the first topic from it


}


}






/*
STEPS
1.after writing basic test do forge build and forge test
2.do forge coverage to check how much percent you have did
3."forge coverage --report debug > coverage.txt"
The above command will create a file called coverage.txt, containing the specific lines of code that have not been covered yet.

 */

/*
FORGE COVERAGE LESRNING

generally check function and branches coz line and statements toh kaafi rahege and when i went through coverage so we realisez inside construcotr we havent checked all the variables

 */



/*
LEARNINGS:

AAA (Arrange-Act-Assert) pattern is the universal standard structure for writing clean unit tests in software engineering.

Arrange: 
Set up the test environment and preconditions. (e.g., set up who the caller is, create test users, set initial state).
 In your code, vm.prank(PLAYER) sets the caller identity to PLAYER.



 Act: 
 Execute the single action or function you want to test. 
 In your code, raffle.enterRaffle{value: entranceFee}() actually executes the transaction.


 Assert: 
 Verify the outcome. Check if the actual result matches your expected result. 
  In your code, assert(playerRecorded == PLAYER) checks if the contract correctly saved the player's address in storage.






 */