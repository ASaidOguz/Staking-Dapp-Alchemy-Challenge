// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;  //Do not change the solidity version as it negativly impacts submission grading
import "./Staker.sol";
contract ExampleExternalContract {
  
  bool public completed;
  
  Staker public staker ;
 
  address owner=0x631A2132B5BC88b6eeE15c04AfD1C322e8C66a3A;
  
  event Received(address, uint); 
  
  function complete() public payable {
    completed = true;
  }
function External(address payable addr) public {
    require(owner==msg.sender,"You are not the owner!!");
    staker= Staker(addr);
  }
  function pingPongeffect(address payable stakerContract)external{
    //Validation for whitelisted contracts...
    require(staker.whitelistForContract(stakerContract)==true,"Contract is not whitelisted!!");
    //Sending eth to validated stake contract... 
    (bool sent, bytes memory data)= stakerContract.call{value: address(this).balance}("");
    
    require(sent,"RIP failed transaction");
    completed=false;
  }
  /*
  \Function for our smart contract to receive ETH
  cc: https://docs.soliditylang.org/en/latest/contracts.html#receive-ether-function
  */
  receive() external payable {
      emit Received(msg.sender, msg.value);
  }
  


}
