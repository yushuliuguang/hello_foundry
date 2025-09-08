// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

//import {Script} from "forge-std/Script.sol";
import {BaseScript} from "./BaseScript.sol";
import {TokenERC721} from "../src/day6_TokenERC721.sol";

contract NFTMarketScript is BaseScript {

    TokenERC721 public nft;

    // 用于 create2 部署的盐值
    bytes32 public constant NFT_SALT = keccak256("TokenERC721_Deployment_v3");

    function run() public broadcaster {
        //create2部署
        //anvil网络的默认create2 deployer部署者是0x4e59b44847b379578588920ca78fbf26c0b4956c而不是广播者
        nft= new TokenERC721{salt:NFT_SALT}("myNFT","nft","ipfs://");
        saveContract("TokenERC721", address(nft));

        
    }


}