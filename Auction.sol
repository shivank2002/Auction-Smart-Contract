// SPDX-License-Identifier: GPL 3.0

pragma solidity >0.5.0 <0.9.0;

contract Action{
    address payable public auctioneer;
    uint public start_block=block.number;
    uint public end_block= 240+start_block;

   enum Auc_state {started, running, end, cancelled}
   Auc_state public auctionState;

   //uint public highest_bid;
   uint public highest_payable_bid;
   uint public bid_increament;

   address payable public highest_bidder;

   mapping(address=>uint) public bids;

   constructor(){
       auctioneer =payable(msg.sender);
       auctionState= Auc_state.running;
       bid_increament= 1 ether;
   }

   modifier notOwner(){
       require(msg.sender != auctioneer, "Owner can not bid");
       _;
   }

   modifier Owner(){
       require(msg.sender == auctioneer);
       _;
   }

   modifier started(){
       require(block.number > start_block);
       _;
   }

   modifier beforeEnding(){
       require(block.number<=end_block);
       _;
   }

   function cancelAuc() public Owner{
       auctionState = Auc_state.cancelled;
   }

    function endAuc() public Owner{
       auctionState = Auc_state.end;
   }

   function min(uint a, uint b) private pure returns(uint){
       if(a<=b){
           return a;
       }
       else 
       return b;
   }

   function bid() payable public notOwner started beforeEnding{
       require(auctionState == Auc_state.running);
       require(msg.value>=1 ether);

       uint currentBid = bids[msg.sender] + msg.value;

       require(currentBid > highest_payable_bid);

       bids[msg.sender] = currentBid;

       if(currentBid < bids[highest_bidder]){
           highest_payable_bid = min(currentBid + bid_increament, bids[highest_bidder]);
       }
       else{
           highest_payable_bid = min(currentBid, bids[highest_bidder]+bid_increament); 
           highest_bidder= payable(msg.sender);
       }
   }

   function finalizeAuction() public{
       require(auctionState == Auc_state.cancelled || auctionState == Auc_state.end || block.number> end_block);
       require(msg.sender == auctioneer || bids[msg.sender] >0);

       address payable person;
       uint value;

       if(auctionState == Auc_state.cancelled){
           person= payable(msg.sender);
           value = bids[msg.sender];
       }
       else{
           if(msg.sender == auctioneer){
               person = auctioneer;
               value = highest_payable_bid;
           }
           else{
               if(msg.sender == highest_bidder){
                   person = highest_bidder;
                   value = bids[highest_bidder] - highest_payable_bid;
               }
               else{
                   person = payable(msg.sender);
                   value = bids[msg.sender];
               }
           }
       }
       bids[msg.sender] =0;
       person.transfer(value);
   }

   function getbalance() public view returns(uint){
       require(msg.sender == auctioneer);
       return address(this).balance;
   }
}
