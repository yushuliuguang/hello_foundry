// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

import "./day5_TokenBank.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";

contract TokenBank_Permit is TokenBank{

    constructor(address _tokenContract) TokenBank(_tokenContract) {}

    struct Permit {
        address owner;
        address spender;
        uint256 value;
        uint256 nonce;
        uint256 deadline;
    }
    function permitDeposit(Permit memory permit,bytes memory signatrue) public {
        // 调用TokenERC20_Permit的permit方法
        require(permit.spender == address(this), "spender must be bank");
        require(signatrue.length == 65, "invalid signature length");

        bytes32 r;
        bytes32 s;
        uint8 v;
        // signature 格式: r(32) | s(32) | v(1)
        assembly {
            r := mload(add(signatrue, 32))
            s := mload(add(signatrue, 64))
            v := byte(0, mload(add(signatrue, 96)))
        }

        IERC20Permit(address(token)).permit(
            permit.owner,
            permit.spender,
            permit.value,
            permit.deadline,
            v,
            r,
            s
        );

        // 调用TokenBank的deposit方法
        _deposit(permit.value);
    }
} 