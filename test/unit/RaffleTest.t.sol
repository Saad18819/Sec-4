// SPDX-License-Identifier:MIT

pragma solidity 0.8.19;

import {Test} from "forge-std/Test.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {Raffle} from "src/Raffle.sol";
import {HelperConfig , CodeConstants} from "script/HelperConfig.s.sol";
import {Vm} from "forge-std/Vm.sol"; // u are exporting this for VM.Log thing
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {console} from "forge-std/console.sol";



contract Raffletest is CodeConstants,Test{
    Raffle public raffle;
    HelperConfig public helperConfig;

    address public PLAYER = makeAddr("player");
    uint256 public constant STARTING_PLAYER_BALANCE = 10 ether;
 
// u only write even of that thing for which u goota do vm.expectEmit for vm.recordLogs and all u dont have to
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

    modifier raffleEntered(){
         vm.prank(PLAYER);
    raffle.enterRaffle{value:entranceFee}();
    vm.warp(block.timestamp + interval + 1); 
    vm.roll(block.number + 1); 
    _;
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


Purpose: 
Acts like an assert. It tells Foundry: "Hey, check if the upcoming function call emits this exact event."  

 How it works: 
 You emit the expected event yourself in the test right after calling vm.expectEmit. Foundry intercepts the next transaction (enterRaffle) and passes if the logs match.  
 '
  When to use:
   When you just want to test if an event was emitted with the right parameters.  

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
 // time hasnt passed so coz of that the performUpKeep gonna revert
 // although in main function we have typecasted the raffle state value but whenever u write paramter in abi.encode u dont typecast it automatically under the hood figure it out
}

// what if we need to get data from emitted events in our tests?

function testPerformUpkeepUpdatesRaffleStateAndEmitsRequestId() public raffleEntered{
/* 
// Arrange
    vm.prank(PLAYER);
    raffle.enterRaffle{value:entranceFee}();
    vm.warp(block.timestamp + interval + 1); 
    vm.roll(block.number + 1); 
*/
    // Act
    vm.recordLogs(); // vm.recordLogs() tells Forge’s Virtual Machine to start recording every EVM event (log) emitted by any contract from that point forward.
    raffle.performUpKeep(""); // Trigger the action that emits events
    Vm.Log[] memory entries = vm.getRecordedLogs(); 
    bytes32 requestId = entries[1].topics[1];
    /*

   vm.getRecordedLogs() does two things simultaneously:

1.Fetches and returns an array containing every EVM event emitted since vm.recordLogs() was called.
2.Resets/clears the internal log recorder buffer in Foundry.


u can go to Vm.sol and can see the Log struct what all its gonna store
Whenever we want to get RequestId in the raffle we would just need to find the event or log that was emitted and then grab the first topic from it
    
EXPLANATION
    bytes32 requestId = entries[1].topics[1];
This single line extracts the requestId from the captured events. Here is the breakdown of why both 1s exist:


    1. Why entries[1]? (The Outer 1)
entries is an array of all events emitted across every contract during the execution of raffle.performUpKeep("").

When performUpKeep runs, it actually triggers two separate events in chronological order:

entries[0] (First Event): Emitted inside the external Chainlink VRF Coordinator contract (RandomWordsRequested).

entries[1] (Second Event): Emitted inside your Raffle contract (e.g., RequestedRaffleWinner(requestId)).

You use entries[1] because you specifically want the event emitted by your Raffle contract, which was recorded second in line.


The topics array inside any event log is arranged like this:

topics[0]: Reserved for the Event Signature Hash (e.g., keccak256("RequestedRaffleWinner(uint256)")). It tells the EVM which event was emitted.

topics[1]: The 1st indexed parameter of that event.

topics[2]: The 2nd indexed parameter (if it exists).

Since requestId is declared as an indexed variable in your Solidity event definition:

The requestId value gets stored directly at topics[1].

Summary
entries[1].topics[1] simply translates to:

"Go to the 2nd event recorded (entries[1]), and grab its 1st indexed parameter (topics[1])."
    


    
     */ 
    


// Assert
Raffle.RaffleState raffleState = raffle.getRaffleState();
assert(uint256(requestId) > 0); // requestId is returned as a bytes32 datatype, which is a raw 32-byte (256-bit) hexadecimal byte array.
assert(uint256(raffleState) == 1);


/*
Purpose:
 Acts like a log recorder/listener.  

 How it works:
 vm.recordLogs() starts recording all logs emitted on the EVM.  
  You trigger performUpKeep("").   vm.getRecordedLogs() fetches all recorded log entries into an array (entries).   You extract specific indexed arguments (e.g., entries[1].topics[1] for requestId).  
   
   When to use:
    When you need to grab an unknown/dynamically generated value (like a Chainlink VRF requestId or a newly minted tokenId) from an event log so you can pass it into the next line of your test (e.g., calling vrfCoordinator.fulfillRandomWords(requestId, ...)).   



 */

}


/* FULFILL RANDOM WORDS TEST */
// fulfill random words can only be called after performUpkeep was called coz u need requestId

modifier skipFork(){
    if(block.chainid != LOCAL_CHAIN_ID){
        return ;
    }
    _;
}


// STATELESS FUZZ TEST
function testFulfillrandomWordsCanOnlyBeCalledAfterPerformUpkeep(uint256 randomRequestId) public raffleEntered skipFork{
    //Arrange / Act / Assert
    vm.expectRevert(VRFCoordinatorV2_5Mock.InvalidRequest.selector);
    VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(randomRequestId , address(raffle)); // this is a function in vrfmock file
}
/*

LEARNING


 vm.expectRevert(VRFCoordinatorV2_5Mock.InvalidRequest.selector);
    VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(0 , address(raffle));


 vm.expectRevert(VRFCoordinatorV2_5Mock.InvalidRequest.selector);
    VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(1 , address(raffle));

   so every random number u put in test will pass so this is defo not a good method so we gonna write a fuzz test or stateless fuzz testing
so basically u gonna put an requestId input onstead of numbers
   
   so here basically while testing we are acting like chainlink and doing the job of requesting fulfillrandomwords thats why we are importing vrfcoordinator mock folder bcz its a mock  
   coz above thing other than chainlink or other node service can do it
   link nobody can call the fiulfillrandom words only chainlink nodes can actually call this function
    

in vrfcoordinatormock they have fulfillrandomwords function and in that we have revert InvalidRequest() thing which tells u gotta have requestId thing else its jusst gonna revert
and thats what exactlty we gonna test that revert
make sure to import vrfcoordinator mock file as well in here


in terminal after running a forge test we got this

[PASS] testFulfillrandomWordsCanOnlyBeCalledAfterPerformUpkeep(uint256) (runs: 256, μ: 82376, ~: 82376)

here runs 256 means the fuzz testing had tried 256 different random numbers to make sure it fails so this is definitely a very very good testing 
and in foundry.toml make sure to set the runs 



What is Fuzz Testing?
Standard unit tests use fixed/hardcoded values (like 0 or 1). If your code works for 0 and 1, you haven't proven it works for 999999 or type(uint256).max.

Fuzz testing automates this: instead of hardcoding values, you pass parameters into your test function (like uint256 randomRequestId). Foundry automatically generates hundreds of random inputs (e.g., 0, 12345, 2**256 - 1, etc.) and runs your test against all of them in a single execution to see if any input breaks your code.

Stateless Fuzz Testing: Each fuzz run resets the EVM state back to initial conditions before testing the next generated input.



What You Are Actually Testing
You are testing security and access control on the Chainlink VRF Coordinator Mock.

Specifically, you want to make sure that nobody can cheat or complete a raffle cycle by guessing or passing a fake requestId before performUpkeep has actually requested randomness.

Which Error Are We Testing?
You are testing for the InvalidRequest error inside the VRFCoordinatorV2_5Mock contract.

In the VRF Mock (and real Chainlink VRF Coordinator), when performUpkeep is called, it creates a request and saves that requestId internally in a mapping.

If someone tries to call fulfillRandomWords(requestId, consumer) using a requestId that was never registered in the Coordinator:
It reverts with VRFCoordinatorV2_5Mock.InvalidRequest.selector
Here we are  testing using the Mock Coordinator instead of live Chainlink


CODEBASE EXPLANATION:

uint256 randomRequestId: Foundry sees this argument and generates a vast range of random numbers to test fulfillRandomWords against every imaginable request ID.

raffleEntered: A modifier setting up the base state (e.g., a player enters the raffle).

vm.expectRevert(...): Asserts that calling fulfillRandomWords without first triggering performUpkeep (which registers a real request ID with the VRF coordinator) must revert.

VRFCoordinatorV2_5Mock(...).fulfillRandomWords(...): Mimics Chainlink VRF attempting to deliver random numbers to your Raffle contract.

The Verdict: If someone (or Chainlink) tries to fulfill a randomRequestId before performUpkeep has officially registered that request, the VRF Coordinator will revert with InvalidRequest across all possible request IDs.
 */





// FINAL GIANT TEST(end-to-end test which will be a baseline for integration test as well)

function testFulfillrandomWordsPicksAWinnerResetsAndSendsMoney() public raffleEntered skipFork{
    // Arrange
    uint256 additionalEntrants = 3; // 4 total
    uint256 startingIndex = 1;
address expectedWinner = address(1);
// generally vrfcoordinator generally generates 777 as random number and to select a winner we do randomnum % no of player so here its 777 % 4 so 1 will be the winner 
// but this thing will only work when testing locally real VRF returns actual cryptographic randomness

    for(uint256 i = startingIndex ; i<(startingIndex + additionalEntrants);i++){
        address newPlayer = address(uint160(i));
        hoax(newPlayer ,1 ether);
        raffle.enterRaffle{value:entranceFee}();
    }
uint256 startingTimeStamp = raffle.getLastTimeStamp();
uint256 winnerStartingBalance = expectedWinner.balance;

// Act  (we want the request id so this is how we generate it )


vm.recordLogs(); 
    raffle.performUpKeep(""); 
    Vm.Log[] memory entries = vm.getRecordedLogs(); 
    console.log("Entries length:", entries.length);
console.logBytes32(entries[0].topics[0]);
console.logBytes32(entries[1].topics[1]);


    bytes32 requestId = entries[1].topics[1];
    console.log("Parsed Request ID:", uint256(requestId));
    VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(uint256(requestId) , address(raffle));
    //the above line shld give random num to our raffle and the fulfillrandomWords function is present vrfcoordinator mock


// Assert

address recentWinner = raffle.getRecentWinner();
Raffle.RaffleState rState = raffle.getRaffleState();
uint256 winnerBalance = recentWinner.balance;
uint256 endingTimeStamp = raffle.getLastTimeStamp();
uint256 prize = entranceFee * (additionalEntrants + 1);

assert(recentWinner == expectedWinner);
assert(uint256(rState)==0);
assert(winnerBalance == winnerStartingBalance + prize);
assert(endingTimeStamp > startingTimeStamp);
}


}




/*
STEPS
1.after writing basic test do forge build and forge test
2.do forge coverage to check how much percent you have did
3."forge coverage --report debug > coverage.txt"
The above command will create a file called coverage.txt, containing the specific lines of code that have not been covered yet.
4. make a .env file and add sepolia ka RPC URL
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





HOW YOU MAKE SURE TO RUN THIS UNIT TEST IN FORKED ENVIRONMENT
1 in struct of helperconfig add an account section and also add those in function returning config things
2 and then in deployRaffle,helperconfig,interactions jaha pe bhi vm.startBroadcast hai then pass the parameter of account thing
3.make sure to get repolia rpc url from alchemy and then do source .env
4.do forge build and then forge test --fork-url $SEPOLIA_RPC_URL 
5.but you will realise 2 test always gonna fail on a fork test
A.  function testFulfillrandomWordsPicksAWinnerResetsAndSendsMoney()
B.  function testFulfillrandomWordsCanOnlyBeCalledAfterPerformUpkeep(uint256 randomRequestId)
these test gonna fail always coz we are mocking, we are pretending to be chainlink vrf coordinator and obv its gonnal fail coz the actual chainlink coordinator have access controls and only let the chainlink nodes can call fulfill random words
so what we gonna do is we wil create a modifier skipFork
6.then do forge test and all and then forge coverage as well


EXPLANATION OF ABOVE THING

Why vm.startBroadcast with an Account?

Local Anvil Node: By default, Foundry uses address(0) or the first default Anvil key 
when you run tests locally. It mints infinite local ETH to simulate transactions.

Forked / Live Network: When you pass --fork-url, standard test scripts often fail if vm.startBroadcast() is called without specifying who is sending the transaction. 
On a fork, Foundry needs an actual address (with funds/keys or explicit prank/account impersonation) to sign the deployment and function calls properly. 
Adding an account to your HelperConfig ensures Foundry explicitly executes transactions from a valid, recognized actor.


2. Why do 2 tests fail on a Forked Network?

When testing locally (Chain ID 31337), your code deploys a VRFCoordinatorV2Mock (or VRFCoordinatorV2_5Mock).

Local Behavior: The mock contract lets your test script manually trigger subscription funding and call fulfillRandomWords(...) directly to simulate the Chainlink node returning a random number.

Forked/Live Network Behavior: When forking (e.g., Sepolia/Mainnet), your code targets the actual Chainlink VRF Coordinator contract address on that chain instead of deploying a local mock.

The Real Coordinator Constraints:

On a real network, fulfillRandomWords can only be called by the official Chainlink VRF off-chain node (which holds special permission keys on the coordinator contract).

When your unit test tries to simulate or force fulfillRandomWords directly on a forked real coordinator, the transaction reverts because you are not the Chainlink off-chain node.




 */

/*
FOUNDRY OPCODE DEBUGGER


"forge test --debug functionName"
basically it takes u through the low level bytes of a smart contract basically u get to now what is exactly happening with meory , storage,call data and all that good stuff
for know just know the method how u do this gonna learn it later in security course 



 */