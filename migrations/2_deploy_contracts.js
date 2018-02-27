var BlockDebitFactory = artifacts.require("./BlockDebitFactory.sol");

module.exports = function(deployer) {
  deployer.deploy(BlockDebitFactory);
};
