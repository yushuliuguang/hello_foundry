// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

interface ERC20{
    function balanceOf(address _owner) external view returns (uint256);
    function transfer(address _to, uint256 _value) external  returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external  returns (bool success);
    function approve(address _spender, uint256 _value) external  returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);
}
contract TokenBank{
    mapping(address=>uint256) public records;
    ERC20 public token;

    constructor(address _tokenContract){
        token=ERC20(_tokenContract);
    }

    function deposit(uint256 amount) external{
        require(amount>0,"Amount must be greater than 0");
        require(token.balanceOf(msg.sender)>=amount,"balance of token insufficent");
        require(token.allowance(msg.sender,address(this))>=amount,"allowance insufficent");
        bool success = token.transferFrom(msg.sender,address(this),amount);
        require(success,"transfer from user to bank failed");
        records[msg.sender]+=amount;
    }
    function withdraw(uint256 amount) external{
        require(amount<=records[msg.sender],"Not enough balance");
        bool success = token.transfer(msg.sender,amount);
        require(success,"transfer from bank to user failed");
        records[msg.sender]-=amount;
    }

}