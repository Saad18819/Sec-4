// SPDX-License-Identifier:MIT

pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {CreateSubscription,FundSubscription, AddConsumer} from "./interactions.s.sol";



contract DeployRaffle is Script{

function run() public {
deployContract();
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

// Fund It
FundSubscription fundSubscription = new FundSubscription();
fundSubscription.fundSubscription(config.vrfCoordinator ,config.subscriptionId,config.link);


}


vm.startBroadcast(config.account);
Raffle raffle = new Raffle(
    config.entranceFee,
    config.interval,
    config.vrfCoordinator,
    config.gasLane,
    config.subscriptionId,
    config.callbackGasLimit
);
vm.stopBroadcast();

/*
First we need to deploy a contract and then gotta add a consumer coz to add consumer u need a deployed contract address
also u dont need to broadcast coz broadcast toh interaction me kar diya tha already
 */
AddConsumer addConsumer = new AddConsumer();
addConsumer.addConsumer(address(raffle),config.vrfCoordinator, config.subscriptionId);
return (raffle, helperconfig);

}



}


/*
ACtual steps
1.just write contract name{} nothing inside and then pragma export and all and do "forge build"





 */
