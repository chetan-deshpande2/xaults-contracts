// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {
    ERC1967Proxy
} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {AssetToken} from "src/AssetToken.sol";

contract Deploy is Script {
    string constant DEFAULT_NAME = "Xaults Asset Token";
    string constant DEFAULT_SYMBOL = "XALT";
    uint256 constant DEFAULT_MAX_SUPPLY = 1_000_000 ether; // 1M tokens

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address admin = vm.addr(deployerPrivateKey);

        // Allow overriding defaults via env vars
        string memory name = vm.envOr("TOKEN_NAME", DEFAULT_NAME);
        string memory symbol = vm.envOr("TOKEN_SYMBOL", DEFAULT_SYMBOL);
        uint256 maxSupply = vm.envOr("MAX_SUPPLY", DEFAULT_MAX_SUPPLY);

        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy implementation
        AssetToken implementation = new AssetToken();

        // 2. Encode initialize call
        bytes memory initData = abi.encodeCall(
            AssetToken.initialize,
            (name, symbol, maxSupply, admin)
        );

        // 3. Deploy proxy pointing to implementation
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(implementation),
            initData
        );

        vm.stopBroadcast();

        console.log("Deployment Complete");
        console.log("Implementation Address:", address(implementation));
        console.log("Proxy Address:", address(proxy));
        console.log("Admin Address:", admin);
        console.log("Max Supply:", maxSupply / 1 ether, "tokens");
    }
}
