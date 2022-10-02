// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface WETH is IERC20{
    function mint(address _address) external; //For testing
}

// Using native token (ETH) to create domain
// To subscribe using WETH
contract Subscribe is Ownable, ReentrancyGuard{
    using SafeMath for uint256;

    struct UserSubscriptionData {
        bool isActive;
        uint expirationTime;
    }
    struct Subscription {
        uint duration;
        uint256 cost;
    }
   
    mapping(bytes32 => address) private domainOwners;
    mapping(bytes32 => Subscription) private subscriptionData;
    mapping(address => mapping(bytes32 => UserSubscriptionData)) private userSubscriptions;
    bytes32[] private domainsList;
    uint256 public fee = 5; // 5%
    uint256 public totalDomains;
    uint256 public constant baseDomainRegisterPrice = 5 * 10**16; //0.05 ETH`
    uint256 public currentDomainRegisterPrice = 5 * 10**16; 
    WETH weth;
    address public checkSender;
    modifier onlyDomainOwner(bytes32 _domainName) {
        require(msg.sender == domainOwners[_domainName], "You are not the domain owner");
        _;
    }

    event newSub(bytes32 indexed _domainName, address indexed _user);
    event newDomain(bytes32 indexed _domainName, address indexed _owner, uint durationDays);
    event cancelSub(bytes32 indexed _domainName, address indexed _user);
    constructor(address tokenAddress) {
        weth = WETH(tokenAddress);
    }

    function registerDomain(bytes32 _domainName, uint256 _cost, uint _durationDays) 
        public 
        payable 
        returns(bool) 
    {
        calculateCurrentDomainRegisterPrice(); 
        require(msg.value >= currentDomainRegisterPrice, "Not enough funds sent");
        require(!isDomainExists(_domainName), "You can not take this domain");

        _setDomainOwner(_domainName, msg.sender);
        domainsList.push(_domainName);
        totalDomains += 1;
        subscriptionData[_domainName].cost = _cost;
        subscriptionData[_domainName].duration = _durationDays;

        if (msg.value > currentDomainRegisterPrice) {
            Address.sendValue(payable(msg.sender), msg.value - currentDomainRegisterPrice);
        }
        emit newDomain(_domainName, msg.sender, _durationDays);
        return true;
    }
    
    function subscribe(bytes32 _domainName) public nonReentrant {
        require(!userSubscriptions[msg.sender][_domainName].isActive, "You are already subscribed");
        _subscribe(msg.sender, _domainName);
        emit newSub(_domainName, msg.sender);
    }

    function _subscribe(address _user, bytes32 _domainName) private {
        uint256 amount = subscriptionData[_domainName].cost;
        require(weth.balanceOf(_user) >= amount, "You don't have enough funds");
        //Getting payment
        weth.transferFrom(_user, address(this), amount);
        
        //Transfer weth to owner except fee
        weth.transfer(payable(domainOwners[_domainName]), amount.mul(100 - fee).div(100));

        //Give sub    
        userSubscriptions[_user][_domainName]
        .expirationTime = block.timestamp + (subscriptionData[_domainName].duration * 1 days);
        userSubscriptions[_user][_domainName].isActive= true;
    }

    function renewSubscription(address _user, bytes32 _domainName) external onlyOwner{
        _subscribe(_user, _domainName);
    }

    function _subscribeRemainingTime(address _user, bytes32 _domainName) external view returns(uint) { 
        if (userSubscriptions[_user][_domainName].expirationTime <= block.timestamp) {
            return 0;
        }
        uint time = userSubscriptions[_user][_domainName].expirationTime - block.timestamp;
        return time;
    }

    function cancelSubscription(bytes32 _domainName) public {
        require(userSubscriptions[msg.sender][_domainName].isActive);
        userSubscriptions[msg.sender][_domainName].isActive = false;
        userSubscriptions[msg.sender][_domainName].expirationTime = 0;
        emit cancelSub(_domainName, msg.sender);
    }

    function _setDomainOwner(bytes32 _domainName, address _owner) private {
        require(_owner != address(0), "Zero address");
        require(domainOwners[_domainName] != _owner, "You are already the owner");

        domainOwners[_domainName] = _owner;
    }


    function transferDomainOwnership(bytes32 _domainName, address _newOwner) 
        public 
        onlyDomainOwner(_domainName) 
    {
        require(msg.sender != _newOwner, "Can not transfer to yourself");
        _setDomainOwner(_domainName, _newOwner);
    }

    function calculateCurrentDomainRegisterPrice() private { 
        currentDomainRegisterPrice = (baseDomainRegisterPrice.div(100) * (100 + totalDomains.div(10))); //1% up for every 10 domains
        
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
        weth.transferFrom(address(this), msg.sender, weth.balanceOf(msg.sender));
    }
    
}