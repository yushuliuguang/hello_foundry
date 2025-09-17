// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

//import {Script} from "forge-std/Script.sol";
import {BaseScript} from "./BaseScript.sol";
import {TokenERC20_Permit} from "../src/day12_TokenERC20_Permit.sol";

contract TokenERC20PermitScript is BaseScript {

    TokenERC20_Permit public tokenContract;

    // 用于 create2 部署的盐值
    bytes32 public constant TOKEN_SALT = keccak256("TokenERC20_Permit_Deployment_v1");

    function run() public broadcaster {

        //create2部署
        //anvil网络的默认create2 deployer部署者是0x4e59b44847b379578588920ca78fbf26c0b4956c而不是广播者
        tokenContract= new TokenERC20_Permit{salt:TOKEN_SALT}(deployer,10000);
        saveContract("TokenERC20_Permit", address(tokenContract));


        
    }
}