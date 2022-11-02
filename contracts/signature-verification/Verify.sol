// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/* Signature Verification

How to Sign and Verify
# Signing
1. Create message to sign
2. Hash the message
3. Sign the hash (off chain, keep your private key secret)

# Verify
1. Recreate hash from the original message
2. Recover signer from signature and hash
3. Compare recovered signer to claimed signer
*/

contract Sign { 
    // 0x016e07024f9021b94ed64d2f4268a3be3337cb09aedba0c45430d066084f51c52764bff3795ae2beb8bd18295debffc757e70fa370899a51e012f4c4d87db54b1c
    function getMessageHash(string memory _message) public pure returns(bytes32 ) {
        bytes32 message = keccak256(abi.encodePacked(_message));
        return message;
    }
    
    function getEthSignedMessage(bytes32 _messageHash) public pure returns(bytes32) {
        return keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash)
        );
    }

    function verify(address _signer, string memory _message, bytes memory _signature) public pure returns(bool) {
        bytes32 messageHash = getMessageHash(_message);
        bytes32 signedMessage = getEthSignedMessage(messageHash);

        return recoverSigner(signedMessage, _signature) == _signer;
    }

    function recoverSigner(bytes32 signedMessage, bytes memory _signature) public pure returns(address){

        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        return ecrecover(signedMessage, v,r,s);
    }

    function splitSignature(bytes memory _signature) public pure returns(bytes32 r, bytes32 s, uint8 v) {
        assembly {
            r := mload(add(_signature, 32))
            s := mload(add(_signature, 64))
            v := byte(0, mload(add(_signature, 96)))        
        }
    }
}