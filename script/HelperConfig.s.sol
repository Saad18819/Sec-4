// SPDX-License-Identifier:MIT
pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";

contract HelperConfig is Script{

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

    constructor(){}

    function getSepoliaEthConfig() public pure returns(NetworkConfig memory){
       return NetworkConfig({
entranceFee: 0.01 ether, // 1e16
interval :30, // 30 sec
vrfCoordinator:0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625, // gotta search it up on chainlink vrf supported network site



       });
    }
}