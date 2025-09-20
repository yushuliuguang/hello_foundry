import { createAppKit } from '@reown/appkit/react'
import { WagmiProvider } from 'wagmi'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
//import { config } from './wagmi'
import { mainnet, sepolia, foundry,optimism } from '@reown/appkit/networks'
import { WagmiAdapter } from '@reown/appkit-adapter-wagmi'
import type { AppKitNetwork} from '@reown/appkit-common'


// 创建 QueryClient 实例
const queryClient = new QueryClient()

// 创建 AppKit 实例
const projectId = 'd359f0d7aa03c6f43692845e210b13ac'
const networks:[AppKitNetwork,...AppKitNetwork[]] = [foundry,sepolia]
const wagmiAdapter = new WagmiAdapter({
  networks,
  projectId,
  ssr: true
});
export const appKit = createAppKit({
  adapters: [wagmiAdapter], // wagmi适配器
  projectId,
  networks,
  metadata: {
    name: 'Hello Foundry App',
    description: 'A Foundry-based DApp with Reown AppKit integration',
    url: 'https://localhost:5173',
    icons: ['https://avatars.githubusercontent.com/u/37784886']
  },
  defaultNetwork:foundry,//可以不设置
  /*features: {
    analytics: true
  }*/
})

// 导出提供者组件
export function AppKitProvider({ children }: { children: React.ReactNode }) {
  return (
    <WagmiProvider config={wagmiAdapter.wagmiConfig}>
      <QueryClientProvider client={queryClient}>
        {children}
      </QueryClientProvider>
    </WagmiProvider>
  )
}
