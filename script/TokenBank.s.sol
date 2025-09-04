// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

//import {Script} from "forge-std/Script.sol";
import {BaseScript} from "./BaseScript.sol";
import {TokenBank,ERC20} from "../src/day5_TokenBank.sol";
import {TokenERC20} from "../src/day5_TokenERC20.sol";


contract TokenBankScript is BaseScript {

    TokenBank public tokenBank;
    TokenERC20 public tokenContract;


    // 用于 create2 部署的盐值
    bytes32 public constant SALT = keccak256("TokenERC20_Deployment_v1");
    bytes32 public constant BANK_SALT = keccak256("TokenBank_Deployment_v1");

    function run() public broadcaster {
        //create2部署
        //anvil网络的默认create2 deployer部署者是0x4e59b44847b379578588920ca78fbf26c0b4956c而不是广播者
        tokenContract= new TokenERC20{salt:SALT}(deployer,10000);
        tokenBank = new TokenBank{salt:BANK_SALT}(address(tokenContract));
        //create部署
        //tokenContract= new TokenERC20(10000);
        //tokenBank = new TokenBank(address(tokenContract));
        require(isContract(address(tokenBank)),"is not contract");

        ERC20 t = tokenBank.token();
        saveContract("TokenBank", address(tokenBank));
        saveContract("TokenERC20", address(tokenContract));
        saveContract("t-TokenBank", address(t));
        // if (isAnvilNetwork()) {
        // } else {
        // }
        
    }

}