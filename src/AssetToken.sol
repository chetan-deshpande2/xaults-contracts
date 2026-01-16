// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {
    ERC20Upgradeable
} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {
    ERC20PermitUpgradeable
} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PermitUpgradeable.sol";
import {
    AccessControlUpgradeable
} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {
    UUPSUpgradeable
} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {
    Initializable
} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {IAssetToken} from "src/interfaces/IAssetToken.sol";

/**
 * @title AssetToken
 * @author Chetan
 * @notice ERC-20 token for Xaults tokenized financial assets.
 */
contract AssetToken is
    Initializable,
    ERC20Upgradeable,
    ERC20PermitUpgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable,
    IAssetToken
{
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    uint256 private _maxSupply;

    // Reserved storage slots for future V2/V3 variables.
    // Without this gap, adding new state vars would corrupt storage layout.
    uint256[49] private __gap; // Reduced by 1 for ERC20Permit storage

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Sets up the token. Called once when proxy is deployed.
     * @param name_ Token name (e.g., "Xaults Real Estate Fund I")
     * @param symbol_ Token symbol (e.g., "XREF1")
     * @param maxSupply_ Hard cap on total tokens that can ever exist
     * @param admin The address that will control minting and upgrades
     */
    function initialize(
        string memory name_,
        string memory symbol_,
        uint256 maxSupply_,
        address admin
    ) external initializer {
        __ERC20_init(name_, symbol_);
        __ERC20Permit_init(name_);
        __AccessControl_init();

        _maxSupply = maxSupply_;

        // Admin gets both roles initially. They can delegate MINTER_ROLE
        // to other addresses later if needed.
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(MINTER_ROLE, admin);
    }

    /// @inheritdoc IAssetToken
    function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) {
        uint256 available = _maxSupply - totalSupply();
        if (amount > available) {
            revert MaxSupplyExceeded(amount, available);
        }

        _mint(to, amount);
        emit TokensMinted(to, amount);
    }

    /// @inheritdoc IAssetToken
    function maxSupply() external view returns (uint256) {
        return _maxSupply;
    }

    // Only admin can upgrade. This is critical for UUPS - without this check,
    // anyone could replace the implementation and take over the contract.
    function _authorizeUpgrade(
        address
    ) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}
}
