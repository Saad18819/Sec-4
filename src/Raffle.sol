// SPDX-License-Identifier:MIT

pragma solidity 0.8.19;

// we will be working with specific sets of contract that works best with 0.8.19

/*
basically the PROJECT IS LIKE A LOTTERY SYSTEM. people gonna buy the tickets or tokens whatever
and then the system will generate a random number which will automatically selects the winner


 */

/**
 * @title a sample raffle contract
 * @author Saad Khan
 * @notice This contract is for creating a sample raffle
 * @dev Implements Chainlink VRFv2.5
 */

// make sure to go through this contract once as well
import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";



// in lib smart brownie contract go to src/vrf/dev/VRFConsumerBaseV2Plus.sol this what we are inheriting
contract Raffle is VRFConsumerBaseV2Plus {
    error Raffle_SendMoreToEnterRaffle();
    error Raffle_TransferFailed();
    error Raffle_RaffleNotOpen();
    error Raffle_UpkeepNotNeeded(uint256 balance , uint256 playersLength , uint256 raffleState);
// If performUpkeep reverts because checkUpkeep returned false, the error won't just say "upkeep not needed". It will spit out the exact contract state at that moment—telling you current balance, playersLength, and raffleState.
// so it would be easy for me to check on which has coz the actual revert in our txn





    /* enum is a kind of type declaration so we gonna put it over the variable declaration */

    enum RaffleState {
        // in solidity each of the type can be converted to integers
        OPEN, // integer 0
        CALCULATING // integer 1
    }

    /*
    ENUM EXPLANATION

    An enum (short for enumeration) in Solidity is a user-defined data type used to create a restricted set of explicit constant values.
    examples of enum
    enum values are not written in all capital letters. The standard convention is to use PascalCase (Capitalized camelCase).

    enum Status {
        INACTIVE, // 0
        ACTIVE    // 1
    }

    enum Direction {
        NORTH, // 0
        SOUTH, // 1
        EAST,  // 2
        WEST   // 3
    }

    At least 1 member: An enum must have at least one option declared (you cannot create an empty enum {}).
    Default Value: An enum variable will always initialize to its first option (index 0).

    Cannot exceed 256 members: If you try to declare 257 options inside a single enum, the compiler will throw an error because it exceeds the uint8 storage limit.

    We generally use enum when a process goes through distince stages and we need to keep track of current status


    here we used enum for the purpose of tracking the raffle status like we dont want people to enter the raffle when we are calculating the winner okkk so at that time we need to restrrict people entering the raffle

     */

    /* VARIABLE DECLARATION */
    uint256 private immutable i_entranceFee;
    // @dev THe duration of the lottery in seconds
    uint256 private immutable i_interval;
    uint256 private s_lastTimeStamp; // it cant be set immutable coz it must be updated every lottery round, whenever a new winner is picked the timestamp needs to be updated to reset the timer
    address payable[] private s_players;
    // s implies storage variable and we keeping it storage variable coz people entering ragffle keeps changing so we dont wana make it immutable or constant
    // payable means see after winning the raffle that address needs to be paid so without oayable u wont be able to pay that address broooo
    // whenever a contract has to pick someone from storage and push money to them, you need a payable array
    address private s_recentWinner;
    RaffleState private s_raffleState;

    /*Struct variable declaration */
    bytes32 private immutable i_keyHash;
    uint256 private immutable i_subscriptionId;
    uint16 private constant REQUEST_CONFIRMATION = 3;
    uint32 private immutable i_callbackGasLimit;
    uint32 private constant NUM_WORDS = 1;

    /*

            uint16 private constant REQUEST_CONFIRMATION = 3;
    this means
    In your contract, that setting corresponds to REQUEST_CONFIRMATIONS = 3, which represents the number of block confirmations the Chainlink node must wait before generating and submitting the random number back to your contract.
       Request Emitted (Block $N$):When your contract calls pickWinner(), a transaction is processed in Block $N$, emitting an event requesting randomness from Chainlink.Waiting for Confirmations (Blocks $N+1$, $N+2$, $N+3$):The Chainlink VRF nodes do not respond immediately. They monitor the network and wait until 3 additional blocks are minted on top of the block containing your request.Fulfillment (Block $N+4$ or later):Once 3 blocks have passed, Chainlink triggers fulfillRandomWords() to deliver the random number and select the winner.
     this is done to prevent the manipulation of the history who won
    Increased security against potential blockchain reorganizations at the cost of longer waiting times for the result
         */

    /*EVENTS */

    event RaffleEntered(address indexed player);
    event WinnerPicked(address indexed winner);
event RequestedRaffleWinner(uint256 indexed requestId);


    // whenever u inherit a contract which has constructor then you need to add the inherited contracts constructor
    constructor(
        uint256 entranceFee,
        uint256 Interval,
        address vrfCoordinator,
        bytes32 gasLane,
        uint256 subscriptionId,
        uint32 callbackGasLimit
    )
        VRFConsumerBaseV2Plus(vrfCoordinator) // passed directly into parent constructor....basically thats how u write when u inherit contract which has constructor u write that constructor as well

    {
        i_entranceFee = entranceFee;
        i_interval = Interval; // so later on it would be easy for us to check how much time has passed to generate a random num
        s_lastTimeStamp = block.timestamp;

        i_keyHash = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        s_raffleState = RaffleState.OPEN; // we can write this as well RaffleState{0}
    }

    // function abt how people should be able to enter raffle
    function enterRaffle() external payable {
        // require(msg.value >= i_entranceFee,"Not enough ETH sent");
        // require is gas expenisve coz u storing string so best is to use custom errors

        // another method is using errors and the most gas efficient method
        if (msg.value < i_entranceFee) {
            revert Raffle_SendMoreToEnterRaffle();
        }

        // another crazy method is using error and require withut using string
        // require(msg.value >= i_entranceFee , SendMoreToEnterRaffle());
        // but above one only runs with specific version of solidity and compiler version so not a good option

        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle_RaffleNotOpen();
        }

        s_players.push(payable(msg.sender));
        // in solidity  it does not automatically convert a standard address into an address payable without explicitally mentioning it

        emit RaffleEntered(msg.sender);
        /*
        The emit keyword is used to fire (or trigger) a smart contract Event, broadcasting data to the outside world.
        Logs Data to the Blockchain: It takes msg.sender and permanently writes it into the Ethereum transaction logs.
        Notifies Off-Chain Apps (Frontend):
        Optimizes Gas Costs: Storing data in contract storage variables (s_players) is very expensive.
        Storing historical data in Event Logs is drastically cheaper on gas.



         */
    }





/**
 * @dev this is the function that the chainlink nodes will call to see
 * if the lottery is ready to have winner picked
 * The following should be true in order for upKeepNeeded to be true:
 * 1.The time interval has passed between raffle runs
 * the lottery is open
 * the contract has ETH
 * implicitly, your subscription has LINK
 * @param - ignored
 * @return upKeepNeeded - true if it's time to restart the lottery
 * 
 */

function checkUpkeep (bytes memory /*checkData */) public view returns(bool upKeepNeeded, bytes memory /*performData*/) {
 
   bool timeHasPassed = ((block.timestamp - s_lastTimeStamp) >= i_interval);
       bool isOpen = (s_raffleState == RaffleState.OPEN);
bool hasBalance = (address(this).balance > 0);
bool hasPlayers = (s_players.length > 0);

upKeepNeeded = timeHasPassed && isOpen && hasBalance && hasPlayers ;
// if above all thing is tru then we gotta get upKeepNeeded as true and like u dont have to metnion its datatype coz u already did inside function parameter 

return (upKeepNeeded ,"" ); // or to return null we can also do (upKeepNeeded , hex"0x0"); or hex""


}

/* 

the above function keeps on running and just checking upKeepNeeded and waiting for it to become true and as soon as it becomes true it calls the performUpKeep function
Chainlink nodes continuously call checkUpkeep off-chain for free to see if it is time to trigger the lottery draw.

 */














/*

Once Chainlink Automation sees upKeepNeeded == true, it executes performUpKeep on the blockchain.
Re-verification Guard: It calls checkUpkeep("") on-chain to prevent front-running or false execution. If upkeep isn't needed, it reverts.


1. Smart Contracts are Passive (They Can't "Wake Up" on Their Own)
Ethereum and EVM smart contracts cannot execute code by themselves on a timer. There is no setInterval or background thread inside EVM.
A smart contract function only executes when an external account (EOA) or another contract sends a transaction to it and pays the gas fee. If nobody sends a transaction to pickWinner(), the contract will sit idle forever, even if 10 days have passed.




2. The Old Manual Way
Without an automated keeper system, you had two options:
You (the admin) had to manually open your wallet every 24 hours, click pickWinner(), and pay the gas fee yourself.
You had to build and host your own server/cron job running 24/7 that pinged your smart contract to check if time had passed and call pickWinner(). If your server crashed or ran out of gas funds, your lottery broke.




3. How Chainlink Automation (Keepers) Fixes This
Instead of relying on you or a centralized server to click the button:
Off-chain Chainlink Nodes run a continuous loop off-chain calling checkUpkeep(). This check is a view function, so it costs $0 in gas.
As soon as checkUpkeep() returns true (time passed + players present + contract open), the Chainlink node automatically sends an on-chain transaction to execute performUpKeep().
By renaming pickWinner() to performUpKeep(), you gave the Chainlink network permission to click the "pick winner" button on your behalf the exact moment the conditions are met.


make sure to write function name as checkUpKeep and performUpKeep asit is required by the Chainlink Automation interface if you want Chainlink nodes to trigger your contract automatically.





 */

   /*  function pickWinner() external { */
   function performUpKeep(bytes calldata /*performData */) external{
        /* 
         to pick a random num first we have to make sure enough time has passsed since the start of lottery
        if ((block.timestamp - s_lastTimeStamp) < i_interval) {
            revert();
        }

        */

// check to see if enough time has passed
(bool upKeepNeeded,) = checkUpkeep("");
if(!upKeepNeeded){
    revert Raffle_UpkeepNotNeeded(address(this).balance , s_players.length , uint256(s_raffleState) );
}


        s_raffleState = RaffleState.CALCULATING; // so yeah if we get into the process of choosing a winner so we have updated the raffle current situation so now no one else can enter the state

        // CHAINLINK VRF CODE.... basically if u analyse it properly its a struct which is definitely exported from a contract file with the name give below

        VRFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient.RandomWordsRequest({
            keyHash: i_keyHash, // max gas price you are willing to pay for a request in wei
            subId: i_subscriptionId, // unique number that holds ETH to automatically pay for vrf random num request across ur smart contracts
            requestConfirmations: REQUEST_CONFIRMATION, // how many confirmations chainlink nodes shd wait before responding like after u send a request it will wait X number of block before trying to give you a random number
            callbackGasLimit: i_callbackGasLimit, // the limit for how much gas to use for the callback request
            numWords: NUM_WORDS, // this is the number of random numbers we want
            extraArgs: VRFV2PlusClient._argsToBytes(VRFV2PlusClient.ExtraArgsV1({nativePayment: false})) // this is where we can set some extra arguments depending on the chainlink VRF version(based on version u can pay with different things like native eth instead of LINK)...LINK is the native ERC-20 utility token of the Chainlink network. It serves as payment to the decentralized oracle network for generating provably fair random numbers and delivering them on-chain.
        });
        uint256 requestId = s_vrfCoordinator.requestRandomWords(request);
        // we send a request for a random number to the VRF coordinator, using the s_vrfCoordinator variable inherited from VRFConsumerBaseV2Plus
// Redundant : unnecessarily repetitive
// the below emit is redundant coz in vrfcoordinator requesId there as well its emitting the event
emit RequestedRaffleWinner(requestId);
        /*
        so basically in above code we have the access to s_vrfCoordinator so basically we requested a random word and then inside it is a whole bunch of stuff in here
        basically in lib/chainlink/contracts/vrf/dev/libraries we have VRF COORDINATOR V2 interface thing and in that we have struct which have all the datas in it

        in chainlink docs we have the explanation of keyhash and other things blah blah
        keyhash is the max amnt of gas so we telling it upfront thats why we used it in constructor as well
        we also add subscriptio ID into the constructor so your contracts knows which chainlink accnt to charge for randomness
        we make requestConfirmations as a constant number
        we also add callbackGasLimit into the constructor

        whenever we call a requestRandomWords it always returns a requestId
         */
    }



    /*
    getting random num on blockchain is quite difficult the main reason is the deterministic system...so to get it we gonna work with VRf chainlink
    getting random no is a two transaction process first we have to mae a transaction to request random num generator and in a second transaction the chainlink oracle will actually sends us or add some random num on chain

    for above code we just went to chainlibk vrf on google and copy pasted it and then u gotta be exporting that thing as well by opening that code in remix and then just copy paste the export thing
    and uk just export thing doest work well in foundry coz u cant extract it so we gotta be downloading chainlink brownie contract in our liubrary
    for downloading chainlink contract ukk what to do rytt like just go to google type chainlink brownie contract and it will give u the cmnd u gotta write that in the terminal
    and then u gotta do remapping in foundry.toml

    also like what we imported is that in lib => brownie contracts => vrf => dev => VRFConsumerBaseV2Plus.sol is actually inhrited and it has constructor in it
    and the important thing is if you inherit a contract that has a constructor like this what you need to do is in ur constructor u need to add that contracts constructor


     */


/* THE IMPORTANT METHOD CEI-Checks,Effects,Interaction Pattern ... the most important pattern i gotta keep in mind*/
    function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) internal override {
       // checks : we dont have any right now but its like if condition and all we are checking first
       


       // EFFECTS (Internal contract state)
        uint256 indexOfWinner = randomWords[0] % s_players.length; // since we will be having a single random words coz we only gonna select one winner
        // and keep in mind random number is frkn long like 23456345302564030789 smthng
        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner;
        s_players = new address payable[](0); // we just resetting the array
         s_raffleState = RaffleState.OPEN; // as we got the winner we have updated the situation accordingly so now people can enter raffle again coz we got the winner so now no chance of manipulation
        s_lastTimeStamp = block.timestamp;
        emit WinnerPicked(s_recentWinner); // this also comes under effects coz it aint interacting with external contract 
        // events (emit) are classified under Effects because an event only modifies the internal state of the current Ethereum node (writing to transaction logs), without transferring control to an external entity.
       

        // INTERACTION (this is gonna be the external contract interactions)
        (bool success,) = recentWinner.call{value: address(this).balance}("");
        // this contract will have money...like whatever u entrance fee is will be accumulated in this contract itself so yeah that all handsome amnt will be given to the winner
        if (!success) {
            revert Raffle_TransferFailed();
        }
     /*In smart contract security, an Interaction specifically refers to handing control over to another address or smart contract—such as an external call (.call{}, .transfer(), or calling another contract's function). When control is handed over, the external contract can execute arbitrary code and potentially reenter your contract before your state is updated. */
    }

    /*
    EXPLANATION:

    An abstract contract in Solidity is a contract that has at least one function defined without an implementation (without a code body { ... }). which is called an unimplemented function
    It acts as a blueprint or template that other contracts must inherit from and complete.
    abstract contract cannot be deployed directly and the unimplemented function is marked virtual so derived contract can override them
    and abstract contract naming is given by   abstract contract "name"{}
    VRFConsumerBaseV2Plus is a abstract contract...u can check out its codebase
    u might for a split sec can thought since its visibility is internal how we are suppose to call this function or override it but remember in internal the parent and the child contract has the accesss
    it is internal instead of external  nhi toh anyone on the internet could call it directly on your contract and fake random numbers to steal the lottery funds.
    To perform security checks, such as verifying that the caller is the expected authorized external source, before executing the main logic its the main reason to keeping it internal


    Chainlink provides an external visibility called rawFulfillRandomWords check in the same codebase. When Chainlink sends the random number back to your contract,
    it calls rawFulfillRandomWords function.
    That function verifies that the caller is genuine and in it we have fulfillrandomwords function so it will call
    then executes your internal fulfillRandomWords logic.



     */

    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }

function getRaffleState() external view returns(RaffleState){
    return s_raffleState;
}

function getPlayer(uint256 indexOfPlayer) external view returns(address){
    return s_players[indexOfPlayer];
}

}

/*
LEARNING

NatSpec (Ethereum Natural Language Specification Format) is a standardized documentation system used in Smart Contract development (primarily Solidity and Vyper). Inspired by Doxygen, it allows developers to write human-readable annotations directly above contracts, functions, events, state variables, and errors.
basically short me intro dena what we are actually building



SOLIDITY STYLE GUIDE to make it look professional

1.pragma statements
2.import statements
3.interfaces
4.libraries
5.contracts

inside each contracts the method is

// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

INSIDE FUNCTIONS

1.constructor
2.receive function (if exists)
3.fallback function (if exists)
4.external
5.public
6.internal
7.private
8.view & pure functions
 */

/*
EVENTS AND TOPIC EXPLANATIONS

1. What is an Event?
An event is a way for a smart contract to send a signal or message to the outside world (like your front-end web app or an off-chain database).

When something important happens in your contract (e.g., a user joins a raffle), the contract "emits" an event.

This creates a permanent log entry stored in the blockchain’s special log data structure.


2. What is a Topic?
A topic is simply an indexed parameter inside an event.

When you mark a variable as indexed inside an event definition, the Ethereum Virtual Machine (EVM) saves it in a special searchable index table (called topics) separate from the regular log data.

You can have a maximum of 3 indexed parameters (topics) per event because creating these search indexes costs extra gas.


. Why Use Them?
Why use Events? Smart contracts are blind and deaf to the outside world—they can't talk directly to your website UI. Events act as a bridge, allowing dApps (decentralized apps) to "listen" to what the contract is doing in real time.

Why use Topics (Indexing)? Without topics, searching through blockchain history is like searching for a needle in a haystack—an external app would have to download and read every single log one by one. Topics turn your logs into a searchable database so apps can find specific data instantly.



When to Use Them?
Use Events when:

You modify the state of the contract (like recording a user entry, changing a price, or transferring ownership) and want to notify off-chain applications that it happened.

Use Topics (Indexing) when:

You expect your front-end application or users to search, filter, or query historical data based on that specific parameter (e.g., “Show me all raffle entries made specifically by wallet address 0x123...” or “Show me every time the exchange rate changed to X”).


Assigning a value to a regular variable in the constructor simply sets its initial state. It does not lock it permanently unless you explicitly attach the immutable keyword to the variable declaration:
the above is specifically to understand s_lastTimeStamp coz u have put that in construcotr and after every lottery it renews the time
When Chainlink VRF returns the random number, your callback function (fulfillRandomWords) picks the winner, resets s_players, and updates s_lastTimeStamp:

 */

/*

ACTUAL STEPS
1.forge init
2.delete each and every file in src,test,script and make new for each of them
3.for vrf thing go to website chainlink vrf use subscription mode copy the chotus code part and then export thing as well
4.for vrf to run u gotta need to download smart contract chainlink brownie thing and its process is same just search for smart contract chainlink brownie and then it will give u the cmnd with the version to write in terminal
5.do remapping in foundry.toml for chainlink
6.and in between we can do "forge build" to make sure we doing everything crct
7. whatever code u have written in the end u do chainlink automation to automatically choose winner whenever enough time has passed
8.go through the chainlink automation site and just for the sake of learning keep in mind how to write that function which u have written above
9.first deploy script 
10.testing


 */
