// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

//import {Script} from "forge-std/Script.sol";
import {BaseScript} from "./BaseScript.sol";
import {Bank} from "../src/day3_Bank.sol";

contract BankScript is BaseScript {

    Bank public bank;

    // 用于 create2 部署的盐值
    bytes32 public constant SALT = keccak256("Bank_Deployment_v1");

    function run() public broadcaster {

        //create2部署
        //anvil网络的默认create2 deployer部署者是0x4e59b44847b379578588920ca78fbf26c0b4956c而不是广播者
        bank= new Bank{salt:SALT}();
        saveContract("Bank", address(bank));


        
    }
}