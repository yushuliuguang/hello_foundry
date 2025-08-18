// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

import "forge-std/console.sol";

interface IBank {
    function getBalance(address addr) external view returns (uint256);
    function deposit() external payable;
    function withdraw(uint256 amount) external;
}

contract Bank is IBank{
    mapping(address=>uint256) public records;
    address[3] public top3;
    address public admin;

    //设置管理员
    constructor() payable {
        admin = msg.sender;
    }

    receive() external payable virtual{
        valueIn();
    }
    function deposit() public payable virtual {
        valueIn();
    }
    function valueIn() internal{
        address addr = msg.sender;
        uint256 amount = records[addr] ;
        amount += msg.value;
        records[addr]=amount;

        //更新top3
        // if (amount <= records[top3[2]] && top3[2] != addr) return;
        // if (amount <= records[top3[1]] && top3[1] != addr) {
        //     top3[2] = addr;
        //     return;
        // }
        // if (amount <= records[top3[0]] && top3[0] != addr) {
        //     top3[2] = top3[1];
        //     top3[1] = addr;
        //     return;
        // }
        // top3[2] = top3[1];
        // top3[1] = top3[0];
        // top3[0] = addr;
        for (uint8 i = 0; i < 3; i++) {
            address currentAddr = top3[i];
            if(currentAddr==addr){
                break;
            }
            if (currentAddr == address(0) || amount > records[currentAddr] ) {
                address[] memory temp=new address[](3-i);
                for (uint8 j = i; j <=2; j++) {
                        temp[j-i]=top3[j];
                }
                for(uint j=0;j<(2-i);j++){
                    if(temp[j]==addr){
                        break;
                    }else{
                        top3[i+j+1]=temp[j];
                    }
                }
                top3[i] = addr;
                break;
            }
        }
    }
    function getBalance(address addr) public view returns (uint256){
        return records[addr];
    }
    function withdraw(uint256 amount) external {
        require(msg.sender == admin, "only administrator can withdraw");
        require(address(this).balance >= amount, "Balance not sufficient");
       // payable(msg.sender).transfer(amount);
       (bool suc,)=msg.sender.call{value:amount}(new bytes(0));
       require(suc,"transfer failed");
    }
}