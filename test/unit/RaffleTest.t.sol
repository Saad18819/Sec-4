// SPDX-License-Identifier:MIT

pragma solidity 0.8.19;
import {test} from "forge-std/Test.sol";
import {DeployRaffle} from "../../scripts/DeployRaffle.s.sol";
import {Raffle} from "src/Raffle.sol";
import {HelperConfig} from "script/Helperconfig.s.sol";




contract Raffletest is test{
    Raffle public raffle;
    Helperconfig public helperConfig;

    address public PLAYER = makeAddr("player");
    uint256 public constant STARTING_PLAYER_BALANCE = 10 ether;



    function setUp() external{
      DeployRaffle deployer = new DeployRaffle();
  (raffle , helperConfig) = deployer.DeployRaffle();
    }





}