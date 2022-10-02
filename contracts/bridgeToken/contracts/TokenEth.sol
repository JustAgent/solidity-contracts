// SPDX-License-Identifier: None

pragma solidity ^0.8.4;

import './TokenBase.sol';

contract TokenEth is TokenBase {
  constructor() TokenBase('ETH Token', 'ETK') {}
}