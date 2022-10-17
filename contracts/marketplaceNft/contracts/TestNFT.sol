// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./NFT.sol";
contract NFT_TEST1 is NFT {
    constructor() NFT("TEST-1", "TEST-1") {
  }
}

contract NFT_TEST2 is NFT {
    constructor() NFT("TEST-2", "TEST-2") {
  }

  function miint(address to, uint amount) public {
      mint(to, amount);
    }
}

contract NFT_TEST3 is NFT {
    constructor() NFT("TEST-3", "TEST-3") {
  }
}