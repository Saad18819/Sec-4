// SPDX-License-Identifier:MIT
pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";
import { VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFCoordinatorV2_5Mock.sol";


abstract contract CodeConstants{
/* VRF MOCK VALUES */
uint96 public MOCK_BASE_FEE = 0.25 ether; //The flat fee charged by Chainlink for every single randomness request.
uint96 public MOCK_GAS_PRICE_LINK = 1e9; // The simulated gas price of the network (in Gwei/wei) used to calculate how much gas the Chainlink node spends to send the random number back to your contract.
// LINK / ETH price
int256 public MOCK_WEI_PER_UINT_LINK = 4e15; // The mock conversion rate between ETH and LINK tokens.
// technical parameters like base fees can theoretically be set to 0 in a test environment, but setting realistic non-zero mock values is intentional:


    uint256 public constant ETH_SEPOLIA_CHAIN_ID = 1115511;
uint256 public constant LOCAL_CHAIN_ID = 31337;
}



/*
1. it wasnt necessary for me to write abstract contract here i could have declared them directly inside helperconfig
2.by separrating code Constants our codebase stays modular like code constant contains all the constant and helperconfig handles all the logic
3. in soldity marking a contract abstract means "This contract is not meant to be deployed on its own; it exists solely to be inherited by other contracts."
 */


contract HelperConfig is CodeConstants, Script{

   error HelperConfig_InvalidChainId();



// When you build a HelperConfig.s.sol script to deploy your contract across different chains (Anvil, Sepolia, Mainnet), you create a NetworkConfig struct to bundle all the chain-specific variables that your contract needs to deploy.
// although here we have taken all the parameter of chainlik vrf inside the struct

    struct NetworkConfig{
        uint256 entranceFee;
        uint256 interval;
        address vrfCoordinator;
        bytes32 gasLane;
        uint256 subscriptionId;
        uint32 callbackGasLimit;
    }

/*
You are completely right to question that—technically, parameters like interval or entranceFee don't depend on the underlying blockchain architecture the way vrfCoordinator or gasLane do.   
However, they are included in NetworkConfig for testing and environment customization reasons:
1. Fast Local Testing vs. Production RealityWhen testing locally on Anvil, you want your tests to run as fast as humanly possible.
Local Anvil: You might set interval to 30 seconds (or even shorter) so your Foundry tests don't have to wait around or warp through huge amounts of time.  
 Live Testnet / Mainnet: You might want the lottery to run once every day (86400 seconds) or once every week.   
 By putting interval inside NetworkConfig, you can change how your raffle behaves on local vs. live networks without hardcoding numbers directly inside your Raffle.sol contract.  

so to summarise u generally write all the parameters in the struct which are dependent on chainlink and also those parameters whose value we dont wanna hardcode 




 */




    NetworkConfig public localNetworkConfig;


   mapping(uint256 chainId => NetworkConfig config) public networkConfigs;

    constructor(){
        networkConfigs[ETH_SEPOLIA_CHAIN_ID] = getSepoliaEthConfig();

    }




function getConfigByChainId(uint256 chainId) public returns (NetworkConfig memory){
    if(networkConfigs[chainId].vrfCoordinator != address(0)){
        return networkConfigs[chainId];
    }else if(chainId == LOCAL_CHAIN_ID){
return getOrCreateAnvilEthCOnfig();
    }else{
        revert HelperConfig_InvalidChainId();
    } 
}

function getConfig() public returns(NetworkConfig memory){
    return getConfigByChainId(block.chainid);
}





    function getSepoliaEthConfig() public pure returns(NetworkConfig memory){
    localNetworkConfig = NetworkConfig({
entranceFee: 0.01 ether, // 1e16
interval :30, // 30 sec
vrfCoordinator:0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625, // gotta search it up on chainlink vrf supported network site
gasLane:0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae // same as above
callbackGasLimit:500000 // 500,000 gas
subscriptionId: 0


       });

       return localNetworkConfig;
    }







function getOrCreateAnvilEthCOnfig() public returns(NetworkConfig memory){
    // we will first check if we have set an active network config
   if(localNetworkConfig.vrfCoordinator != address(0)){
    return localNetworkConfig;
   } 
// Deploy mocks and such...look at the import thing to locate the file of the mock
vm.startBroadcast();
VRFCoordinatorV2_5Mock vrfCoordinatorMock = new VRFCoordinatorV2_5Mock(MOCK_BASE_FEE,MOCK_GAS_PRICE_LINK ,MOCK_WEI_PER_UINT_LINK);
vm.stopBroadcast();


localNetworkConfig = NetworkConfig({

entranceFee: 0.01 ether, // 1e16
interval :30, // 30 sec
vrfCoordinator:address(vrfCoordinatorMock);
// here gaslane address and callback doesnt matter vrfcoordinator address of mock will figure that out so here u write anything
gasLane:0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae // same as above
callbackGasLimit:500000 // 500,000 gas
subscriptionId: 0

});

return localNetworkConfig;
}


}


/*
LEARNINGS

1. whenever u create a struct u separate variables by ; but when u initiate an instance u separate varibale by ,


DIfference between pure and view

A. VIEW
A function marked as view promises that it will read but not write to the contract's storage or the blockchain state.

``

uint256 public number = 10; // State variable in persistent storage

function getNumber() public view returns (uint256) {
    return number; // Reading state from storage
}

``

Writing to state means modifying, adding, or deleting data saved on the blockchain





B.PURE

A function marked as pure promises that it will neither read from nor write to the contract's storage or the blockchain state.

In getSepoliaEthConfig():

All values (such as 0.01 ether, addresses, gas limits) are hardcoded directly inside the function body.

It does not read any state variables, mapping data, balance info, or block variables (like block.timestamp or block.chainid).
Instead of reading an existing struct saved in state, this function is constructing a brand-new struct instance from scratch on the fly in memory.
NetworkConfig({ ... }) is a constructor call: It takes those literal, hardcoded values (0.01 ether, 30, 0x8103..., etc.) and packages them into a brand-new NetworkConfig struct inside temporary memory (memory).  
 entranceFee, interval, vrfCoordinator are field keys, not variables: Those labels inside the curly braces are the named properties of the NetworkConfig struct definition, not state variables stored on the blockchain. 












 */