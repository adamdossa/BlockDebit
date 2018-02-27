pragma solidity 0.4.15;

import '../installed_contracts/zeppelin/contracts/math/SafeMath.sol';
import '../installed_contracts/zeppelin/contracts/math/Math.sol';

contract BlockDebit {

  //If there is a withdrawal where subscriber is not up to date, or
  //you have reached the maxNumberOfPeriods, then contract is cancelled.

  event BlockDebitCreated(
    address indexed _serviceProvider,
    address indexed _subscriber,
    string _debitDescription,
    uint256 _startingBlock,
    uint256 _blocksInPeriod,
    uint256 _paymentAmount);
  event FundsDeposited(address indexed _serviceProvider, address indexed _subscriber, address indexed _depositor, uint256 _amount);
  event DebitTaken(address indexed _serviceProvider, address indexed _subscriber, uint256 _amount);
  event BlockDebitCancelled(address indexed _serviceProvider, address indexed _subscriber);
  event FundsWithdrawn(address indexed _serviceProvider, address indexed _subscriber, uint256 _amount);

  string public debitDescription;

  uint256 public deposited;
  uint256 public withdrawn;
  address public subscriber;
  address public serviceProvider;
  uint256 public paidUntilBlock;
  uint256 public blocksInPeriod;
  uint256 public paymentAmount;
  uint256 public numberOfWithdrawals;
  bool public cancelled;

  modifier notCancelled() {
    require(cancelled == false);
    _;
  }

  modifier onlySubscriber() {
    require(msg.sender == subscriber);
    _;
  }

  modifier onlyServiceProvider() {
    require(msg.sender == serviceProvider);
    _;
  }

  function BlockDebit(address _subscriber,
    address _serviceProvider,
    string _debitDescription,
    uint256 _blocksInPeriod,
    uint256 _paymentAmount) payable
  {
    //TODO: Validate inputs
    subscriber = _subscriber;
    serviceProvider = _serviceProvider;
    debitDescription = _debitDescription;
    blocksInPeriod = _blocksInPeriod;
    paymentAmount = _paymentAmount;
    paidUntilBlock = getBlockNumber();
    BlockDebitCreated(serviceProvider, subscriber, debitDescription, getBlockNumber(), blocksInPeriod, paymentAmount);
  }

  function depositFunds() payable notCancelled public {
    FundsDeposited(serviceProvider, subscriber, msg.sender, msg.value);
  }

  function pendingWithdrawal() constant public returns (uint256, uint256) {
    if (paidUntilBlock > getBlockNumber()) {
      return (0, 0);
    }
    uint256 blocksSincePaidUntil = SafeMath.sub(getBlockNumber(), paidUntilBlock);
    //We add one to this since payments are taken in advance for periods
    uint256 pendingPeriods = SafeMath.add(1, SafeMath.div(blocksSincePaidUntil, blocksInPeriod));
    uint256 pendingAmount = SafeMath.mul(pendingPeriods, paymentAmount);
    return (pendingPeriods, pendingAmount);
  }

  function currentBalance() constant public returns (uint256) {
    var (pendingPeriods, pendingAmount) = pendingWithdrawal();
    //pendingAmount could be greater than deposited, in which case we would return zero
    return SafeMath.sub(this.balance, pendingAmount);
  }

  function blockDebitValid() constant public returns (bool) {
    if (cancelled) {
      return false;
    }
    var (pendingPeriods, pendingAmount) = pendingWithdrawal();
    if (pendingAmount <= this.balance) {
      return true;
    } else {
      return false;
    }
  }

  function blockDebitArrears() constant public returns (uint256) {
    var (pendingPeriods, pendingAmount) = pendingWithdrawal();
    //Could be zero if account is in credit
    return SafeMath.sub(pendingAmount, this.balance);
  }

  function collectDebits() onlyServiceProvider notCancelled public {
    var (pendingPeriods, pendingAmount) = pendingWithdrawal();
    if (pendingAmount > this.balance) {
      //If we try and collect a debit payment, and there are insufficient funds, then the direct debit is cancelled
      cancelled = true;
      DebitTaken(serviceProvider, subscriber, this.balance);
      BlockDebitCancelled(serviceProvider, subscriber);
      serviceProvider.transfer(this.balance);
    } else {
      paidUntilBlock = SafeMath.add(paidUntilBlock, SafeMath.mul(pendingPeriods, blocksInPeriod));
      DebitTaken(serviceProvider, subscriber, pendingAmount);
      serviceProvider.transfer(pendingAmount);
    }
  }

  function withdraw(uint256 _amount) onlySubscriber notCancelled public {
    require(_amount <= currentBalance());
    subscriber.transfer(_amount);
  }

  function () payable {
    depositFunds();
  }

  function getBlockNumber() internal constant returns (uint256) {
    return block.number;
  }

}
