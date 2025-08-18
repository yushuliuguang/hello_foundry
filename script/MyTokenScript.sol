// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

//import {Script} from "forge-std/Script.sol";
import {BaseScript} from "./BaseScript.sol";
import {MyToken} from "../src/Mytoken.sol";

contract MyTokenScript is BaseScript {
    MyToken public myToken;


    function run() public broadcaster {

        myToken = new MyToken("MyToken", "MTK");
        saveContract("MyToken", address(myToken));
    }
}