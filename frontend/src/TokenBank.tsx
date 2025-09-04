import { useState,useEffect } from 'react'
import { 
  createPublicClient, 
  createWalletClient, 
  http,
  parseEther, 
  formatEther,
  type Address,
  type Hash,
  custom,
  type WalletClient,
  type RequestAddressesReturnType,
  getContract
} from 'viem';
import { foundry,sepolia } from 'viem/chains';
import TokenBankABI from '../abi/TokenBank.json';
import IERC20ABI from '../abi/IERC20.json';

function TokenBank() {
  const [walletClient, setWalletClient] = useState<WalletClient|null>(null);
  const [balance, setBalance] = useState(0)
  const [balanceInBank, setBalanceInBank] = useState(0)
  const [isLinked, setLinked] = useState(false)
  const [userAddr, setUserAddr] = useState('')
  const [amount, setAmount] = useState('')
  const [outAmount, setOutAmount] = useState('')
  const [error, setError] = useState<string>('');
  const [bankContract,setBank] = useState<any>(null);
  const [tokenContract,setToken] = useState<any>(null);

  const bankAddr: `0x${string}` = '0x631E069699c9a4Fc13782551370a459dBa894680'
  

  // 创建公共客户端
  const publicClient = createPublicClient({
    chain: foundry,
    transport: http()
  })
  // 链接sepolia测试网
  // const publicClient= createPublicClient({
  //   chain: sepolia,
  //   transport: http('https://eth-sepolia.public.blastapi.io'),
  // });
  //console.log(publicClient)

  
  const linkToMetaMask = async function(){
    try {
      //viem连接钱包
      if (typeof window === 'undefined' || !window.ethereum) {
        setError('请安装 MetaMask 或在浏览器中运行');
        console.log('请安装 MetaMask 或在浏览器中运行')
        return;
      }

      const client = createWalletClient({
        chain: foundry,
        transport: custom(window.ethereum)
      });
      
      if(client){
        setWalletClient(client);
        
        // 请求用户授权连接钱包
        const addresses = await client.requestAddresses()
        
        if (addresses && addresses.length > 0) {
          //成功后修改状态 isLinked,userAddr
          setLinked(true)
          setUserAddr(addresses[0])
          setError('') // 清除之前的错误
        } else {
          setError('未能获取钱包地址')
          return
        }
        const bankContract = getContract({
          address: bankAddr,
          abi: TokenBankABI as any,
          //公共和钱包客户端
          client: { public: publicClient, wallet: client }
        })
        if(!bankContract){
          setError('未能获取bank合约对象')
          return
        }
        setBank(bankContract)
        console.log(bankContract)
        //const tokenAddr:any = await bankContract.read.token([]) 
        const tokenAddr:any = await publicClient.readContract({
            address: bankAddr,
            abi: TokenBankABI as any,
            functionName: 'token',
            args:[]
          })
        console.log('TokenBank 合约地址:', bankAddr)
        console.log('TokenERC20 合约地址:', tokenAddr)
        const tokenContract = getContract({
          address: tokenAddr,
          abi: IERC20ABI,
          //公共和钱包客户端
          client: { public: publicClient, wallet: client }
        })
        if(!tokenContract){
          setError('未能获取token合约对象')
          return
        }
        setToken(tokenContract)
        const balance:any = await tokenContract.read.balanceOf([addresses[0]])
        setBalance(balance)
        const balanceInBank:any = await bankContract.read.records([addresses[0]])
        setBalanceInBank(balanceInBank)
      }
    } catch (error) {
      console.error('连接钱包失败:', error)
      setError('连接钱包失败: ' + (error instanceof Error ? error.message : '未知错误'))
    }
  }
  const checkDeposit=function(e:React.ChangeEvent<HTMLInputElement>){
    let v:number = parseInt(e.target.value)
    if(v<0){
      v=0
    }else if(v>balance){
      v=balance
    }
    setAmount(v.toString())
  }
  const checkWithdraw=function(e:React.ChangeEvent<HTMLInputElement>){
    let v:number = parseInt(e.target.value)
    if(v<0){
      v=0
    }else if(v>balanceInBank){
      v=balanceInBank
    }
    setOutAmount(v.toString())
  }
  

  const deposit = async function(){
    //存款approv+deposit
    console.log("tokenContract",tokenContract)
    console.log("bankContract",bankContract)
    await tokenContract.write.approve([bankAddr,amount], {
      account: userAddr as `0x${string}`
    })
    await bankContract.write.deposit([amount], {
      account: userAddr as `0x${string}`
    })
    //成功后查询当前存款(bank和token)
    await queryBalance()
    await queryBalanceInBank()
    //成功后更新/清理状态
    setAmount('')
  }
  const withdraw =async function(){
    //取款withdraw
    await bankContract.write.withdraw([outAmount], {
      account: userAddr as `0x${string}`
    })
    //成功后查询当前存款(bank和token)
    await queryBalance()
    await queryBalanceInBank()
    //成功后更新/清理状态
    setOutAmount('')
  }
  async function queryBalance():Promise<void>{
    const balance:any = await tokenContract.read.balanceOf([userAddr])
    setBalance(balance)
  }
  async function queryBalanceInBank():Promise<void>{
    const balanceInBank:any = await bankContract.read.records([userAddr])
    setBalanceInBank(balanceInBank)
  }

  return (
    <>
      {error && <div style={{color: 'red', marginBottom: '10px'}}>错误: {error}</div>}
      {!isLinked && <button onClick={linkToMetaMask}>点击连接metamask钱包</button>}
      {isLinked && 
        <div>
          <div>
            <span >用户地址：{userAddr},当前token余额：{balance}</span>
            <div>
              <input  type="number" onChange={checkDeposit} placeholder='输入存入Token数' value={amount}></input>
              <button onClick={deposit}>点击向TokenBank存款</button>
            </div>
          </div>
          <div>
            <span>当前存款Token数：{balanceInBank}</span>
            <div>
              <input  type="number" onChange={checkWithdraw} placeholder='输入取出Token数' value={outAmount}></input>
              <button onClick={withdraw}>点击从TokenBank取款</button>
            </div>
        </div>
      </div>
      }

    </>
  )
}

export default TokenBank
