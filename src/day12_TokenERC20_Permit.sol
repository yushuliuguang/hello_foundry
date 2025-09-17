// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;

import "./day5_TokenERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract TokenERC20_Permit is ERC20Permit{

    constructor(address to, uint256 initialSupply) ERC20Permit("MyTokenERC20Permit") ERC20("MyTokenERC20Permit","MTE20P"){
        _update(address(0), to, (initialSupply*10**decimals()));
    }

}