// SPDX-License-Identifier: None
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Marketplace {
    

    function _transferNFT(address _to, address, uint256 tokenId, address _contractAddress ) private {
        IERC721 nft = IERC721(_contractAddress);
        nft.safeTransferFrom(msg.sender, _to, tokenId);
    }

    function checkApproval(address _user, address _contract) private view returns(bool) {
        IERC721 nft = IERC721(_contract);
        return nft.isApprovedForAll(_user, address(this));
    }

}