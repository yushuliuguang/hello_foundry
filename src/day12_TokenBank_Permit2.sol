// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

import "./day5_TokenBank.sol";
import {Nonces} from "@openzeppelin/contracts/utils/Nonces.sol";
import "./day5_TokenERC20.sol";

// Permit2 相关结构体定义
struct TokenPermissions {
    address token;
    uint256 amount;
}
struct PermitTransferFrom {
    TokenPermissions permitted;
    uint256 nonce;
    uint256 deadline;
}
struct SignatureTransferDetails {
    address to;
    uint256 requestedAmount;
}

// Permit2 接口
interface IPermit2 {
    function permitTransferFrom(
        PermitTransferFrom memory permit,
        SignatureTransferDetails calldata transferDetails,
        address owner,
        bytes calldata signature
    ) external;
}

contract TokenBank_Permit2 is TokenBank{

    // Permit2合约地址 
    address public constant PERMIT2_ADDRESS = 0x000000000022D473030F116dDEE9F6B43aC78BA3;
    
    IPermit2 public immutable permit2;
    
    constructor(address _tokenContract) TokenBank(_tokenContract) {
        permit2 = IPermit2(PERMIT2_ADDRESS);
    }

    function depositWithPermit2(
        PermitTransferFrom calldata permit,
        uint256 amount,
        bytes calldata signature
    ) public {

        // 验证代币地址必须匹配
        require(permit.permitted.token == address(token), "token mismatch");
        //校验token余额
        require(amount>0,"Amount must be greater than 0");
        require(token.balanceOf(msg.sender)>=amount,"balance of token insufficent");
        // 验证签名未过期
        require(block.timestamp <= permit.deadline, "signature expired");
        // 创建转移详情
        SignatureTransferDetails memory transferDetails = SignatureTransferDetails({
            to: address(this),
            requestedAmount: amount
        });
        
        // 使用 Permit2 的 permitTransferFrom 函数，从用户账户转移代币到当前合约
        permit2.permitTransferFrom(permit, transferDetails, msg.sender, signature);
        records[msg.sender]+=amount;
    }


    
} 
// contract TokenERC20_Permit is ERC20Permit{
//     constructor(address to, uint256 initialSupply) ERC20Permit("MyTokenERC20Permit2") ERC20("MyTokenERC20Permit2","MTE20P2"){
//         _update(address(0), to, (initialSupply*10**decimals()));
//     }
//     function safeTransferFrom(address from, address to, requestedAmount) public {
//         transferFrom(from,to,requestedAmount);
//     }
// }