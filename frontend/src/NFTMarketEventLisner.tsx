import { useEffect } from 'react';
import { 
  createPublicClient, 
  formatEther, 
  http,
  publicActions,
  type PublicClient
} from 'viem';
import { foundry,sepolia } from 'viem/chains';

function NFTMarketLisner() {

  const marketAddr: `0x${string}` = '0x1926CdC80805F44eB5Be0b2899fF6a3798506CEd'

  // 创建公共客户端
  // const publicClient:PublicClient = createPublicClient({
  //   chain: foundry,
  //   transport: http('http://127.0.0.1:8545'),
  // }).extend(publicActions);
  const publicClient:PublicClient = createPublicClient({
    chain: foundry,
    transport: http(),
  });
  useEffect(()=>{
    // 监听List事件
    publicClient.watchEvent({
      address: marketAddr,
      event: {
        type: 'event',
        name: 'List',
        inputs: [
          { type: 'address', indexed: true, name: 'erc721' },
          { type: 'uint256', indexed: true, name: 'tokenId' },
          { type: 'uint256', indexed: false, name: 'price' },
          { type: 'address', indexed: false, name: 'sender' }
        ]   
      },
      onLogs: (logs:any) => {
        console.log("检测到新的NFT上架事件:");
        logs.forEach((log:any) => {
          console.log(`NFT合约: ${log.args.erc721}`);
          console.log(`Token ID: ${log.args.tokenId}`);
          console.log(`价格: ${formatEther(log.args.price)} ETH`);
          console.log(`上架者: ${log.args.sender}`);
          console.log(`交易哈希: ${log.transactionHash}`);
          console.log(`区块号: ${log.blockNumber}`);
        });
      }
    });

    // 监听BuyNFT事件
    publicClient.watchEvent({
      address: marketAddr,
      event: {
        type: 'event',
        name: 'BuyNFT',
        inputs: [
          { type: 'uint256', indexed: false, name: 'id' },
          { type: 'uint256', indexed: false, name: 'tokenId' },
          { type: 'address', indexed: false, name: 'sender' }   
        ]   
      },
      onLogs: (logs:any) => {
        console.log("检测到新的NFT购买事件:");
        logs.forEach((log:any) => {
          console.log(`上架ID: ${log.args.id}`);
          console.log(`Token ID: ${log.args.tokenId}`);
          console.log(`购买者: ${log.args.sender}`);
          console.log(`交易哈希: ${log.transactionHash}`);
          console.log(`区块号: ${log.blockNumber}`);
        });
      }
    });
  },[])
  



  return (
    <>
      <div>
          <span>正在监听NFT市场事件，请查看控制台</span>
      </div>
    </>
  )
}

export default NFTMarketLisner