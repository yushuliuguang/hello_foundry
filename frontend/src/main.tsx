import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import {createBrowserRouter,RouterProvider} from 'react-router-dom'
import './index.css'
import App from './App.tsx'
import TokenBank from './TokenBank.tsx'
import NFTMarketLisner from './NFTMarketEventLisner.tsx'

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
  }
])

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <RouterProvider router={router}></RouterProvider>
  </StrictMode>,
)
