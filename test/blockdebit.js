const assertFail = require("./helpers/assertFail");

const BlockDebit = artifacts.require("./BlockDebitMock.sol");
const BlockDebitFactory = artifacts.require("./BlockDebitFactory.sol");

contract('BlockDebit', function (accounts) {

  var blockDebitFactory;
  var arbitration;
  var serviceProvider = accounts[1];
  var subscriber = accounts[2];
  var ETHER = 1000000000000000000;

  before(async function() {
    blockDebitFactory = await BlockDebitFactory.new({from: accounts[0]});
    console.log("BlockDebitFactory address: " + blockDebitFactory.address);
    console.log("Subscriber address: " + subscriber);
    console.log("ServiceProvider address: " + serviceProvider);
  });

  // =========================================================================
  it("0. initialises block debit and checks basic functions", async () => {

    await blockDebitFactory.createBlockDebit(subscriber, serviceProvider, "first test debit", 5, 5 * ETHER, {from: accounts[0]});
    var blockDebitAddress = await blockDebitFactory.getSubscriberDebit(subscriber, 0);
    console.log("BlockDebit Address: " + blockDebitAddress);

  });

});
