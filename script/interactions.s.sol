// SPDX-License-Identifier:MIT
pragma solidity 0.8.19;
import {Script,console} from "forge-std/Script.sol";
import {HelperConfig,CodeConstants} from "./HelperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "test/mocks/LinkToken.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

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
 /*linkToken: The address of the live, real LINK token contract on Sepolia.

LinkToken(...): The ABI / interface wrapper that tells Solidity 
"Hey, at this address on Sepolia, 
there is a function called transferAndCall(address, uint256, bytes)—encode the call for me."
for mainnet or sepolia or any real netowrk u dont need to deploy that LinkToken.sol thing like after importing it will work fine as well but yeah u need That linktoken file 
but for anvil and local testing u gotta be deploying it

*/
vm.stopBroadcast();
// here dont think much abt transferAndCall just remember its a special link token function
}
}

/*
LEARNING

1. On Local Chain (Anvil)

On your local Anvil chain, you don't actually need real LINK tokens or a real ERC-20 transfer process to get funds into the VRF subscription. The Chainlink mock contract (VRFCoordinatorV2_5Mock) includes a special cheat helper function named .fundSubscription(subId, amount).

Calling this helper directly mints fake balance straight into your subscription inside the mock coordinator storage mapping—bypassing the need for any LINK token contract interactions.



2. On Real Networks (Sepolia / Mainnet)

On a live testnet like Sepolia, the official Chainlink VRF Coordinator contract does not have a cheat function like .fundSubscription(...).

Instead, Chainlink uses the ERC-677 token standard (which extends ERC-20 with transferAndCall). You must interact directly with the actual LINK Token contract, transfer LINK to the VRF Coordinator's contract address, and pass the subscriptionId in the data payload (abi.encode(subscriptionId)). The VRF Coordinator receives the tokens, reads the encoded subId from the call, and credits your subscription balance.



 */

function run() public{
fundSubscriptionUsingConfig();
}

}
/*

FUND CONTRACT LEARNING


for FUND contract also make sure

make a folder of mocks inside test folder and inside that LinkToken.sol thing and then on just google search 
github linktoken.sol u will get the repo, copy the code and paste it

and in linktoken we are importing erc 20 solmate something so for that search on google solmate github to check the version of it and copy the actual url of that github and then in termianl write
"forge install URL@version"
and inside foundry.toml in remappings do
'@solmate=lib/solmate/src/'

and then import it here in this codebase
and in helperconfig also make sure to deploy that mock as well 
. and then u gotta go to Deploy file and then write the logic of  Fund

the above process is for anvil coz we need mock for it rytt

In Solidity, LinkToken(linkToken) is an interface/type casting wrapper (or instantiation) that tells the compiler how to interact with the contract deployed at the address stored in the variable linkToken.



 */







contract AddConsumer is Script{

  function run() external{
    address mostRecentDeployed = DevOpsTools.get_most_recent_deployment("Raffle",block.chainid);
    addConsumerUsingConfig( mostRecentDeployed);
  }

  /*
  although here we havent imported our raffle contract but still wrote the name of it  "Raffle" but but but what actually happens behind the hood is that
  DevOpsTools is a helper library provided by Cyfrin (foundry-devops). It does not look at Solidity contract types or compiler imports. Instead, it reads the JSON files saved in your local broadcast/ folder generated by Forge during deployments.

When you run a deployment script (like DeployRaffle.s.sol), Forge creates a tracking JSON file inside broadcast/DeployRaffle.s.sol/<chain_id>/run-latest.json. Inside that JSON file, Forge logs the exact artifact name of every contract created:

so always make sure to write the correct contract type
  
   */

  function addConsumerUsingConfig(address mostRecentDeployed) public{
    HelperConfig helperConfig = new HelperConfig();
    uint256 subId = helperConfig.getConfig().subscriptionId;
    address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
addConsumer(mostRecentDeployed,vrfCoordinator,subId);
  }


  function addConsumer(address contractToAddtoVrf, address vrfCoordinator , uint256 subId) public{
console.log("Adding consumer contract:",contractToAddtoVrf);
console.log("To vrfCoordinator:",vrfCoordinator);
console.log("On ChainId:",block.chainid);

vm.startBroadcast();
VRFCoordinatorV2_5Mock(vrfCoordinator).addConsumer(subId,contractToAddtoVrf); // this function is present in SubscriptionApi file
vm.stopBroadcast();
// contractToAddtoVrf means deployed contract ka address
  }
}

/*
ADD CONSUMER LEARNING

1. for consumer we need the latest deployed address of the contract
2. so for latest deployed contract go to google and search foundry devops u will get the repo and in that down there we have 
"forge install Cyfrin/foundry-devops"

3.also its already provided in the repo what update u gotta do in foundry.toml
4.and then u gotta import
"import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";
5 first write the logic here and then u gotta go to Deploy file and write the logic of Add consumer
6. make sure to do import crctly in deploy file


git add .
git commit -m "fix: updated scripts and tests"
git push
 */










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





 */