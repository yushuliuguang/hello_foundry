import { createWalletClient, createPublicClient, http, parseEther, formatEther, parseUnits, formatUnits } from 'viem'
import { sepolia } from 'viem/chains'
import { privateKeyToAccount } from 'viem/accounts'
import { erc20Abi } from 'viem'
import readlineSync from 'readline-sync'

// Sepolia 网络配置
const SEPOLIA_RPC_URL = 'https://sepolia.drpc.org' // 请替换为您的 Infura 密钥
const SEPOLIA_CHAIN_ID = 11155111

// 创建公共客户端（用于查询）
const publicClient = createPublicClient({
  chain: sepolia,
  transport: http(SEPOLIA_RPC_URL)
})

// 全局变量存储钱包信息
let walletClient = null
let account = null
let privateKey = null

// 颜色输出函数
const colors = {
  reset: '\x1b[0m',
  bright: '\x1b[1m',
  red: '\x1b[31m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  magenta: '\x1b[35m',
  cyan: '\x1b[36m'
}

function colorLog(message, color = 'reset') {
  console.log(`${colors[color]}${message}${colors.reset}`)
}

// 1. 生成私钥和查询余额
async function generateWallet() {
  try {
    colorLog('\n=== 生成新钱包 ===', 'cyan')
    
    // 生成随机私钥
    privateKey = `0x${Array.from({ length: 64 }, () => Math.floor(Math.random() * 16).toString(16)).join('')}`
    
    // 从私钥创建账户
    account = privateKeyToAccount(privateKey)
    
    // 创建钱包客户端
    walletClient = createWalletClient({
      account,
      chain: sepolia,
      transport: http(SEPOLIA_RPC_URL)
    })
    
    colorLog(`私钥: ${privateKey}`, 'yellow')
    colorLog(`地址: ${account.address}`, 'green')
    
    // 查询 ETH 余额
    const ethBalance = await publicClient.getBalance({
      address: account.address
    })
    
    colorLog(`ETH 余额: ${formatEther(ethBalance)} ETH`, 'blue')
    
    // 查询 ERC20 代币余额（使用 0xdaD2f084F277b61A9d2fB2504d3c14afbE55F2D7 合约作为示例）
    const tokenAddress = '0xdaD2f084F277b61A9d2fB2504d3c14afbE55F2D7' // Sepolia TokenERC20
    try {
      const tokenBalance = await publicClient.readContract({
        address: tokenAddress,
        abi: erc20Abi,
        functionName: 'balanceOf',
        args: [account.address]
      })
      
      const tokenDecimals = await publicClient.readContract({
        address: tokenAddress,
        abi: erc20Abi,
        functionName: 'decimals'
      })
      
      colorLog(`token 余额: ${formatUnits(tokenBalance, tokenDecimals)} MTE20`, 'blue')
    } catch (error) {
      colorLog('无法查询 token 余额（可能未持有该代币）', 'yellow')
    }
    
    colorLog('\n请向此地址转入一些 ETH 和 token 进行测试:', 'magenta')
    colorLog(`地址: ${account.address}`, 'bright')
    colorLog('Sepolia 测试网水龙头: https://sepoliafaucet.com/', 'cyan')
    
  } catch (error) {
    colorLog(`生成钱包失败: ${error.message}`, 'red')
  }
}

// 2. 构建 ERC20 转账的 EIP 1559 交易
async function buildERC20Transfer() {
  if (!account) {
    colorLog('请先生成钱包！', 'red')
    return null
  }
  
  try {
    colorLog('\n=== 构建 ERC20 转账交易 ===', 'cyan')
    
    // 获取用户输入
    const tokenAddress = readlineSync.question('请输入 ERC20 代币合约地址 (默认 0xdaD2f084F277b61A9d2fB2504d3c14afbE55F2D7): ') || '0xdaD2f084F277b61A9d2fB2504d3c14afbE55F2D7'
    const toAddress = readlineSync.question('请输入接收地址: ')
    const amount = readlineSync.question('请输入转账数量: ')
    
    // 获取代币精度
    const decimals = await publicClient.readContract({
      address: tokenAddress,
      abi: erc20Abi,
      functionName: 'decimals'
    })
    
    // 转换数量为正确的单位
    const transferAmount = parseUnits(amount, decimals)
    
    // 获取当前 gas 价格
    const gasPrice = await publicClient.getGasPrice()
    const maxFeePerGas = gasPrice * 120n / 100n // 增加 20%
    const maxPriorityFeePerGas = gasPrice * 10n / 100n // 10% 作为优先费
    
    // 构建交易
    const transaction = {
      to: tokenAddress,
      data: encodeERC20Transfer(toAddress, transferAmount),
      value: 0n,
      gas: 100000n, // 预估 gas limit
      maxFeePerGas,
      maxPriorityFeePerGas,
      type: 'eip1559'
    }

    // 估算 gas
    const estimatedGas = await publicClient.estimateGas({
      account: account.address,
      to: tokenAddress,
      data: transaction.data,
      value: 0n
    })
    
    transaction.gas = estimatedGas * 120n / 100n // 增加 20% 缓冲
    
    colorLog(`\n交易详情:`, 'yellow')
    colorLog(`代币地址: ${tokenAddress}`, 'blue')
    colorLog(`接收地址: ${toAddress}`, 'blue')
    colorLog(`转账数量: ${amount}`, 'blue')
    colorLog(`Gas Limit: ${transaction.gas}`, 'blue')
    colorLog(`Max Fee Per Gas: ${formatUnits(maxFeePerGas, 9)} Gwei`, 'blue')
    colorLog(`Max Priority Fee: ${formatUnits(maxPriorityFeePerGas, 9)} Gwei`, 'blue')
    
    return transaction
    
  } catch (error) {
    colorLog(`构建交易失败: ${error.message}`, 'red')
    return null
  }
}

// 编码 ERC20 transfer 函数调用
function encodeERC20Transfer(to, amount) {
  // transfer(address,uint256) 的函数选择器
  const functionSelector = 'a9059cbb'
  
  // 编码参数
  const toPadded = to.slice(2).padStart(64, '0')
  const amountPadded = amount.toString(16).padStart(64, '0')
  
  return `0x${functionSelector}${toPadded}${amountPadded}`
}

// 3. 签名交易
async function signTransaction(transaction) {
  if (!walletClient || !account) {
    colorLog('请先生成钱包！', 'red')
    return null
  }
  
  try {
    colorLog('\n=== 签名交易 ===', 'cyan')
    
    const confirm = readlineSync.keyInYNStrict('确认签名此交易？')
    if (!confirm) {
      colorLog('交易已取消', 'yellow')
      return null
    }
    
    // 签名交易
    const signedTransaction = await walletClient.signTransaction(transaction)
    
    colorLog('交易签名成功！', 'green')
    colorLog(`签名: ${signedTransaction}`, 'blue')
    
    return signedTransaction
    
  } catch (error) {
    colorLog(`签名失败: ${error.message}`, 'red')
    return null
  }
}

// 4. 发送交易到 Sepolia 网络
async function sendTransaction(signedTransaction) {
  if (!signedTransaction) {
    colorLog('没有可发送的交易！', 'red')
    return
  }
  
  try {
    colorLog('\n=== 发送交易到 Sepolia ===', 'cyan')
    
    // 发送交易
    const hash = await publicClient.sendRawTransaction({
      serializedTransaction: signedTransaction
    })
    
    colorLog(`交易已发送！`, 'green')
    colorLog(`交易哈希: ${hash}`, 'blue')
    colorLog(`区块浏览器: https://sepolia.etherscan.io/tx/${hash}`, 'cyan')
    
    // 等待交易确认
    colorLog('\n等待交易确认...', 'yellow')
    const receipt = await publicClient.waitForTransactionReceipt({
      hash,
      timeout: 60000 // 60秒超时
    })
    
    if (receipt.status === 'success') {
      colorLog(`✅ 交易成功确认！`, 'green')
      colorLog(`区块号: ${receipt.blockNumber}`, 'blue')
      colorLog(`Gas 使用: ${receipt.gasUsed}`, 'blue')
    } else {
      colorLog(`❌ 交易失败`, 'red')
    }
    
  } catch (error) {
    colorLog(`发送交易失败: ${error.message}`, 'red')
  }
}

// 主菜单
function showMenu() {
  colorLog('\n' + '='.repeat(50), 'bright')
  colorLog('          基于 Viem.js 的命令行钱包', 'bright')
  colorLog('='.repeat(50), 'bright')
  colorLog('1. 生成新钱包', 'cyan')
  colorLog('2. 查询余额', 'cyan')
  colorLog('3. 构建 ERC20 转账交易', 'cyan')
  colorLog('4. 签名交易', 'cyan')
  colorLog('5. 发送交易到 Sepolia', 'cyan')
  colorLog('6. 一键完成 ERC20 转账', 'cyan')
  colorLog('0. 退出', 'red')
  colorLog('='.repeat(50), 'bright')
}

// 一键完成 ERC20 转账
async function completeERC20Transfer() {
  colorLog('\n=== 一键完成 ERC20 转账 ===', 'magenta')
  
  const transaction = await buildERC20Transfer()
  if (!transaction) return
  
  const signedTransaction = await signTransaction(transaction)
  if (!signedTransaction) return
  
  await sendTransaction(signedTransaction)
}

// 查询余额
async function checkBalance() {
  if (!account) {
    colorLog('请先生成钱包！', 'red')
    return
  }
  
  try {
    colorLog('\n=== 查询余额 ===', 'cyan')
    
    const ethBalance = await publicClient.getBalance({
      address: account.address
    })
    
    colorLog(`ETH 余额: ${formatEther(ethBalance)} ETH`, 'blue')
    
    // 查询 token 余额
    const tokenAddress = '0xdaD2f084F277b61A9d2fB2504d3c14afbE55F2D7'
    try {
      const tokenBalance = await publicClient.readContract({
        address: tokenAddress,
        abi: erc20Abi,
        functionName: 'balanceOf',
        args: [account.address]
      })
      
      const tokenDecimals = await publicClient.readContract({
        address: tokenAddress,
        abi: erc20Abi,
        functionName: 'decimals'
      })
      
      colorLog(`token 余额: ${formatUnits(tokenBalance, tokenDecimals)} MTE20`, 'blue')
    } catch (error) {
      colorLog('无法查询 token 余额', 'yellow')
    }
    
  } catch (error) {
    colorLog(`查询余额失败: ${error.message}`, 'red')
  }
}

// 主程序循环
async function main() {
  let currentTransaction = null
  
  while (true) {
    showMenu()
    
    const choice = readlineSync.question('请选择操作 (0-6): ')
    
    switch (choice) {
      case '1':
        await generateWallet()
        break
      case '2':
        await checkBalance()
        break
      case '3':
        currentTransaction = await buildERC20Transfer()
        break
      case '4':
        if (currentTransaction) {
          const signedTx = await signTransaction(currentTransaction)
          if (signedTx) {
            currentTransaction = signedTx
          }
        } else {
          colorLog('请先构建交易！', 'red')
        }
        break
      case '5':
        await sendTransaction(currentTransaction)
        currentTransaction = null
        break
      case '6':
        await completeERC20Transfer()
        currentTransaction = null
        break
      case '0':
        colorLog('感谢使用！', 'green')
        process.exit(0)
      default:
        colorLog('无效选择，请重试！', 'red')
    }
    
    readlineSync.keyInPause('\n按任意键继续...')
  }
}

// 启动程序
main().catch(console.error)
