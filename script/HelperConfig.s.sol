// SPDX-License-Identifier:MIT
pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";



abstract contract CodeConstants{
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

    struct NetworkConfig{
        uint256 entranceFee;
        uint256 interval;
        address vrfCoordinator;
        bytes32 gasLane;
        uint256 subscriptionId;
        uint32 callbackGasLimit;
    }






    NetworkConfig public localNetworkConfig;


    mapping(uint256 chainId => NetworkConfig public networkConfigs);

    constructor(){
        networkConfigs[ETH_SEPOLIA_CHAIN_ID] = getSepoliaEthConfig();

    }




function getConfigByChainId(uint256 chainId) public returns (NetworkConfig memory){
    if(networkConfigs[chainId].vrfCoordinator != address(0)){
        return networkConfigs[chainId];
    }else if(chainId == LOCAL_CHAIN_ID){
// getOrCreateANvilETH
    }else{
        revert HelperConfig_InvalidChainId();
    } 
}





    function getSepoliaEthConfig() public pure returns(NetworkConfig memory){
       return NetworkConfig({
entranceFee: 0.01 ether, // 1e16
interval :30, // 30 sec
vrfCoordinator:0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625, // gotta search it up on chainlink vrf supported network site
gasLane:0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae // same as above
callbackGasLimit:500000 // 500,000 gas
subscriptionId: 0


       });
    }

function getOrCreateAnvilEthCOnfig() public returns(NetworkConfig memory){
    // we will first check if we have set an acitve network config
   if(localNetworkConfig.vrfCoordinator != address(0)){
    return localNetworkConfig;
   } 
}


}


/*
LEARNINGS

1. whenever u create a struct u separate variables by ; but when u initiate an instance u separate varibale by ,












 */