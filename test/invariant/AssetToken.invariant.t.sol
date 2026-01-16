// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {
    ERC1967Proxy
} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {AssetToken} from "src/AssetToken.sol";
import {AssetTokenHandler} from "./handlers/AssetTokenHandler.sol";

contract AssetTokenInvariantTest is Test {
    AssetToken public token;
    AssetTokenHandler public handler;
    address public admin = makeAddr("admin");

    uint256 public constant MAX_SUPPLY = 1_000_000 ether;

    function setUp() public {
        AssetToken impl = new AssetToken();
        bytes memory initData = abi.encodeCall(
            AssetToken.initialize,
            ("Xaults Asset Token", "XALT", MAX_SUPPLY, admin)
        );
        ERC1967Proxy proxy = new ERC1967Proxy(address(impl), initData);
        token = AssetToken(address(proxy));

        handler = new AssetTokenHandler(token, admin);
        targetContract(address(handler));
    }

    function invariant_TotalSupplyNeverExceedsMax() public view {
        assertLe(token.totalSupply(), token.maxSupply());
    }

    function invariant_GhostMatchesTotalSupply() public view {
        assertEq(handler.ghostMintedTotal(), token.totalSupply());
    }

    function invariant_BalancesSumToGhostMinted() public view {
        uint256 sum;
        for (uint256 i = 0; i < handler.getActorsLength(); i++) {
            sum += token.balanceOf(handler.actors(i));
        }
        assertEq(sum, handler.ghostMintedTotal());
    }
}
