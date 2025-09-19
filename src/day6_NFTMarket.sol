// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount)external returns (bool);
    function transferFrom(address sender,address recipient,uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender)external view returns (uint256);
}
//*略/
interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address);
    function transferFrom(address from,address to,uint256 tokenId) external;
    function safeTransferFrom(address from,address to,uint256 tokenId) external;
    function isApprovedForAll(address owner, address operator)external view returns (bool);
    function getApproved(uint256 tokenId) external view returns (address);
}

contract NFTMarket {
    //NFT信息
    struct NFTInfo {
        address owner; //NFT持有人地址
        IERC721 nftContract; //NFT合约地址
        uint256 tokenId; //NFT的tokenId
        uint256 price; //售卖价格
    }

    //上架的NFT
    mapping(uint256 => NFTInfo) public priceList; //id=>NFT信息
    //token合约地址
    IERC20 private _tokenAddr;
    //自增id
    uint256 public _ids;

    constructor(address erc20) {
        _tokenAddr = IERC20(erc20);
    }

    //上架
    function list(IERC721 erc721,uint256 tokenId,uint256 price) external {
        address owner = erc721.ownerOf(tokenId);
        //检验nft是否存在
        require(owner != address(0), "this NFT not exist");
        //校验是否为NFT的持有者
        require(msg.sender == owner, "you are not the owner of the NFT");
        //校验授权
        require(
            erc721.getApproved(tokenId) == address(this) ||
                erc721.isApprovedForAll(owner, address(this)),
            "you have not approved this NFT to nftMarket"
        );
        //NFT转至合约
        erc721.transferFrom(msg.sender, address(this), tokenId);
        //更新上架信息
        NFTInfo memory info = NFTInfo(owner, erc721, tokenId, price);
        priceList[_ids++] = info;
        emit List(erc721,tokenId,price,msg.sender);
    }

    //购买
    function buyNFT(uint256 id) external {
        _buyNft(id);
    }
    function _buyNft(uint256 id) internal{
        NFTInfo memory info = priceList[id];
        //买卖双方是否相同
        require(msg.sender != info.owner,"the saler buy the NFT himself");
        //校验是否上架
        require(info.owner != address(0), "the id is not listed now");
        //校验tokenId余额与授权
        require(
            _tokenAddr.balanceOf(msg.sender) >= info.price,
            "the balance is not enough"
        );
        require(
            _tokenAddr.allowance(msg.sender, address(this)) >= info.price,
            "the allowance not enough"
        );
        //token从买方转到卖方
        bool success = _tokenAddr.transferFrom(
            msg.sender,
            info.owner,
            info.price
        );
        require(success, "token transfer failed");
        //NFT从合约转到买方
        info.nftContract.transferFrom(address(this), msg.sender, info.tokenId);
        //清除上架信息
        delete priceList[id];
        emit BuyNFT(id,info.tokenId,msg.sender);
    }

    event List(IERC721 indexed erc721,uint256 indexed tokenId,uint256 price,address sender);
    event BuyNFT(uint256 id,uint256 tokenId,address sender);
}
