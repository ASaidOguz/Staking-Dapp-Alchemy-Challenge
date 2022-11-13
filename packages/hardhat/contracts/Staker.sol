// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;  //Do not change the solidity version as it negativly impacts submission grading

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";
import "../lib/Interest.sol";
contract Staker {
  //Using  DSMath and Interest packages for exponential interest calculation;
  

  ExampleExternalContract public exampleExternalContract;
   //Balance map keeps track of the balances ;
   mapping(address => uint256) public balances;
   //depositTimestamps map keeps track of when the transaction occurs;
   mapping(address => uint256) public depositTimestamps;  
   //whiteList map keeps staker addresses for whitelisting;
   mapping(address=>bool) public whiteList;
   //whitelisted contract addresses;
   mapping(address =>bool) public whitelistForContract;
  //Needed variables to make staking more realistic ;the names prove their work meta  
  uint256 public constant rewardRatePerBlock = 0.1 ether; 
  uint256 public withdrawalDeadline = block.timestamp +60 seconds; 
  uint256 public claimDeadline = block.timestamp + 70 seconds; 
  uint256 public currentBlock = 0;
  address  payable public  stakerContract = payable(address(this));
  
  //set your contract address 
  //Events ;
  event Stake(address indexed sender, uint256 amount); 
  event Received(address, uint); 
  event Execute(address indexed sender, uint256 amount);

    //modifier for WithdrawalTimeLeft;
    modifier withdrawalDeadlineReached( bool requireReached ) {
    uint256 timeRemaining = WithdrawalTimeLeft();
    if( requireReached ) {
      require(timeRemaining == 0, "Withdrawal period is not reached yet");
    } else {
      require(timeRemaining > 0, "Withdrawal period has been reached");
    }
    _;
  }
  //modifier for ClaimPeriodLeft;
  modifier claimDeadlineReached( bool requireReached ) {
    uint256 timeRemaining = ClaimPeriodLeft();
    if( requireReached ) {
      require(timeRemaining == 0, "Claim deadline is not reached yet");
    } else {
      require(timeRemaining > 0, "Claim deadline has been reached");
    }
    _;
  }
  //modifier for external contracts completed function;
  modifier notCompleted() {
    bool completed = exampleExternalContract.completed();
    require(!completed, "Stake already completed!");
    _;
  }

  constructor(address payable exampleExternalContractAddress) {
      exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
      
      whitelistForContract[stakerContract]=true;
  }

  modifier isInWhiteList()  {
    require(whiteList[msg.sender]==true,"You didnt even stake ETH!!");
    _;
  }
  //Simple timer using block time stamp and variable withdrawalTimeLeft;
  function WithdrawalTimeLeft() public view returns (uint256 withdrawalTimeLeft) {
    if( block.timestamp >= withdrawalDeadline) {
      return (0);
    } else {
      return (withdrawalDeadline - block.timestamp);
    }
  }
  //Simple timer using block time stamp and variable claimPeriodLeft;
  function ClaimPeriodLeft() public view returns (uint256 claimPeriodLeft) {
    if( block.timestamp >= claimDeadline) {
      return (0);
    } else {
      return (claimDeadline - block.timestamp);
    }
  }
  
  //In scaffold application;interaction wallet is not the owner !!!
  // Stake function for a user to stake ETH in our contract
  function stake() public payable withdrawalDeadlineReached(false) claimDeadlineReached(false) {
    balances[msg.sender] = balances[msg.sender] + msg.value;
    depositTimestamps[msg.sender] = block.timestamp;
    whiteList[msg.sender]=true;
    whitelistForContract[payable(stakerContract)]=true;
    emit Stake(msg.sender, msg.value);
  }

    /*
  Withdraw function for a user to remove their staked ETH inclusive
  of both the principle balance and any accrued interest
  */
  
  function withdraw() public withdrawalDeadlineReached(true) claimDeadlineReached(false) notCompleted isInWhiteList {
    require(balances[msg.sender] > 0, "You have no balance to withdraw!");
    
    uint256 indBalanceRewards = RewardsWithInterest(msg.sender);
    balances[msg.sender] = 0;

    // Transfer all ETH via call! (not transfer) cc: https://solidity-by-example.org/sending-ether
    (bool sent, bytes memory data) = msg.sender.call{value: indBalanceRewards}("");
    require(sent, "RIP; withdrawal failed :( ");
    
  }

  /*
   Interest calculator is calculating compound interest 
   */

  function RewardsWithInterest(address _staker) public returns(uint256 interest){
       
        Interest interestCalculator = new Interest();
        uint256 principal = balances[_staker];
        uint256 rate =interestCalculator.yearlyRateToRay(0.2 ether);//0.2 ether roughly %20 
        uint256 age=currentBlock;
        //block.timestamp-depositTimestamps[_staker];
         return interest=interestCalculator.accrueInterest(principal,rate,age);

        
  }
    /*
  Allows any user to repatriate "unproductive" funds that are left in the staking contract
  past the defined withdrawal period
  */
  
  function execute() public claimDeadlineReached(true) notCompleted {
    //uint256 contractBalance = address(this).balance;
    
    exampleExternalContract.complete{value: address(this).balance}();
  }
 
 /*
  pingpongEffect make pingpong transaction between storage (exampleContract) contract
  */
  function initiatePingpongEffect()public  isInWhiteList  {
       //exampleExternalContract.External(stakerContract);
       require(address(exampleExternalContract).balance>0,"There's no balance in External Contract");
       exampleExternalContract.pingPongeffect(stakerContract);
       
  }
  /*
  Time to "kill-time" on our local testnet
  */
  function killTime() public payable {
    currentBlock = 31536000 seconds;
  }
function CheckExampleContractBalance()public view returns( uint256 contractBalance ){
  return contractBalance=address(exampleExternalContract).balance;
  
}
  /*
  \Function for our smart contract to receive ETH
  cc: https://docs.soliditylang.org/en/latest/contracts.html#receive-ether-function
  */
  receive() external payable {
      emit Received(msg.sender, msg.value);
  }
 

}




 // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
  // ( Make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )


  // After some `deadline` allow anyone to call an `execute()` function
  // If the deadline has passed and the threshold is met, it should call `exampleExternalContract.complete{value: address(this).balance}()`


  // If the `threshold` was not met, allow everyone to call a `withdraw()` function to withdraw their balance


  // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend


  // Add the `receive()` special function that receives eth and calls stake()