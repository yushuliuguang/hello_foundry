// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

contract TokenERC20{

    //public变量自动生成view方法
    string public name;
    string public symbol;
    uint8 public decimals;

    mapping(address=>uint256) public balanceOf;
    mapping(address=>mapping(address=>uint256)) public allowance;

    uint256 totalSupply;

    constructor(address to, uint256 _initialSupply) {
        name="MyTokenERC20";
        symbol="MTE20";
        decimals=18;
        totalSupply=_initialSupply*10**decimals;
        balanceOf[to]=totalSupply;
    }

    function transfer(address _to, uint256 _value) public returns (bool success){
        require(balanceOf[msg.sender]>=_value,"balance of token insufficent");
        balanceOf[msg.sender]-=_value;
        balanceOf[_to]+=_value;
        emit Transfer(msg.sender,_to,_value);
        return true;
    }
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){
        require(balanceOf[_from]>=_value,"balance of token insufficent");
        require(allowance[_from][msg.sender] >= _value,"allowance insufficent");
        balanceOf[_from]-=_value;
        balanceOf[_to]+=_value;
        allowance[_from][msg.sender]-=_value;
        emit Transfer(_from,_to,_value);
        return true;
    }
    function approve(address _spender, uint256 _value) public returns (bool success){
        allowance[msg.sender][_spender]=_value;
        emit Approval(msg.sender,_spender,_value);
        return true;
    }


    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}