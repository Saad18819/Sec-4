// SPDX-License-Identifier:MIT
pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";



abstract contract CodeConstants{
    uint256 public constant ETH_SEPOLIA_CHAIN_ID = 1115511;
uint256 public constant LOCAL_CHAIN_ID = 31337;
}

contract HelperConfig is CodeConstants, Script{

   error HelperConfig_InvalidChainId();





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




function getConfigByChainId(uint256 chainId) public view returns (NetworkConfig memory){
    if(networkConfigs[chainId].vrfCoordinator != address(0)){
        return networkConfigs[chainId];
    }else if(chainId=LOCAL_CHAIN_ID){
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
}