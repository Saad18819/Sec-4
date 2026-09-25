// SPDX-License-Identifier:MIT
pragma solidity 0.8.19;
import {Script,console} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

contract CreateSubscription is Script{

function CreateSubscriptionUsingConfig() public{
    HelperConfig helperConfig = new HelperConfig();
address vrfcoordinator = helperConfig.getConfig().vrfCoordinator;
createSubscription(vrfcoordinator);



}

function createSubscription(address vrfCoordinator)public returns(uint256,address){

console.log("Creating subscription on chainID:",block.chainid);


vm.startBroadcast();
uint256 subId = VRFCoordinatorV2_5Mock(vrfCoordinator).createSubscription();
vm.stopBroadcast();

console.log("your subscription Id is:",subId);
console.log("please update the subscription in your HelperConfig.s.sol");
return (subId , vrfCoordinator);
}

function run() public{
CreateSubscriptionUsingConfig();
}


}