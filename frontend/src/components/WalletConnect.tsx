import { useAccount, useConnect, useDisconnect } from 'wagmi'
import { useAppKit } from '@reown/appkit/react'

export default function WalletConnect() {
  const { address, isConnected } = useAccount()
  const { connect, connectors } = useConnect()
  const { disconnect } = useDisconnect()
  const { open } = useAppKit()

  const clearAppKitConnection = async () => {
    // 1) 断开钱包连接
    try { await disconnect() } catch {}

    // 2) 清理本地缓存（AppKit / WalletConnect / Wagmi 可能用到的键）
    const keysToClear = [
      'wagmi.store',
      'walletconnect',
      'WALLETCONNECT_DEEPLINK_CHOICE'
    ]
    // 清理 WalletConnect v2 相关命名空间
    const wcPrefixes = ['wc@2:', 'wc@2']
    // AppKit 可能使用的前缀（不同版本可能不同，做前缀清理）
    const appkitPrefixes = ['appkit', '@reown', '@walletconnect']

    const clearByPredicate = (storage: Storage) => {
      const allKeys = Object.keys(storage)
      for (const k of allKeys) {
        if (
          keysToClear.includes(k) ||
          wcPrefixes.some(p => k.startsWith(p)) ||
          appkitPrefixes.some(p => k.startsWith(p))
        ) {
          try { storage.removeItem(k) } catch {}
        }
      }
    }

    try { clearByPredicate(localStorage) } catch {}
    try { clearByPredicate(sessionStorage) } catch {}

    // 3) 可选：切回默认链（比如本地 foundry: 31337）
    // try { switchChain({ chainId: 31337 }) } catch {}

    // 4) 可选：刷新页面确保状态重置
    location.reload()
  }

  if (isConnected) {
    return (
      <div className="wallet-connect">
        <div className="wallet-info">
          <p>已连接钱包: {address?.slice(0, 6)}...{address?.slice(-4)}</p>
        </div>
        <button 
          onClick={() => clearAppKitConnection()}
          className="disconnect-btn"
        >
          断开连接
        </button>
      </div>
    )
  }

  return (
    <div className="wallet-connect">
      <button 
        onClick={() => open()}
        className="connect-btn"
      >
        连接钱包
      </button>
    </div>
  )
}
