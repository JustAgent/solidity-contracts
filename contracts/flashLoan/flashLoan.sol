// SPDX-License-Identifier: None
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";


contract FlashLoan is ERC20, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    
    uint256 baseFee = 9;
    mapping(address => uint256) public debts;

    constructor() ERC20('Flash Token', 'FT') {
        _mint(address(this), 100000);
    }

    function mint(address _address) external onlyOwner {
        _mint(_address, 100000);
    }
    
    function flashLoan(address _receiver, uint256 _amount) 
    public 
    nonReentrant
    {
        require(_amount > 0, "Amount can not be equal to 0");
        require(balanceOf(address(this)) >= _amount, 'Not enough funds');
        uint256 availableLiquidityBefore = balanceOf(address(this));

        // Actual fee is 0.09%
        uint256 amountFee = _amount.mul(baseFee).div(10000);
        require(amountFee > 0, "The requested amount is too small for a flashLoan");

        _transferToUser(_receiver, _amount);
        debts[_receiver] = _amount + amountFee;
        uint256 availableLiquidityAfter = balanceOf(address(this));

        require(
            availableLiquidityAfter == availableLiquidityBefore.add(amountFee),
            "The actual balance of the contract is inconsistent"
        );
    }

    function _transferToUser(address _receiver, uint256 _amount) private {
        _transfer(address(this), _receiver, _amount);
    }


    function transferFundsBack(address borrower) public {
        require(debts[borrower] > 0, 'No debts');
        require(balanceOf(borrower) >= debts[borrower], 'Can not pay');
        transferFrom(borrower, address(this), debts[borrower]);
        debts[borrower] = 0;

    }
}

contract Borrower is Ownable {
    using SafeMath for uint256;

    FlashLoan flashLoaner;
    constructor(address _flashLoanerAddress) {
        flashLoaner = FlashLoan(_flashLoanerAddress);
    }
    
    function execute(uint256 _amount) public onlyOwner {
        flashLoaner.approve(address(this), _amount + _amount.mul(9).div(10000));
        flashLoaner.flashLoan(address(this), _amount); 
        //Do smth
        flashLoaner.transferFundsBack(address(this));
    }

}