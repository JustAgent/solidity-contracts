// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/Test.sol";
// import {Utils} from './utils/Utils.sol';
contract NftTest is Test {
    NFT public nft;
    address  alice = address(0x1);
    address  bob  = address(0x2);
    address owner;
    function setUp() public {
            nft = new NFT();
            owner = nft.owner();
            // utils = new Utils();
     }

    function testBalanceOf() public {
        nft.mint(msg.sender, 4);
        assertEq(nft.balanceOf(msg.sender), 4);

    }

    function testOwner() public {
        assertEq(owner, nft.owner());
        
    }

}