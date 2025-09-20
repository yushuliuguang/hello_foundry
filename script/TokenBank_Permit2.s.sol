// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

//import {Script} from "forge-std/Script.sol";
import {BaseScript} from "./BaseScript.sol";
import {TokenBank_Permit2} from "../src/day12_TokenBank_Permit2.sol";


contract TokenBankScript is BaseScript {

    TokenBank_Permit2 public tokenBank;


    // 用于 create2 部署的盐值
    bytes32 public constant BANK_SALT = keccak256("TokenBank_Permit2_Deployment_v1");

    function run() public broadcaster {
        //create2部署
        //anvil网络的默认create2 deployer部署者是0x4e59b44847b379578588920ca78fbf26c0b4956c而不是广播者
        tokenBank = new TokenBank_Permit2{salt:BANK_SALT}(0x957C30AF876b074701DA973745Ec209A48aB4078);

        saveContract("TokenBank_Permit2", address(tokenBank));
    }

}