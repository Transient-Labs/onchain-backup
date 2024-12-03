// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "forge-std-1.9.4/Test.sol";
import {OnchainBackup, Ownable} from "src/OnchainBackup.sol";

contract OnchainBackupTest is Test {
    OnchainBackup public ocb;

    address public nftAddress = address(420);
    uint256 public tokenId = 69;

    function setUp() public {
        string[] memory assetMimeTypes = new string[](2);
        assetMimeTypes[0] = "image/jpeg";
        assetMimeTypes[1] = "video/mp4";
        OnchainBackup.Metadata memory metadata =
            OnchainBackup.Metadata({nftAddress: nftAddress, tokenId: tokenId, assetMimeTypes: assetMimeTypes});

        ocb = new OnchainBackup(address(this), metadata);
    }

    function test_initialization() public view {
        (OnchainBackup.Metadata memory md, string[] memory mimeTypes) = ocb.metadata();

        assertEq(md.nftAddress, nftAddress);
        assertEq(md.tokenId, tokenId);
        assertEq(keccak256(bytes(mimeTypes[0])), keccak256("image/jpeg"));
        assertEq(keccak256(bytes(mimeTypes[1])), keccak256("video/mp4"));
        assertEq(ocb.owner(), address(this));
    }

    function test_accessControl(address hacker, bytes memory data) public {
        vm.assume(hacker != address(this));
        vm.startPrank(hacker);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, hacker));
        ocb.addJSONData(data);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, hacker));
        ocb.addAssetData(0, data);
        vm.stopPrank();
    }

    function test_addJSONData(bytes memory data) public {
        // add data
        vm.expectEmit(true, true, true, true);
        emit OnchainBackup.JSONAdded(data);
        ocb.addJSONData(data);
    }

    function test_addAssetData(bytes memory data) public {
        // add data
        vm.expectEmit(true, true, true, true);
        emit OnchainBackup.AssetDataAdded(0, data);
        ocb.addAssetData(0, data);
    }

    function test_addData_multiple(bytes[] memory data1, bytes[] memory data2) public {
        // add data1
        for (uint256 i = 0; i < data1.length; ++i) {
            vm.expectEmit(true, true, true, true);
            emit OnchainBackup.AssetDataAdded(0, data1[i]);
            ocb.addAssetData(0, data1[i]);
        }

        // add data2
        for (uint256 i = 0; i < data2.length; ++i) {
            vm.expectEmit(true, true, true, true);
            emit OnchainBackup.AssetDataAdded(1, data2[i]);
            ocb.addAssetData(1, data2[i]);
        }
    }
}
