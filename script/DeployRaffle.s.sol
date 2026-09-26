// SPDX-License-Identifier:MIT

pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {CreateSubscription} from "./interactions.s.sol";



contract DeployRaffle is Script{

function run() public returns(Raffle,HelperConfig){
return deployContract();
}

function deployContract() public returns(Raffle, HelperConfig) {
HelperConfig helperconfig = new HelperConfig();
// local => deploy mocks, get local config
// sepolia => get sepolia config
HelperConfig.NetworkConfig memory config = helperconfig.getConfig();


if(config.subscriptionId==0){
    // create subscription
CreateSubscription  createSubs = new CreateSubscription();
   (config.subscriptionId , config.vrfCoordinator) = createSubs.createSubscription(config.vrfCoordinator);
}


vm.startBroadcast();
Raffle raffle = new Raffle(
    config.entranceFee,
    config.interval,
    config.vrfCoordinator,
    config.gasLane,
    config.subscriptionId,
    config.callbackGasLimit
);
vm.stopBroadcast();
return (raffle, helperconfig);

}



}


/*
ACtual steps
1.just write contract name{} nothing inside and then pragma export and all and do "forge build"





 */
