// SPDX-License-Identifier: None
pragma solidity ^0.8.4;

import './BridgeBase.sol';

contract BridgeEth is BridgeBase {
  constructor(address token) BridgeBase(token) {}
}