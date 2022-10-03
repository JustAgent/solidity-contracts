// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFT is ERC721Enumerable, Ownable {
  using Strings for uint256;

  string public baseURI;
  string public baseExtension = ".json";
  uint256 public cost = 0.001 ether;
  uint256 public maxSupply = 10;
  uint256 public maxMintAmount = 10;
  bool public publicSaleActive = false;
  mapping(address => bool) public whitelisted;

  constructor() ERC721("TestERC721", "T721") {
    setBaseURI("https://bafybeiaon7sl66cygvkownw6ddyhufz23ihwssmc74mvzexkvgdwfrjtry.ipfs.w3s.link/");
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function mint(address _to, uint256 _mintAmount) public payable {
    uint256 supply = totalSupply();
    require(publicSaleActive);
    require(_mintAmount > 0);
    require(_mintAmount <= maxMintAmount);
    require(supply + _mintAmount <= maxSupply);

    uint256 mintCost = cost * _mintAmount;
    if (msg.sender != owner()) {
        if(whitelisted[msg.sender] != true) {
          require(msg.value >= mintCost);
        }
    }
    
    for (uint256 i = 1; i <= _mintAmount; i++) {
      _safeMint(_to, supply + i);
    }

    if (msg.value > mintCost) {
       (bool os, ) = payable(msg.sender).call{value: msg.value - mintCost}("");
       require(os);
    }

  }

  

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }

  function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
  }

  function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
    maxMintAmount = _newmaxMintAmount;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }

  function pause() public onlyOwner {
    require(publicSaleActive, "Already paused");
    publicSaleActive = false;
  }
  function start() public onlyOwner {
    require(!publicSaleActive, "Already active");
    publicSaleActive = true;
  }
 
  function whitelistUser(address _user) public onlyOwner {
    whitelisted[_user] = true;
  }
 
  function removeWhitelistUser(address _user) public onlyOwner {
    whitelisted[_user] = false;
  }

  function withdraw() public payable onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }
}