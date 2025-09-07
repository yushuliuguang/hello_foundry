import { useAccount, useBalance, useChainId } from 'wagmi'

export default function WalletInfo() {
  const { address, isConnected } = useAccount()
  const chainId = useChainId()
  const { data: balance } = useBalance({
    address: address,
  })

  if (!isConnected) {
    return null
  }

  return (
    <div className="wallet-info-details">
      <h3>钱包信息</h3>
      <div className="info-grid">
        <div className="info-item">
          <label>地址:</label>
          <span className="address">{address}</span>
        </div>
        <div className="info-item">
          <label>链 ID:</label>
          <span>{chainId}</span>
        </div>
        <div className="info-item">
          <label>余额:</label>
          <span>
            {balance ? `${parseFloat(balance.formatted).toFixed(4)} ${balance.symbol}` : '加载中...'}
          </span>
        </div>
      </div>
    </div>
  )
}
