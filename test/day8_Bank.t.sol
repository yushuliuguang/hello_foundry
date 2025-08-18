// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/day3_Bank.sol";

contract BankTest is Test {
    Bank public bank;
    Bank public bankUser1;
    address public admin;
    address public user1;
    address public user2;
    address public user3;
    address public user4;

    function setUp() public {
        bank = new Bank();
        user1=0x94658EC7EF791214E423F484C6374f2B96ff50eE;
        user2=0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
        user3=0x70997970C51812dc3A010C7d01b50e0d17dc79C8;
        user4=0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC;
        vm.prank(user1);
        bankUser1=new Bank();
    }
    // 1. 断言检查存款前后用户在 Bank 合约中的存款额更新是否正确。
    function test_deposit() public {
        vm.deal(user1, 100 ether);
        vm.deal(user2, 100 ether);
        vm.prank(user1);
        bank.deposit{value: 10*10**18 }();
        assertEq(bank.getBalance(user1), 10 ether);
        assertEq(user1.balance, 90 ether);
        assertEq(address(bank).balance, 10 ether);
        vm.prank(user2);
        bank.deposit{value: 20*10**18 }();
        assertEq(bank.getBalance(user2), 20 ether);
        assertEq(user2.balance, 80 ether);
        assertEq(address(bank).balance, 30 ether);
        vm.prank(user1);
        bank.deposit{value: 10*10**18 }();
        assertEq(bank.getBalance(user1), 20 ether);
        assertEq(user1.balance, 80 ether);
        assertEq(address(bank).balance, 40 ether);

    }

    // 2. 检查存款金额的前 3 名用户是否正确，分别检查有1个、2个、3个、4 个用户， 以及同一个用户多次存款的情况。
    function test_sort() public{
        vm.deal(user1, 100 ether);
        vm.deal(user2, 100 ether);
        vm.deal(user3, 100 ether);
        vm.deal(user4, 100 ether);
        vm.prank(user1);
        bank.deposit{value: 1*10**18 }();
        assertEq(bank.top3(0), user1);
        assertEq(bank.top3(1), address(0));
        assertEq(bank.top3(2), address(0));
        vm.prank(user2);
        bank.deposit{value: 2*10**18 }();
        assertEq(bank.top3(0), user2);
        assertEq(bank.top3(1), user1);
        assertEq(bank.top3(2), address(0));
        vm.prank(user3);
        bank.deposit{value: 4*10**18 }();
        assertEq(bank.top3(0), user3);
        assertEq(bank.top3(1), user2);
        assertEq(bank.top3(2), user1);
        vm.prank(user4);
        bank.deposit{value: 3*10**18 }();
        assertEq(bank.top3(0), user3);
        assertEq(bank.top3(1), user4);
        assertEq(bank.top3(2), user2);
        vm.prank(user1);
        bank.deposit{value: 2*10**18 }();
        assertEq(bank.top3(0), user3);
        assertEq(bank.top3(1), user4);
        assertEq(bank.top3(2), user1);
        vm.prank(user1);
        bank.deposit{value: 1*10**18 }();
        assertEq(bank.top3(0), user3);
        assertEq(bank.top3(1), user1);
        assertEq(bank.top3(2), user4);
        vm.prank(user1);
        bank.deposit{value: 1*10**18 }();
        assertEq(bank.top3(0), user1);
        assertEq(bank.top3(1), user3);
        assertEq(bank.top3(2), user4);
        vm.prank(user1);
        bank.deposit{value: 1*10**18 }();
        assertEq(bank.top3(0), user1);
        assertEq(bank.top3(1), user3);
        assertEq(bank.top3(2), user4);
        vm.prank(user1);
        bank.deposit{value: 1*10**18 }();
        assertEq(bank.top3(0), user1);
        assertEq(bank.top3(1), user3);
        assertEq(bank.top3(2), user4);
    }
    // 3. 检查只有管理员可取款，其他人不可以取款。  请提交 github 仓库，仓库中需包含运行 case 通过的日志。
    function test_withdraw_admin() public{
        vm.deal(user1, 0 ether);
        vm.deal(user2, 100 ether);
        vm.prank(user2);
        bankUser1.deposit{value: 10*10**18 }();
        assertEq(address(bankUser1).balance, 10 ether);
        vm.prank(user1);
        bankUser1.withdraw(10*10**18);
        assertEq(user1.balance,10 ether);
        assertEq(address(bankUser1).balance,0 ether);
    }
    function test_withdraw_not_admin() public{
        vm.deal(user1, 0 ether);
        vm.deal(user2, 100 ether);
        vm.prank(user2);
        bankUser1.deposit{value: 10*10**18 }();
        assertEq(address(bankUser1).balance, 10 ether);
        vm.prank(user2);
        vm.expectRevert( "only administrator can withdraw");
        bankUser1.withdraw(10*10**18);
        

    }
}