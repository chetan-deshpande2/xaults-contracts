// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IAssetToken
 * @notice Interface for Xaults tokenized asset contracts
 */
interface IAssetToken {
    /// @notice Emitted when new tokens are minted
    event TokensMinted(address indexed to, uint256 amount);

    /// @notice Thrown when minting would exceed the supply cap
    error MaxSupplyExceeded(uint256 requested, uint256 available);

    /// @notice Returns the maximum token supply
    function maxSupply() external view returns (uint256);

    /// @notice Mints tokens to an address. Caller must have MINTER_ROLE.
    function mint(address to, uint256 amount) external;

    /// @notice The role identifier for addresses allowed to mint
    function MINTER_ROLE() external view returns (bytes32);
}
