// SPDX-License-Identifier: None

pragma solidity ^0.8.4;

import './TokenBase.sol';

contract TokenBsc is TokenBase {
  constructor() TokenBase('BSC Token', 'BTK') {}
}