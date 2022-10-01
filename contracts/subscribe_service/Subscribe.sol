// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Subscribe is Ownable{
    using SafeMath for uint256;
    mapping(bytes32 => address) domainOwners;
    mapping(address => mapping(bytes32 => bool)) userSubscriptions;
    bytes32[] domainsList;
    uint256 public totalDomains;
    uint256 public currentDomainRegisterPrice = 3000;

    modifier onlyDomainOwner(string memory _domainName) {
        bytes32 domain = keccak256(abi.encodePacked(_domainName));
        require(msg.sender == domainOwners[domain], "You are not the domain owner");
        _;
    }

    function registerDomain(string memory _domainName) public payable returns(bool) {
        //require domain doesnt exist
        //pay for domain registration
        calculateCurrentDomainRegisterPrice();
        require(msg.value >= currentDomainRegisterPrice, "Not enough funds sent");
        
        bytes32 domainName = keccak256(abi.encodePacked(_domainName));
        _setDomainOwner(domainName, msg.sender);
        domainsList.push(domainName);
        totalDomains += 1;

        if (msg.value > currentDomainRegisterPrice) {
            Address.sendValue(payable(msg.sender), msg.value - currentDomainRegisterPrice);
        }
        return true;
    }

    function _setDomainOwner(bytes32 _domainName, address _owner) private {
        require(_owner != address(0), "Zero address");
        bytes32 domainName = keccak256(_domainName);
        require(domainOwners[domainName] != _owner, "You are already the owner");

        domainOwners[domainName] = _owner;
    }

    function calculateCurrentDomainRegisterPrice() private returns(bool) {
        //create a formula
        return true;
    }

    function isDomainExist(bytes32 _domain) private returns(bool) {
        for (uint i = 0; i < totalDomains; i++) {
            if (domainsList[i] == _domain) {
                return true;
            }
        }
        return false;
    } 

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(owner()), balance);
    }
}