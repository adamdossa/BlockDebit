pragma solidity 0.4.15;

import "../BlockDebit.sol";

contract BlockDebitMock is BlockDebit {

  event MockBlockNumber(uint256 _blockNumber);

  uint blockNumber = 0;

  function BlockDebitMock(address _subscriber,
    address _serviceProvider,
    string _debitDescription,
    uint256 _blocksInPeriod,
    uint256 _paymentAmount) payable
    BlockDebit(_serviceProvider, _subscriber, _debitDescription, _blocksInPeriod, _paymentAmount)
  {
  }

  function getBlockNumber() internal constant returns (uint256) {
      return blockNumber;
  }

  function setMockedBlockNumber(uint256 _blockNumber) public {
      blockNumber = _blockNumber;
      MockBlockNumber(blockNumber);
  }

}
