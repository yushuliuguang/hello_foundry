// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

import "./day6_NFTMarket.sol";
import {Nonces} from "@openzeppelin/contracts/utils/Nonces.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

contract NFTMarket_Permit is EIP712,Nonces,NFTMarket {
   
    address public admin;
    bytes32 private constant PERMIT_TYPEHASH = keccak256("PermitBuy(address consumer,uint256 nonce)");

    constructor(string memory name,address erc20,address _admin) EIP712(name,"1") NFTMarket(erc20) {
        admin=_admin;
    }

    struct PermitBuy{
        address consumer;
        uint256 nonce;
    }
    
    function permitBuy( bytes memory signature,PermitBuy memory data,uint256 id) public {
        require(msg.sender==data.consumer , "sender is not consumer");
        bytes32 structHash = keccak256(abi.encode(PERMIT_TYPEHASH, data.consumer, _useNonce(data.consumer))); // 组装并哈希 EIP-712 结构体，包含并消耗 nonce
        bytes32 hash = _hashTypedDataV4(structHash); // 计算带域分隔符的 EIP-712 最终消息哈希
        address signer = ECDSA.recover(hash, signature);
        require(signer==admin,"invalid signer");
        _buyNft(id);
    }
}