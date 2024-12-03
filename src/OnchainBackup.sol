// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {Ownable} from "@openzeppelin-contracts-5.0.2/access/Ownable.sol";

/// @title OnchainBackup.sol
/// @notice Contract to store onchain data related to an nft on the same chain via event logs
/// @author transientlabs.xyz
contract OnchainBackup is Ownable {
    ////////////////////////////////////////////////////////////////
    /// TYPES
    ////////////////////////////////////////////////////////////////

    struct Metadata {
        address nftAddress;
        uint256 tokenId;
        string[] assetMimeTypes;
    }

    ////////////////////////////////////////////////////////////////
    /// STORAGE
    ////////////////////////////////////////////////////////////////

    Metadata private _metadata;

    ////////////////////////////////////////////////////////////////
    /// EVENTS
    ////////////////////////////////////////////////////////////////

    /// @notice Event emitted containing the json metadata for the NFT
    /// @dev The mime type is always `application/json`
    event JSONAdded(bytes data);

    /// @notice Event emitted for a particular asset added to this contract, specified by the `Metadata.assetMimeType` index
    event AssetDataAdded(uint256 indexed assetIndex, bytes data);

    ////////////////////////////////////////////////////////////////
    /// CONSTRUCTOR
    ////////////////////////////////////////////////////////////////

    constructor(address initOwner, Metadata memory metadata_) Ownable(initOwner) {
        _metadata = metadata_;
    }

    ////////////////////////////////////////////////////////////////
    /// WRITE FUNCTIONS
    ////////////////////////////////////////////////////////////////

    /// @notice Function to add onchain JSON data that comprises the json metadata returned from `tokenURI`
    /// @dev Data must be chunked within calldata limits
    /// @dev Only callable by the contract owner
    /// @param data The data to add
    function addJSONData(bytes memory data) external onlyOwner {
        emit JSONAdded(data);
    }

    /// @notice Function to add onchain asset data
    /// @dev Data must be chunked within calldata limits
    /// @dev Only callable by the contract owner
    /// @param index The index of the asset in the `metadata.assetMimeType` array
    /// @param data The data to add
    function addAssetData(uint256 index, bytes memory data) external onlyOwner {
        emit AssetDataAdded(index, data);
    }

    ////////////////////////////////////////////////////////////////
    /// VIEW FUNCTIONS
    ////////////////////////////////////////////////////////////////

    /// @notice Function to get the metadata
    function metadata() external view returns (Metadata memory, string[] memory) {
        return (_metadata, _metadata.assetMimeTypes);
    }
}
