// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {NFTMarket_Permit} from "../src/day12_NFTMarket_Permit.sol";
import {IERC20,IERC721,NFTMarket} from "../src/day6_NFTMarket.sol";
import {TokenERC20} from "../src/day5_TokenERC20.sol";
import {TokenERC721} from "../src/day6_TokenERC721.sol";


contract NFTMarketTest is Test {
    NFTMarket_Permit private market;
    TokenERC20 private tokenContract;
    TokenERC721 private nftContract;
    string private baseURI="ipfs://";

    address public saler;
    address public customer;
    address public admin;
    uint256 private adminPk;

    function setUp() public {
        saler=0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
        customer=0x94658EC7EF791214E423F484C6374f2B96ff50eE;
        tokenContract = new TokenERC20(address(this),10**10);
        nftContract = new TokenERC721("nft","nft",baseURI);
        adminPk = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        admin = vm.addr(adminPk);
        market=new NFTMarket_Permit("NFTMarketPermit",address(tokenContract),admin);
    }
    
    // // 1.上架NFT：测试上架成功和失败情况，要求断言错误信息和上架事件。
    
    // function test_list_success() public{
    //     uint tokenId = _prepareList();
    //     vm.expectEmit(true,true,true,true);
    //     emit NFTMarket.List(IERC721(address(nftContract)),tokenId,10,saler);
    //     vm.prank(saler);
    //     market.list(IERC721(address(nftContract)),tokenId,10);
    //     assertEq(nftContract.ownerOf(tokenId),address(market));
    //     uint id = market._ids()-1;
    //     (address addr,IERC721 ierc721,uint t,uint price)=market.priceList(id);
    //     assertEq(price,10);
    //     assertEq(t,tokenId);
    //     assertEq(addr,saler);
    //     assertEq(address(ierc721),address(nftContract));
    // }
    // function test_list_fail() public{
    //     uint tokenId = _prepareList();
    //     vm.expectRevert("you are not the owner of the NFT");
    //     market.list(IERC721(address(nftContract)),tokenId,10);
    //     vm.expectRevert("this NFT not exist");
    //     tokenId++;
    //     vm.prank(saler);
    //     market.list(IERC721(address(nftContract)),tokenId,10);
    // }
    function _prepareList() private returns (uint){
        uint tokenId=nftContract.mint(saler,"123");
        vm.prank(saler);
        nftContract.approve(address(market),tokenId);
        return tokenId;
    }
    // // 2. 购买NFT：测试购买成功、自己购买自己的NFT、NFT被重复购买、支付Token过多或者过少情况，要求断言错误信息和购买事件。
    // function test_buy_success() public{
    //     uint tokenId=_prepareBuy();
    //     uint id= market._ids()-1;
    //     vm.expectEmit(true,true,true,true);
    //     emit TokenERC20.Transfer(customer,saler, 10);
    //     vm.expectEmit(true,true,true,true);
    //     emit NFTMarket.BuyNFT(id,tokenId,customer);
    //     vm.prank(customer);
    //     market.buyNFT(id);
    //     assertEq(nftContract.ownerOf(tokenId),customer);

    // }
    // function test_buy_self() public{
    //     uint tokenId=_prepareBuy();
    //     tokenContract.transfer(saler,10);
    //     vm.prank(saler);
    //     tokenContract.approve(address(market),10);
    //     uint id= market._ids()-1;
    //     vm.expectRevert("the saler buy the NFT himself");
    //     vm.prank(saler);
    //     market.buyNFT(id);
    // }
    // function test_buy_repeat() public{
    //     uint tokenId=_prepareBuy();
    //     uint id= market._ids()-1;
    //     vm.prank(customer);
    //     market.buyNFT(id);
    //     vm.expectRevert("the id is not listed now");
    //     vm.prank(customer);
    //     market.buyNFT(id);
    // }
    // // function test_buy_moreToken() public{

    // // }
    // function test_buy_lessToken() public{
    //     tokenContract.transfer(customer,9);
    //     vm.prank(customer);
    //     tokenContract.approve(address(market),10);
    //     uint tokenId = _prepareList();
    //     vm.prank(saler);
    //     market.list(IERC721(address(nftContract)),tokenId,10);
    //     uint id= market._ids()-1;
    //     vm.expectRevert("the balance is not enough");
    //     vm.prank(customer);
    //     market.buyNFT(id);
    // }
    function _prepareBuy() private returns (uint){
        tokenContract.transfer(customer,10);
        vm.prank(customer);
        tokenContract.approve(address(market),10);
        uint tokenId = _prepareList();
        vm.prank(saler);
        market.list(IERC721(address(nftContract)),tokenId,10);
        return tokenId;
    }



    // // 3. 模糊测试：测试随机使用 0.01-10000 Token价格上架NFT，并随机使用任意Address购买NFT
    // function testFuzz_listAndBuy(uint price,address _customer) public{
    //     vm.assume(price>=10**18);
    //     vm.assume(price<=10000*10**18);
    //     tokenContract.transfer(_customer,price);
    //     vm.prank(_customer);
    //     tokenContract.approve(address(market),price);
    //     uint tokenId=nftContract.mint(address(this),"123");
    //     nftContract.approve(address(market),tokenId);
    //     market.list(IERC721(address(nftContract)),tokenId,price);
    //     uint id=market._ids()-1;
    //     vm.prank(_customer);
    //     market.buyNFT(id);
    //     // 获取NFTInfo结构体并验证其属性
    //     (,,tokenId,) = (market.priceList(id));
    //     assertEq(tokenId, 0);
    //     assertEq(tokenContract.balanceOf(_customer),0);
    //     assertEq(nftContract.ownerOf(tokenId),_customer);
    // }

    //4.测试permitBuy方法成功、失败、模糊测试
    function test_permitBuy_success() public {
        console.log("--start--");
        tokenContract.transfer(customer,10);
        vm.prank(customer);
        tokenContract.approve(address(market),10);
        uint tokenId=nftContract.mint(saler,"123");
        console.log("balance of customer:%d",tokenContract.balanceOf(customer));
        console.log("balance of saler:%d",tokenContract.balanceOf(saler));
        console.log("owner of nft:%s",nftContract.ownerOf(tokenId));
        vm.prank(saler);
        nftContract.approve(address(market),tokenId);
        vm.prank(saler);
        market.list(IERC721(address(nftContract)),tokenId,10);
        uint id= market._ids()-1;
        console.log("--listed--");
        console.log("balance of customer:%d",tokenContract.balanceOf(customer));
        console.log("balance of saler:%d",tokenContract.balanceOf(saler));
        console.log("owner of nft:%s",nftContract.ownerOf(tokenId));
        uint256 nonce = market.nonces(customer);
        bytes memory sig = _signPermitBuy(customer, nonce);
        NFTMarket_Permit.PermitBuy memory data = NFTMarket_Permit.PermitBuy({consumer: customer, nonce: nonce});
        vm.expectEmit(true,true,true,true);
        emit TokenERC20.Transfer(customer,saler, 10);
        vm.expectEmit(true,true,true,true);
        emit NFTMarket.BuyNFT(id,tokenId,customer);
        vm.prank(customer);
        market.permitBuy(sig, data, id);
        assertEq(nftContract.ownerOf(tokenId),customer);
        console.log("--permitBuy--");
        console.log("balance of customer:%d",tokenContract.balanceOf(customer));
        console.log("balance of saler:%d",tokenContract.balanceOf(saler));
        console.log("owner of nft:%s",nftContract.ownerOf(tokenId));
    }

    function test_permitBuy_fail() public {
        // case 1: 非admin签名，签名者非法
        uint tokenId=_prepareBuy();
        uint id= market._ids()-1;
        uint256 nonce = market.nonces(customer);
        // 使用错误的私钥签名
        uint256 wrongPk = 0xB0B;
        bytes memory badSig = _signPermitBuyWithPk(customer, nonce, wrongPk);
        NFTMarket_Permit.PermitBuy memory data = NFTMarket_Permit.PermitBuy({consumer: customer, nonce: nonce});
        vm.expectRevert(bytes("invalid signer"));
        vm.prank(customer);
        market.permitBuy(badSig, data, id);

        // case 2: 调用者不是consumer
        uint tokenId2=_prepareBuy();
        uint id2= market._ids()-1;
        uint256 nonce2 = market.nonces(customer);
        bytes memory sig2 = _signPermitBuy(customer, nonce2);
        NFTMarket_Permit.PermitBuy memory data2 = NFTMarket_Permit.PermitBuy({consumer: customer, nonce: nonce2});
        vm.expectRevert(bytes("sender is not consumer"));
        vm.prank(saler);//错误的sender
        market.permitBuy(sig2, data2, id2);
    }

    function testFuzz_permitBuy(uint price,address _customer)public{
        vm.assume(price>=10**18);
        vm.assume(price<=10000*10**18);
        tokenContract.transfer(_customer,price);
        vm.prank(_customer);
        tokenContract.approve(address(market),price);
        uint tokenId=nftContract.mint(address(this),"123");
        nftContract.approve(address(market),tokenId);
        market.list(IERC721(address(nftContract)),tokenId,price);
        uint id=market._ids()-1;
        uint256 nonce = market.nonces(_customer);
        bytes memory sig = _signPermitBuy(_customer, nonce);
        NFTMarket_Permit.PermitBuy memory data=NFTMarket_Permit.PermitBuy({consumer: _customer, nonce: nonce});
        vm.prank(_customer);
        market.permitBuy(sig,data,id);
        // 获取NFTInfo结构体并验证其属性
        (,,tokenId,) = (market.priceList(id));
        assertEq(tokenId, 0);
        assertEq(tokenContract.balanceOf(_customer),0);
        assertEq(nftContract.ownerOf(tokenId),_customer);
    }

    // ---------------- internal helpers ----------------
    function _domainSeparator() internal view returns (bytes32) {
        bytes32 EIP712_DOMAIN_TYPEHASH = keccak256(
            bytes("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")
        );
        bytes32 nameHash = keccak256(bytes("NFTMarketPermit"));
        bytes32 versionHash = keccak256(bytes("1"));
        return keccak256(abi.encode(
            EIP712_DOMAIN_TYPEHASH,
            nameHash,
            versionHash,
            block.chainid,
            address(market)
        ));
    }

    function _signPermitBuy(address consumer, uint256 nonce) internal returns (bytes memory) {
        return _signPermitBuyWithPk(consumer, nonce, adminPk);
    }

    function _signPermitBuyWithPk(address consumer, uint256 nonce, uint256 pk) internal view returns (bytes memory)  {
        bytes32 TYPEHASH = keccak256(bytes("PermitBuy(address consumer,uint256 nonce)"));
        bytes32 structHash = keccak256(abi.encode(TYPEHASH, consumer, nonce));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", _domainSeparator(), structHash));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(pk, digest);
        return abi.encodePacked(r, s, v);
    }


    //「可选」不可变测试：测试无论如何买卖，NFTMarket合约中都不可能有 Token 持仓
    function invariant_marktHasNotToken() public view{
        assertEq(tokenContract.balanceOf(address(market)),0);
    }
}

