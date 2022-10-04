// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;  
import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

// https://lackadaisical-stone.surge.sh/
// deployer: 0x28f50dd8d51742333c6c86276663956f81956d6d 
// https://goerli.etherscan.io/address/0x573b596814deF4CFd3FFAC85Ac52B5c11f2e24a3
contract Staker {

  ExampleExternalContract public exampleExternalContract;

  mapping (address => uint256) public balances;

  uint256 public constant threshold = 1 ether;

  uint256 public deadline = block.timestamp + 72 hours;

  bool public openForWithdraw;

  event Stake(address staker, uint256 amount);

  // checks whether the external contract is completed
  modifier notCompleted() {
    bool completed = exampleExternalContract.completed();
    require(!completed, "Staking period has completed!");
    _;
  }

  // checks whether the required deadline has passed
  modifier deadlinePassed( bool requireDeadlinePassed) {
    uint256 timeRemaining = timeLeft();
    if (requireDeadlinePassed) {
      require(timeRemaining == 0, "Deadline has passed");
    } else {
      require(timeRemaining > 0, "Deadline has not passed yet");
    }
    _;
  }

  constructor(address exampleExternalContractAddress) {
      exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
  }

  // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
  // ( Make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )
  function stake() public payable deadlinePassed(false) notCompleted {    
    balances[msg.sender] += msg.value;
    emit Stake(msg.sender, msg.value);
  }

  //After some `deadline` allow anyone to call an `execute()` function
  // It should either call `exampleExternalContract.complete{value: address(this).balance()` to send all the value
  function execute() public notCompleted deadlinePassed(true) {
    uint256 contractBalance = address(this).balance;
    if (contractBalance >= threshold) {
      exampleExternalContract.complete{value: contractBalance}();
      } else {
            openForWithdraw = true;
      } 
  }
 // Add a `withdraw(address payable)` function lets users withdraw their balance
  function withdraw() public deadlinePassed(true) {
    require(openForWithdraw, "Not open for withdraw");
    uint256 userBalance = balances[msg.sender];
     require (userBalance > 0, "User has no deposits");
     balances[msg.sender] = 0;
     (bool success, ) = payable(msg.sender).call{value: userBalance}("");
     require (success, "Failed to send ether");
  } 

    // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
  function timeLeft() public view returns (uint256) {
    return block.timestamp >= deadline ? 0 : deadline - block.timestamp; 
  }

  // Add the `receive()` special function that receives eth and calls stake()
   receive() external payable {
      stake();
  }

}




