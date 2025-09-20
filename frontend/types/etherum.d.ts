// interface Window {
//     ethereum?: {
//       request: (args: { method: string; params?: any[] }) => Promise<any>;
//       on: (event: string, callback: (params: any) => void) => void;
//       removeListener: (event: string, callback: (params: any) => void) => void;
//       removeAllListeners?: (event: string) => void;
//       isMetaMask?: boolean;
//       isConnected?: () => boolean;
//       chainId?: string;
//       selectedAddress?: string;
//     };
//   } 


// types/ethereum.d.ts
import { MetaMaskInpageProvider } from '@metamask/providers';

declare global {
  interface Window {
    ethereum?: MetaMaskInpageProvider;
  }
}

// 声明 JSON 模块
declare module '*.json' {
  const value: any;
  export default value;
}

// 确保文件被当作模块处理
export {};