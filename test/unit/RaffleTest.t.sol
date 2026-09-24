// SPDX-License-Identifier:MIT

pragma solidity 0.8.19;

import {Test} from "forge-std/Test.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {Raffle} from "src/Raffle.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";




contract Raffletest is Test{
    Raffle public raffle;
    HelperConfig public helperConfig;

    address public PLAYER = makeAddr("player");
    uint256 public constant STARTING_PLAYER_BALANCE = 10 ether;
 
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

// testing emit is little bit funky although u can refer to foundry book for the cheatcode

function testEnteringRaffleEmitsEvent() public{
    
}

}

/*
STEPS
after writing basic test do forge build and forge test
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