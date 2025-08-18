
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

abstract contract BaseScript is Script {
    address internal deployer;
    address internal user;
    string internal mnemonic;

    function setUp() public virtual {
        mnemonic = vm.envString("MNEMONIC");
        (deployer, ) = deriveRememberKey(mnemonic, 0);
        console.log("deployer: %s", deployer);

        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        user = vm.addr(deployerPrivateKey);
        console.log("user: %s", user);
    }


    function saveContract(string memory name, address addr) public {
        string memory chainId = vm.toString(block.chainid);
        
        string memory json1 = "key";
        string memory finalJson =  vm.serializeAddress(json1, "address", addr);
        string memory dirPath = string.concat(string.concat("deployments/", name), "_");
        vm.writeJson(finalJson, string.concat(dirPath, string.concat(chainId, ".json"))); 
    }

    modifier broadcaster() {
        //sender:本地网络使用user（anvil生成的私钥），远程网络使用deployer（助记词）
        // vm.startBroadcast(deployer);
        vm.startBroadcast(deployer);
        _;
        vm.stopBroadcast();
    }
}
