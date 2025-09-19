import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import {createBrowserRouter,RouterProvider} from 'react-router-dom'
import './index.css'
import App from './App.tsx'
import NFTMarket from './NFTMarket.tsx'
import TokenBank from './TokenBank.tsx'
import NFTMarketLisner from './NFTMarketEventLisner.tsx'
import { AppKitProvider } from './config/appkit.tsx'
import WalletConnect from './components/WalletConnect.tsx'
import WalletInfo from './components/WalletInfo.tsx'
import TokenBank_Permit from './TokenBank_Permit.tsx'


const router = createBrowserRouter([
  {
    path:"/",
    element:<App/>
  },
  {
    path:"app",
    element:<App/>
  },
  {
    path:"tokenBank",
    element:<TokenBank/>
  },{
    path:"NFTMarketEventListner",
    element:<NFTMarketLisner/>
  },{
    path:"walletConnect",
    element:<WalletConnect/>
  },{
    path:"walletInfo",
    element:<WalletInfo/>
  },{
    path:"NFTMarket",
    element:<NFTMarket/>
  },{
    path:"tokenBank_Permit",
    element:<TokenBank_Permit/>
  }
])

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <AppKitProvider>
      <RouterProvider router={router}></RouterProvider>
    </AppKitProvider>
  </StrictMode>,
)
