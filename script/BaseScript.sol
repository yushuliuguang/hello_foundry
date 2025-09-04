
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

abstract contract BaseScript is Script {
    address internal deployer;
    address internal user;
    string internal mnemonic;

    function setUp() public virtual {
        //sender:本地网络使用PRIVATE_KEY（anvil生成的私钥），远程网络使用MNEMONIC（助记词）
        if(isAnvilNetwork()){
            uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
            deployer = vm.addr(deployerPrivateKey);
            console.log("user: %s", deployer);
        }else{
            mnemonic = vm.envString("MNEMONIC");
            (deployer, ) = deriveRememberKey(mnemonic, 0);
            console.log("deployer: %s", deployer);
        }

        
    }


    function saveContract(string memory name, address addr) public {
        string memory chainId = vm.toString(block.chainid);
        
        string memory json1 = "key";
        string memory finalJson =  vm.serializeAddress(json1, "address", addr);
        string memory dirPath = string.concat(string.concat("deployments/", name), "_");
        vm.writeJson(finalJson, string.concat(dirPath, string.concat(chainId, ".json"))); 
    }

    modifier broadcaster() {
        vm.startBroadcast(deployer);
        _;
        vm.stopBroadcast();
    }
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function isAnvilNetwork() internal view returns (bool) {
        // anvil 默认 chainid 为 31337
        return block.chainid == 31337;
    }
}
