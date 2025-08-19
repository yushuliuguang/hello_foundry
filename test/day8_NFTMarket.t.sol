// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {NFTMarket,IERC20,IERC721} from "../src/day6_NFTMarket.sol";
import {TokenERC20} from "../src/day5_TokenERC20.sol";
import {TokenERC721} from "../src/day6_TokenERC721.sol";


contract NFTMarketTest is Test {
    NFTMarket private market;
    TokenERC20 private tokenContract;
    TokenERC721 private nftContract;
    string private baseURI="ipfs://";

    address public saler;
    address public customer;

    function setUp() public {
        tokenContract = new TokenERC20(10**10);
        nftContract = new TokenERC721("nft","nft",baseURI);
        saler=0x94658EC7EF791214E423F484C6374f2B96ff50eE;
        customer=0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
        // user3=0x70997970C51812dc3A010C7d01b50e0d17dc79C8;
        // user4=0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC;
        //vm.prank(user1);
        market=new NFTMarket(address(tokenContract));
    }
    
    // 1.上架NFT：测试上架成功和失败情况，要求断言错误信息和上架事件。
    
    function test_list_success() public{
        uint tokenId = _prepareList();
        vm.expectEmit(true,true,true,true);
        emit NFTMarket.List(IERC721(address(nftContract)),tokenId,10,saler);
        vm.prank(saler);
        market.list(IERC721(address(nftContract)),tokenId,10);
        assertEq(nftContract.ownerOf(tokenId),address(market));
        uint id = market._ids()-1;
        (address addr,IERC721 ierc721,uint t,uint price)=market.priceList(id);
        assertEq(price,10);
        assertEq(t,tokenId);
        assertEq(addr,saler);
        assertEq(address(ierc721),address(nftContract));
    }
    function test_list_fail() public{
        uint tokenId = _prepareList();
        vm.expectRevert("you are not the owner of the NFT");
        market.list(IERC721(address(nftContract)),tokenId,10);
        vm.expectRevert("this NFT not exist");
        tokenId++;
        vm.prank(saler);
        market.list(IERC721(address(nftContract)),tokenId,10);
    }
    function _prepareList() private returns (uint){
        uint tokenId=nftContract.mint(saler,"123");
        vm.prank(saler);
        nftContract.approve(address(market),tokenId);
        return tokenId;
    }
    // 2. 购买NFT：测试购买成功、自己购买自己的NFT、NFT被重复购买、支付Token过多或者过少情况，要求断言错误信息和购买事件。
    function test_buy_success() public{
        uint tokenId=_prepareBuy();
        uint id= market._ids()-1;
        vm.expectEmit(true,true,true,true);
        emit TokenERC20.Transfer(customer,saler, 10);
        vm.expectEmit(true,true,true,true);
        emit NFTMarket.BuyNFT(id,tokenId,customer);
        vm.prank(customer);
        market.buyNFT(id);
        assertEq(nftContract.ownerOf(tokenId),customer);

    }
    function test_buy_self() public{
        uint tokenId=_prepareBuy();
        tokenContract.transfer(saler,10);
        vm.prank(saler);
        tokenContract.approve(address(market),10);
        uint id= market._ids()-1;
        vm.expectRevert("the saler buy the NFT himself");
        vm.prank(saler);
        market.buyNFT(id);
    }
    function test_buy_repeat() public{
        uint tokenId=_prepareBuy();
        uint id= market._ids()-1;
        vm.prank(customer);
        market.buyNFT(id);
        vm.expectRevert("the id is not listed now");
        vm.prank(customer);
        market.buyNFT(id);
    }
    // function test_buy_moreToken() public{

    // }
    function test_buy_lessToken() public{
        tokenContract.transfer(customer,9);
        vm.prank(customer);
        tokenContract.approve(address(market),10);
        uint tokenId = _prepareList();
        vm.prank(saler);
        market.list(IERC721(address(nftContract)),tokenId,10);
        uint id= market._ids()-1;
        vm.expectRevert("the balance is not enough");
        vm.prank(customer);
        market.buyNFT(id);
    }
    function _prepareBuy() private returns (uint){
        tokenContract.transfer(customer,10);
        vm.prank(customer);
        tokenContract.approve(address(market),10);
        uint tokenId = _prepareList();
        vm.prank(saler);
        market.list(IERC721(address(nftContract)),tokenId,10);
        return tokenId;
    }

    // 3. 模糊测试：测试随机使用 0.01-10000 Token价格上架NFT，并随机使用任意Address购买NFT
    function testFuzz_listAndBuy(uint price,address _customer) public{
        vm.assume(price>=10**18);
        vm.assume(price<=10000*10**18);
        tokenContract.transfer(_customer,price);
        vm.prank(_customer);
        tokenContract.approve(address(market),price);
        uint tokenId=nftContract.mint(address(this),"123");
        nftContract.approve(address(market),tokenId);
        market.list(IERC721(address(nftContract)),tokenId,price);
        uint id=market._ids()-1;
        vm.prank(_customer);
        market.buyNFT(id);
        // 获取NFTInfo结构体并验证其属性
        (,,tokenId,) = (market.priceList(id));
        assertEq(tokenId, 0);
        assertEq(tokenContract.balanceOf(_customer),0);
        assertEq(nftContract.ownerOf(tokenId),_customer);
    }
    //「可选」不可变测试：测试无论如何买卖，NFTMarket合约中都不可能有 Token 持仓
    function invariant_marktHasNotToken() public view{
        assertEq(tokenContract.balanceOf(address(market)),0);
    }
}

