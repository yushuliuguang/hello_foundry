import { useEffect, useState } from 'react'
import { useAccount, useChainId, usePublicClient, useReadContract, useWriteContract } from 'wagmi'
import { formatEther, parseEther, type Address, erc20Abi } from 'viem'
import WalletConnect from './components/WalletConnect'
import WalletInfo from './components/WalletInfo'
import NFTMarketAbi from '../abi/NFTMarket.json'
import IERC20Abi from '../abi/IERC20.json'
import { ADDRESSES } from './config/addresses'

type Listing = { id: bigint; owner: Address; nftContract: Address; tokenId: bigint; price: bigint }

export default function NFTMarket() {
  const { address, isConnected } = useAccount()
  const chainId = useChainId()
  const publicClient = usePublicClient()
  const { writeContractAsync, isPending } = useWriteContract()

  const [erc721Addr, setErc721Addr] = useState<string>('')
  const [tokenId, setTokenId] = useState<string>('')
  const [price, setPrice] = useState<string>('')
  const [listings, setListings] = useState<Listing[]>([])

  const networkCfg = ADDRESSES[chainId] || {}
  const marketAddr = networkCfg.nftMarket as Address | undefined
  const erc20Addr = networkCfg.erc20 as Address | undefined

  const { data: ids } = useReadContract({
    abi: NFTMarketAbi as any,
    address: marketAddr,
    functionName: '_ids',
    query: { enabled: Boolean(marketAddr) }
  }) as { data: bigint | undefined }

  useEffect(() => {
    if (!marketAddr || !ids || !publicClient) return
    const load = async () => {
      const tasks: Promise<Listing | null>[] = []
      for (let i = 0n; i < ids; i++) {
        tasks.push(
          (async () => {
            try {
              const res = await publicClient.readContract({
                abi: NFTMarketAbi as any,
                address: marketAddr,
                functionName: 'priceList',
                args: [i]
              }) as unknown as [Address, Address, bigint, bigint]
              if (!res) return null
              const [owner, nftContract, tokenId, price] = res
              if (owner === '0x0000000000000000000000000000000000000000') return null
              return { id: i, owner, nftContract: nftContract as Address, tokenId, price }
            } catch {
              return null
            }
          })()
        )
      }
      const result = (await Promise.all(tasks)).filter(Boolean) as Listing[]
      setListings(result)
    }
    load()
  }, [marketAddr, ids, publicClient])

  //nft上架，未实现approve
  const handleList = async () => {
    if (!marketAddr || !isConnected) return
    const nft = (erc721Addr || networkCfg.erc721) as Address
    if (!nft || !tokenId || !price) return
    const tid = BigInt(tokenId)
    const wei = parseEther(price)
    await writeContractAsync({
      abi: NFTMarketAbi as any,
      address: marketAddr,
      functionName: 'list',
      args: [nft, tid, wei]
    })
    setTokenId('')
    setPrice('')
    location.reload()
  }

  //购买nft，实现approve
  const handleApproveAndBuy = async (id: bigint, need: bigint) => {
    if (!erc20Addr || !marketAddr || !address || !publicClient) return
    const allowance = await publicClient.readContract({
      abi: IERC20Abi as any,
      address: erc20Addr,
      functionName: 'allowance',
      args: [address, marketAddr]
    }) as unknown as bigint
    if ((allowance ?? 0n) < need) {
      await writeContractAsync({
        abi: erc20Abi,
        address: erc20Addr,
        functionName: 'approve',
        args: [marketAddr, need]
      })
    }
    await writeContractAsync({
      abi: NFTMarketAbi as any,
      address: marketAddr,
      functionName: 'buyNFT',
      args: [id]
    })
    location.reload()
  }

  return (
    <div className="page">
      <header className="page-header" style={{display:'flex',justifyContent:'space-between',alignItems:'center',gap:12,flexWrap:'wrap',padding:'12px 0'}}>
        <div style={{flexBasis:'100%'}}><h2>NFT 市场</h2></div>
        <div style={{display:'flex',alignItems:'center',gap:12}}>
          <WalletInfo/>
          <WalletConnect/>
        </div>
      </header>

      <section className="actions" style={{marginTop:16,display:'grid',gap:12,maxWidth:560}}>
        <h3>上架 NFT</h3>
        <input placeholder="ERC721 地址(留空用默认)" value={erc721Addr} onChange={e=>setErc721Addr(e.target.value)} />
        <input placeholder="Token ID" value={tokenId} onChange={e=>setTokenId(e.target.value)} />
        <input placeholder="价格(ERC20)" value={price} onChange={e=>setPrice(e.target.value)} />
        <button onClick={handleList} disabled={isPending || !isConnected || !marketAddr}>上架</button>
      </section>

      <section className="listings" style={{marginTop:24}}>
        <h3>已上架 NFT</h3>
        <div style={{display:'grid',gap:12}}>
          {(!listings || listings.length===0) && <div>暂无上架</div>}
          {listings.map(item => (
            <div key={item.id.toString()} style={{display:'flex',alignItems:'center',gap:12,border:'1px solid #eee',padding:12,borderRadius:8}}>
              <div>#{item.tokenId.toString()}</div>
              <div>合约: {item.nftContract}</div>
              <div>价格: {formatEther(item.price)} Token</div>
              <button onClick={() => handleApproveAndBuy(item.id, item.price)} disabled={!isConnected}>购买</button>
            </div>
          ))}
        </div>
      </section>
    </div>
  )
}


