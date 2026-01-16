// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {
    ERC1967Proxy
} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {AssetToken} from "src/AssetToken.sol";
import {AssetTokenV2} from "src/AssetTokenV2.sol";
import {IAssetToken} from "src/interfaces/IAssetToken.sol";

contract AssetTokenTest is Test {
    AssetToken public implementation;
    AssetToken public token;
    ERC1967Proxy public proxy;

    address public admin = makeAddr("admin");
    address public minter = makeAddr("minter");
    address public user = makeAddr("user");
    uint256 public userPrivateKey = 0x1234;

    uint256 public constant MAX_SUPPLY = 1_000_000 ether;

    function setUp() public {
        // Derive user address from private key for permit tests
        user = vm.addr(userPrivateKey);

        implementation = new AssetToken();

        bytes memory initData = abi.encodeCall(
            AssetToken.initialize,
            ("Xaults Asset Token", "XALT", MAX_SUPPLY, admin)
        );
        proxy = new ERC1967Proxy(address(implementation), initData);
        token = AssetToken(address(proxy));
    }

    function test_Initialize_SetsNameAndSymbol() public view {
        assertEq(token.name(), "Xaults Asset Token");
        assertEq(token.symbol(), "XALT");
    }

    function test_Initialize_SetsMaxSupply() public view {
        assertEq(token.maxSupply(), MAX_SUPPLY);
    }

    function test_Initialize_GrantsAdminRole() public view {
        assertTrue(token.hasRole(token.DEFAULT_ADMIN_ROLE(), admin));
    }

    function test_Initialize_GrantsMinterRole() public view {
        assertTrue(token.hasRole(token.MINTER_ROLE(), admin));
    }

    function test_Mint_WithMinterRole_Success() public {
        vm.prank(admin);
        token.mint(user, 100 ether);

        assertEq(token.balanceOf(user), 100 ether);
    }

    function test_Mint_EmitsTokensMintedEvent() public {
        vm.prank(admin);
        vm.expectEmit(true, false, false, true);
        emit IAssetToken.TokensMinted(user, 100 ether);
        token.mint(user, 100 ether);
    }

    function test_RevertWhen_MintWithoutRole() public {
        vm.prank(user);
        vm.expectRevert();
        token.mint(user, 100 ether);
    }

    function test_RevertWhen_MintExceedsMaxSupply() public {
        vm.prank(admin);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAssetToken.MaxSupplyExceeded.selector,
                MAX_SUPPLY + 1,
                MAX_SUPPLY
            )
        );
        token.mint(user, MAX_SUPPLY + 1);
    }

    function test_Permit_AllowsGaslessApproval() public {
        uint256 amount = 100 ether;
        uint256 deadline = block.timestamp + 1 hours;

        // Build permit digest
        bytes32 permitTypehash = keccak256(
            "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
        );
        bytes32 structHash = keccak256(
            abi.encode(
                permitTypehash,
                user,
                admin,
                amount,
                token.nonces(user),
                deadline
            )
        );
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", token.DOMAIN_SEPARATOR(), structHash)
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPrivateKey, digest);

        token.permit(user, admin, amount, deadline, v, r, s);

        assertEq(token.allowance(user, admin), amount);
    }

    function test_Upgrade_WithAdminRole_Success() public {
        AssetTokenV2 newImpl = new AssetTokenV2();

        vm.prank(admin);
        token.upgradeToAndCall(address(newImpl), "");

        AssetTokenV2 tokenV2 = AssetTokenV2(address(proxy));
        vm.prank(admin);
        tokenV2.pause();
        assertTrue(tokenV2.paused());
    }

    function test_RevertWhen_UpgradeWithoutRole() public {
        AssetTokenV2 newImpl = new AssetTokenV2();

        vm.prank(user);
        vm.expectRevert();
        token.upgradeToAndCall(address(newImpl), "");
    }

    function test_Upgrade_PreservesState() public {
        vm.prank(admin);
        token.mint(user, 100 ether);

        AssetTokenV2 newImpl = new AssetTokenV2();
        vm.prank(admin);
        token.upgradeToAndCall(address(newImpl), "");

        assertEq(
            token.balanceOf(user),
            100 ether,
            "Balance should persist after upgrade"
        );
        assertEq(
            token.maxSupply(),
            MAX_SUPPLY,
            "MaxSupply should persist after upgrade"
        );
    }

    function test_V2_Pause_BlocksTransfers() public {
        AssetTokenV2 newImpl = new AssetTokenV2();
        vm.prank(admin);
        token.upgradeToAndCall(address(newImpl), "");
        AssetTokenV2 tokenV2 = AssetTokenV2(address(proxy));

        vm.prank(admin);
        tokenV2.mint(user, 100 ether);

        vm.prank(admin);
        tokenV2.pause();

        vm.prank(user);
        vm.expectRevert();
        tokenV2.transfer(admin, 50 ether);
    }

    function test_V2_Unpause_AllowsTransfers() public {
        AssetTokenV2 newImpl = new AssetTokenV2();
        vm.prank(admin);
        token.upgradeToAndCall(address(newImpl), "");
        AssetTokenV2 tokenV2 = AssetTokenV2(address(proxy));

        vm.prank(admin);
        tokenV2.mint(user, 100 ether);

        vm.prank(admin);
        tokenV2.pause();

        vm.prank(admin);
        tokenV2.unpause();

        vm.prank(user);
        bool success = tokenV2.transfer(admin, 50 ether);
        assertTrue(success);

        assertEq(tokenV2.balanceOf(admin), 50 ether);
        assertEq(tokenV2.balanceOf(user), 50 ether);
    }

    function testFuzz_Mint_ArbitraryAmounts(uint96 amount) public {
        vm.assume(amount > 0 && amount <= MAX_SUPPLY);

        vm.prank(admin);
        token.mint(user, amount);

        assertEq(token.balanceOf(user), amount);
        assertEq(token.totalSupply(), amount);
    }
}
