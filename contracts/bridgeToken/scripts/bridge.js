const Web3 = require('web3')

const BridgeEth = require('../build/contracts/BridgeEth.json');
const BridgeBsc = require('../build/contracts/BridgeBsc.json');

const web3Eth = new Web3('https://goerli.infura.io/v3/');
const web3Bsc = new Web3('https://data-seed-prebsc-1-s1.binance.org:8545');

const adminPrivKey = '';
const {address: admin} = web3Eth.eth.accounts.wallet.add(adminPrivKey);

const bridgeEth = web3Eth.eth.Contract(
    BridgeEth.abi,
    BridgeEth.networks['5'].address,
)
const bridgeBsc = web3Bsc.eth.Contract(
    BridgeBsc.abi,
    BridgeBsc.networks['97'].address,
)

bridgeEth.events.Transfer(
    {fromBlock: 0, step: 0}
  )
  .on('data', async event => {
    const { from, to, amount, date, nonce, signature } = event.returnValues;
  
    const tx = bridgeBsc.methods.mint(from, to, amount, nonce, signature);
    const [gasPrice, gasCost] = await Promise.all([
      web3Bsc.eth.getGasPrice(),
      tx.estimateGas({from: admin}),
    ]);
    const data = tx.encodeABI();
    const txData = {
      from: admin,
      to: bridgeBsc.options.address,
      data,
      gas: gasCost,
      gasPrice
    };
    const receipt = await web3Bsc.eth.sendTransaction(txData);
    console.log(`Transaction hash: ${receipt.transactionHash}`);
    console.log(`
      Processed transfer:
      - from ${from} 
      - to ${to} 
      - amount ${amount} tokens
      - date ${date}
      - nonce ${nonce}
    `);
  });
  