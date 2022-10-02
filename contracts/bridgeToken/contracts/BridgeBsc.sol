// SPDX-License-Identifier: None
pragma solidity ^0.8.4;

import './BridgeBase.sol';

contract BridgeBsc is BridgeBase {
  constructor(address token) BridgeBase(token) {}
}