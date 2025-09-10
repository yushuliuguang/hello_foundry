// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

import "@openzeppelin/contracts/utils/Strings.sol";

contract SimpleMultisigWallet {

    address[] public admins;
    mapping(address=>bool) public isAdmin;
    uint8 threshold=2;
    mapping(uint256=>Proposal) public proposalMap;
    uint256 public ids;//proposalId

    //remix测试数据 【0x5B38Da6a701c568545dCfcB03FcB875f56beddC4,0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2,0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db],2
    constructor(address[] memory _admins,uint8 _threshold){
        threshold=_threshold;
        admins=_admins;
        for(uint i=0;i<_admins.length;i++){
           isAdmin[_admins[i]]=true; 
        }
    }
    receive() external payable {
    }

    struct Proposal{
        address to;
        uint256 value;
        bytes data;
        bool executed;//true 已执行
        uint8 confirmedNum;
        mapping(address=>bool) confirms;

    }

    //remix测试数据 0xf8e81D47203A594245E36C48e151709F0C19fBe8,1000000000000000000,0xd0e30db0
    function createProposal(address to,uint256 value,bytes memory data) public {
        _judgeAdmin();
        uint256 proposalId = ids++;
        Proposal storage proposal=proposalMap[proposalId];
        proposal.to = to;
        proposal.value = value;
        proposal.data = data;
        proposal.confirmedNum = 1;
        proposal.confirms[msg.sender]=true;

    }

    function confirmProposal(uint256 id) public {
        _judgeAdmin();
        require(id<ids,"proposalId doesn't exist");
        Proposal storage currenProposal = proposalMap[id];
        require(!currenProposal.executed,"porposal has been executed");
        require(currenProposal.confirms[msg.sender]==false,string.concat("current administrator ",Strings.toHexString(msg.sender)," has already confirmed this proposal(id:",Strings.toString(id),")"));
        currenProposal.confirms[msg.sender]=true;
        currenProposal.confirmedNum++;

    }

    function executeProposal(uint256 id) public {
        _judgeAdmin();
        require(id<ids,"proposalId doesn't exist");
        Proposal storage currenProposal = proposalMap[id];
        require(!currenProposal.executed,"porposal has been executed");
        require(currenProposal.confirmedNum >=threshold,
            string.concat(Strings.toString(currenProposal.confirmedNum)," of ",Strings.toString(admins.length)," administrators have confirmed, but ",Strings.toString(threshold)," needed"));
        //执行
        (bool success,)=currenProposal.to.call{value:currenProposal.value}(currenProposal.data);
        require(success,"execute failed");
        currenProposal.executed=true;

    }


    function _judgeAdmin() internal view {
        require(isAdmin[msg.sender],"the sender is not administrator");
    }
}