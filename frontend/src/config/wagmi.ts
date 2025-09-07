import { createConfig, http } from 'wagmi'
import { mainnet, sepolia, localhost } from 'wagmi/chains'
import { injected, metaMask, walletConnect } from 'wagmi/connectors'
import { type Config} from 'wagmi';

// 配置支持的链
export const chains = [mainnet, sepolia, localhost] as const

// 创建 wagmi 配置
// export const config:Config = createConfig({
//   chains,
//   connectors: [
//     injected(),
//     metaMask(),
//     walletConnect({
//       projectId: 'd359f0d7aa03c6f43692845e210b13ac', // hello_foundryS
//     }),
//   ],
//   transports: {
//     [mainnet.id]: http(),
//     [sepolia.id]: http(),
//     [localhost.id]: http('http://localhost:8545'),
//   },
// })

// // 声明模块类型
// declare module 'wagmi' {
//   interface Register {
//     config: typeof config
//   }
// }
