pragma solidity 0.4.15;

import '../installed_contracts/zeppelin/contracts/math/SafeMath.sol';
import '../installed_contracts/zeppelin/contracts/math/Math.sol';
import '../installed_contracts/zeppelin/contracts/ownership/Ownable.sol';
import './BlockDebit.sol';

contract BlockDebitFactory is Ownable {

  address public owner;

  mapping (address => address[]) public subscriberDebits;
  mapping (address => address[]) public serviceProviderDebits;
  mapping (address => uint256) public successfullDebits;

  function BlockDebitFactory() {
    owner = msg.sender;
  }

  function createBlockDebit(address _subscriber,
    address _serviceProvider,
    string _debitDescription,
    uint256 _blocksInPeriod,
    uint256 _paymentAmount)
  {
    BlockDebit newBlockDebit = new BlockDebit(_subscriber, _serviceProvider, _debitDescription, _blocksInPeriod, _paymentAmount);
    subscriberDebits[_subscriber].push(address(newBlockDebit));
    serviceProviderDebits[_serviceProvider].push(address(newBlockDebit));
  }

  function getSubscriberDebitsLength(address _serviceProvider) constant returns (uint256) {
    return serviceProviderDebits[_serviceProvider].length;
  }

  function getServiceProviderDebitsLength(address _subscriber) constant returns (uint256) {
    return subscriberDebits[_subscriber].length;
  }

  function collectDebitsUntil(uint256 _until) public {
    for (uint256 i = successfullDebits[msg.sender]; i < _until; i++) {
      BlockDebit blockDebit = BlockDebit(serviceProviderDebits[msg.sender][i]);
      if (blockDebit.cancelled() != false) {
        blockDebit.collectDebits();
      }
    }
    successfullDebits[msg.sender] = i;
  }

  function collectDebitsAll() public {
    collectDebitsUntil(serviceProviderDebits[msg.sender].length);
  }

}
