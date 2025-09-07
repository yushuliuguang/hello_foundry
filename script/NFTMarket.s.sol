// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

//import {Script} from "forge-std/Script.sol";
import {BaseScript} from "./BaseScript.sol";
import {NFTMarket,IERC20,IERC721} from "../src/day6_NFTMarket.sol";
import {TokenERC20} from "../src/day5_TokenERC20.sol";
import {TokenERC721} from "../src/day6_TokenERC721.sol";

contract NFTMarketScript is BaseScript {

    NFTMarket public market;
    TokenERC20 public tokenContract;
    TokenERC721 public nft;


    // 用于 create2 部署的盐值
    bytes32 public constant MARKET_SALT = keccak256("NFTMarket_Deployment_v1");
    bytes32 public constant TOKEN_SALT = keccak256("TokenERC20_Deployment_v1");
    bytes32 public constant NFT_SALT = keccak256("TokenERC721_Deployment_v1");

    function run() public broadcaster {
        //create2部署
        //anvil网络的默认create2 deployer部署者是0x4e59b44847b379578588920ca78fbf26c0b4956c而不是广播者
        tokenContract= new TokenERC20{salt:TOKEN_SALT}(deployer,10000);
        market = new NFTMarket{salt:MARKET_SALT}(address(tokenContract));
        nft= new TokenERC721{salt:NFT_SALT}("myNFT","nft","ipfs://");
        require(isContract(address(market)),"is not contract");

        saveContract("NFTMarket", address(market));
        saveContract("TokenERC20", address(tokenContract));
        saveContract("TokenERC721", address(nft));

        
    }


}