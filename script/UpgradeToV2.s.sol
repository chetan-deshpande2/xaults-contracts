// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {AssetToken} from "src/AssetToken.sol";
import {AssetTokenV2} from "src/AssetTokenV2.sol";


contract UpgradeToV2 is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address proxyAddress = vm.envAddress("PROXY_ADDRESS");

        vm.startBroadcast(deployerPrivateKey);

        AssetTokenV2 newImplementation = new AssetTokenV2();

        AssetToken proxy = AssetToken(proxyAddress);
        proxy.upgradeToAndCall(address(newImplementation), "");

        vm.stopBroadcast();

        console.log("Upgrade Complete");
        console.log("Proxy Address:", proxyAddress);
        console.log("New Implementation Address:", address(newImplementation));
    }
}
