const TokenEth = artifacts.require('./TokenEth.sol');

module.exports = async done => {
  const [recipient, _] = await web3.eth.getAccounts();
  const tokenEth = await TokenEth.deployed();
  const balance = await tokenEth.balanceOf(recipient);
  console.log(balance.toString());
  done();
}