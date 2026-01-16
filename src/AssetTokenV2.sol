// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {
    PausableUpgradeable
} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import {AssetToken} from "src/AssetToken.sol";

/**
 * @title AssetTokenV2
 * @author Chetan
 * @notice Upgraded version of AssetToken 

 */
contract AssetTokenV2 is AssetToken, PausableUpgradeable {
    // V1 had __gap[49], so V2 needs fewer slots to account for PausableUpgradeable
    uint256[48] private __gap;

    /// @notice Pauses all token transfers. Only callable by admin.
    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    /// @notice Resumes token transfers. Only callable by admin.
    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    // Block transfers when paused. This hooks into all transfer operations
    // including mint, burn, and regular transfers.
    function _update(
        address from,
        address to,
        uint256 value
    ) internal virtual override whenNotPaused {
        super._update(from, to, value);
    }
}
