// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {
    ERC1967Proxy
} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {AssetToken} from "src/AssetToken.sol";


contract AssetTokenHandler is Test {
    AssetToken public token;
    address public admin;

    uint256 public ghostMintedTotal;
    mapping(address => uint256) public ghostBalances;

    address[] public actors;
    address internal currentActor;

    constructor(AssetToken _token, address _admin) {
        token = _token;
        admin = _admin;

        for (uint256 i = 0; i < 5; i++) {
            actors.push(makeAddr(string(abi.encodePacked("actor", i))));
        }
    }

    modifier useActor(uint256 actorSeed) {
        currentActor = actors[bound(actorSeed, 0, actors.length - 1)];
        _;
    }

    function mint(
        uint256 amount,
        uint256 actorSeed
    ) external useActor(actorSeed) {
        uint256 available = token.maxSupply() - token.totalSupply();
        amount = bound(amount, 0, available);

        if (amount == 0) return;

        vm.prank(admin);
        token.mint(currentActor, amount);

        ghostMintedTotal += amount;
        ghostBalances[currentActor] += amount;
    }

    function transfer(
        uint256 amount,
        uint256 fromSeed,
        uint256 toSeed
    ) external {
        address from = actors[bound(fromSeed, 0, actors.length - 1)];
        address to = actors[bound(toSeed, 0, actors.length - 1)];

        amount = bound(amount, 0, token.balanceOf(from));

        if (amount == 0 || from == to) return;

        vm.prank(from);
        bool success = token.transfer(to, amount);
        require(success, "transfer failed");

        ghostBalances[from] -= amount;
        ghostBalances[to] += amount;
    }

    function getActorsLength() external view returns (uint256) {
        return actors.length;
    }
}
