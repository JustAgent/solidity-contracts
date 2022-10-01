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
    uint256 public currentDomainRegisterPrice = 3000; //Change

    modifier onlyDomainOwner(string memory _domainName) {
        bytes32 domain = keccak256(abi.encodePacked(_domainName));
        require(msg.sender == domainOwners[domain], "You are not the domain owner");
        _;
    }

    function registerDomain(string memory _domainName) 
        public 
        payable 
        returns(bool) 
    {
        calculateCurrentDomainRegisterPrice(); //To do
        require(msg.value >= currentDomainRegisterPrice, "Not enough funds sent");

        bytes32 domainName = keccak256(abi.encodePacked(_domainName));
        require(!isDomainExists(domainName));

        _setDomainOwner(domainName, msg.sender);
        domainsList.push(domainName);
        totalDomains += 1;

        if (msg.value > currentDomainRegisterPrice) {
            Address.sendValue(payable(msg.sender), msg.value - currentDomainRegisterPrice);
        }
        return true;
    }

    function subscribe(string memory _domainName) public {
        bytes32 domainName = keccak256(abi.encodePacked(_domainName));
        require(!userSubscriptions[msg.sender][domainName], "You are already subscribed");
        userSubscriptions[msg.sender][domainName] = true;
    }

    function _subscribeExpired() private { //TO DO
        bytes32 domainName = keccak256(abi.encodePacked(_domainName));
        userSubscriptions[msg.sender][domainName] = false;
    }

    function _setDomainOwner(bytes32 domainName, address _owner) private {
        require(_owner != address(0), "Zero address");
        require(domainOwners[domainName] != _owner, "You are already the owner");

        domainOwners[domainName] = _owner;
    }

    function cancelSubscription(string memory _domainName) public {
        bytes32 domainName = keccak256(abi.encodePacked(_domainName));
        require(userSubscriptions[msg.sender][domainName]);


    }

    function transferDomainOwnership(string memory _domainName, address _newOwner) 
        public 
        onlyDomainOwner(_domainName) 
    {
        require(msg.sender != _newOwner, "Can not transfer to yourself");
        bytes32 domainName = keccak256(abi.encodePacked(_domainName));
        _setDomainOwner(domainName, _newOwner);
    }

    function calculateCurrentDomainRegisterPrice() private returns(bool) {
        //create a formula
        return true;
    }

    function isDomainExists(bytes32 _domain) private view returns(bool) {
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