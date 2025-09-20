import { useState } from 'react'
import { 
  createPublicClient, 
  createWalletClient, 
  http,
  custom,
  type Hash,
  type Address,
  type WalletClient,
  getContract,
} from 'viem';
import { waitForTransactionReceipt } from 'viem/actions';
import { foundry,sepolia } from 'viem/chains';
import TokenBankABI from '../abi/TokenBank_Permit2.json';
import ERC20PermitABI from '../abi/TokenERC20_Permit.json';

function TokenBank_Permit2() {
  const [walletClient, setWalletClient] = useState<WalletClient|null>(null);
  const [balance, setBalance] = useState(0)
  const [balanceInBank, setBalanceInBank] = useState(0)
  const [isLinked, setLinked] = useState(false)
  const [userAddr, setUserAddr] = useState<`0x${string}`>('0x')
  const [amount, setAmount] = useState('')
  const [outAmount, setOutAmount] = useState('')
  const [error, setError] = useState<string>('');
  const [isProcessing, setIsProcessing] = useState(false);
  const [bankContract,setBank] = useState<any>(null);
  const [tokenContract,setToken] = useState<any>(null);

  const bankAddr: `0x${string}` = '0x4866C14E7517970df302B1d802fD59ce5eDa1459'
  const permit2Addr: Address ='0x000000000022D473030F116dDEE9F6B43aC78BA3'
  

  // 创建公共客户端
  // const publicClient = createPublicClient({
  //   chain: foundry,
  //   transport: http()
  // })
  // 链接sepolia测试网
  const publicClient= createPublicClient({
    chain: sepolia,
    transport: http('https://eth-sepolia.public.blastapi.io'),
  });
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
        chain: sepolia,
        transport: custom(window.ethereum as any)
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
          abi: ERC20PermitABI,
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
    // console.log("tokenContract",tokenContract)
    // console.log("bankContract",bankContract)
    await tokenContract.write.approve([bankAddr,amount], {
      account: userAddr
    })
    await bankContract.write.deposit([amount], {
      account: userAddr
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
      account: userAddr
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

  async function queryBalanceWithRetry(maxRetries: number, delay: number): Promise<void> {
    for (let i = 0; i < maxRetries; i++) {
      try {
        await queryBalance()
        await queryBalanceInBank()
        return
      } catch (error) {
        console.warn(`余额查询重试 ${i + 1}/${maxRetries} 失败:`, error)
        if (i < maxRetries - 1) {
          await new Promise(resolve => setTimeout(resolve, delay))
        }
      }
    }
    throw new Error('余额查询重试失败')
  }

  const depositWithPermit2 = async function(){
    if (isProcessing) return; // 防止重复提交
    
    try {
      setIsProcessing(true)
      setError('')
      
      //存款approv+deposit
      // console.log("tokenContract",tokenContract)
      // console.log("bankContract",bankContract)
      
      //域信息
      const domain = {
        name: 'Permit2',
        chainId: sepolia.id,
        verifyingContract: permit2Addr
      };
      //EIP712结构数据
      const types = {
        TokenPermissions:[
          { name: 'token', type: 'address' },
          { name: 'amount', type: 'uint256' }
        ],
        PermitTransferFrom: [
          { name: 'permitted', type: 'TokenPermissions'},
          { name: 'spender', type: 'address' },
          { name: 'nonce', type: 'uint256' },
          { name: 'deadline', type: 'uint256' }
        ]
      };

      //原始数据
      //Permit2支持非自增的nonce，这里nonce使用随机数
      const nonce = BigInt(Math.floor(Math.random() * Number.MAX_SAFE_INTEGER))
      console.log(nonce)
      const msg = {
        permitted:{
          token:tokenContract.address,
          amount:BigInt(amount || '0')
        },
        spender: bankContract.address,
        nonce: nonce,
        //deadline为当前时间向后30分钟
        deadline: BigInt(Math.floor(Date.now() / 1000) + 30 * 60)
      };
      console.log(msg)
      
      const signature = await walletClient?.signTypedData({
        account:userAddr, domain, types,
        primaryType: 'PermitTransferFrom',
        message: msg
      });
      
      // 发送交易并获取交易哈希
      const txHash = await bankContract.write.depositWithPermit2([msg,BigInt(amount || '0'),signature], {
        account: userAddr
      }) as Hash;
      
      console.log('交易已发送，哈希:', txHash)
      
      // 等待交易确认 - 增加确认数量到3个区块
      console.log('等待交易确认...')
      const receipt = await waitForTransactionReceipt(publicClient, {
        hash: txHash,
        confirmations: 3  // 增加到3个确认，确保交易完全确认
      });
      
      if (receipt.status === 'success') {
        console.log('交易确认成功')
        
        // 等待一小段时间让区块链状态同步
        await new Promise(resolve => setTimeout(resolve, 1000))
        
        // 使用重试机制查询余额
        try {
          await queryBalanceWithRetry(3, 2000)
          console.log('余额更新成功')
        } catch (retryError) {
          console.warn('余额查询重试失败，使用单次查询:', retryError)
          // 如果重试失败，至少尝试一次查询
          await queryBalance()
          await queryBalanceInBank()
        }
        
        //成功后更新/清理状态
        setAmount('')
        setError('') // 清除之前的错误
      } else {
        setError('交易失败')
        console.error('交易失败:', receipt)
      }
    } catch (error) {
      console.error('depositWithPermit2 失败:', error)
      setError('存款失败: ' + (error instanceof Error ? error.message : '未知错误'))
    } finally {
      setIsProcessing(false)
    }
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
              <button onClick={depositWithPermit2}>点击向TokenBank签名(Permit2)并存款</button>
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

export default TokenBank_Permit2
