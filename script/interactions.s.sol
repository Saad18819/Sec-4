// SPDX-License-Identifier:MIT
pragma solidity 0.8.19;
import {Script,console} from "forge-std/Script.sol";
import {HelperConfig,CodeConstants} from "./HelperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "test/mocks/LinkToken.sol";


contract CreateSubscription is Script{

function CreateSubscriptionUsingConfig() public returns(uint256,address){
    
    HelperConfig helperConfig = new HelperConfig();
address vrfcoordinator = helperConfig.getConfig().vrfCoordinator;
(uint256 subId,) = createSubscription(vrfcoordinator);
return (subId , vrfcoordinator);


}

function createSubscription(address vrfCoordinator)public returns(uint256,address){

console.log("Creating subscription on chainID:",block.chainid);


vm.startBroadcast();
uint256 subId = VRFCoordinatorV2_5Mock(vrfCoordinator).createSubscription(); // here createSubscription function aint same jo uppar likha hai its the function present in vrfcoordinatomock.sol vali file and mock _5 vali me inherit hora
vm.stopBroadcast();

console.log("your subscription Id is:",subId);
console.log("please update the subscription in your HelperConfig.s.sol");
return (subId , vrfCoordinator);
}

function run() public{
CreateSubscriptionUsingConfig();
}


}


contract FundSubscription is Script,CodeConstants{
uint256 public constant FUND_AMOUNT = 3 ether;// 3 LINKS coz link also have this 18 decimal thing


    function fundSubscriptionUsingConfig() public{
  HelperConfig helperConfig = new HelperConfig();
address vrfcoordinator = helperConfig.getConfig().vrfCoordinator;
uint256 subscriptionId = helperConfig.getConfig().subscriptionId;
address linkToken = helperConfig.getConfig().link;
fundSubscription(vrfcoordinator,subscriptionId,linkToken);
}

function fundSubscription(address vrfCoordinator , uint256 subscriptionId , address linkToken) public{
console.log("Funding subscription:",subscriptionId);
console.log("Using vrfCoordinator:",vrfCoordinator);
console.log("On ChainId:",block.chainid);

if(block.chainid == LOCAL_CHAIN_ID ){
  vm.startBroadcast();
  VRFCoordinatorV2_5Mock(vrfCoordinator).fundSubscription(subscriptionId , FUND_AMOUNT);
vm.stopBroadcast();

}else{
 vm.startBroadcast();
 LinkToken(linkToken).transferAndCall(vrfCoordinator, FUND_AMOUNT , abi.encode(subscriptionId));
vm.stopBroadcast();
// here dont think much abt transferAndCall just remember its a special link token function
}
}

function run() public{
fundSubscriptionUsingConfig();
}

}











/*
LEARNING

Step 1: The Core Problem (Why VRF Exists)
Imagine you are running a lottery in real life.

Players buy tickets.

At the end of the week, you pull a winning number out of a hat.

Now put that lottery on Ethereum (Raffle.sol).
Blockchains are completely deterministic—every node on the network must compute the exact same result for every line of code. 
Because of this, EVMs cannot generate true random numbers natively. 
If you try using block.timestamp or block.prevrandao, miners/validators can manipulate it to win the lottery.



To get a verifiably random number,
your contract has to ask an external, off-chain service: Chainlink VRF (Verifiable Random Function).










Step 2: How Chainlink VRF Charges You (The Subscription Model)
Chainlink nodes don't work for free. Generating a random number and submitting a cryptographic proof back to the blockchain costs gas and services.

Chainlink handles payment through a Subscription Model:

You create an Account / Vault (a Subscription) on Chainlink's system.

You deposit LINK tokens into that subscription account to pay for future random numbers.

You tell Chainlink: "Hey, my Raffle.sol contract is authorized to use the funds in this Subscription." (This is called adding a Consumer).

When Raffle.sol requests a random number, Chainlink checks:

Does this request come from an authorized Consumer?

Is there enough LINK in the Subscription to cover the request?

If yes, Chainlink sends the random number back!









Step 3: The 3-Step Setup Needed for VRF
Before Raffle.sol can ask for a single random number, three things must happen in order:

[Step A: Create Subscription]  ──> Gives you a `subscriptionId` (a unique uint256 number)
             │
             ▼
[Step B: Fund Subscription]    ──> Puts LINK tokens into that `subscriptionId`
             │
             ▼
[Step C: Add Consumer]         ──> Registers `Raffle.sol` address to that `subscriptionId`


If you miss any of these three steps, your contract will revert when it tries to pick a winner.

Step 4: the code u written actually does Step A(that is create Subscription)











VRFCoordinatorV2_5Mock(vrfCoordinator)

just to clear the doubt we aint using mock deployment and all its just it has a function of createSubsciption id so to get that we doing all of this



for FUND contract also make sure

make a folder of mocks inside test folder and inside that LinkToken.sol thing and then on just google search 
github linktoken.sol u will get the repo, copy the code and paste it

and in linktoken we are importing erc 20 solmate something so for that search on google solmate github to check the version of it and copy the actual url of that github and then in termianl write
"forge install URL@version"
and inside foundry.toml in remappings do
'@solmate=lib/solmate/src/'

and then import it here in this codebase
and in helperconfig also make sure to deploy that mock as well 


the above process is for anvil coz we need mock for it rytt

 */