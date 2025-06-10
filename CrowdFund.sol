// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0<0.9.0;

contract Crowdfunding
{
    mapping(address=>uint) public contributors;
    address public manager;
    uint public minContribution;
    uint public deadline;
    uint public target;
    uint public raisedAmount;
    uint public noOfContributors;

    struct Request{
        string description;
        address payable recipent;
        uint value;
        bool completed;
        uint noOfvoters;
        mapping(address=>bool) voters;
    }
    mapping(uint=>Request) public request;
    uint public numRequests;

    constructor(uint _target,uint _deadline)
    {
        target=_target;
        deadline=block.timestamp+_deadline;
        manager=msg.sender;
        minContribution=100 wei;

    }
    function sendEth() public payable {
        require(block.timestamp<deadline,"Deadline has passed");
        require(msg.value>=minContribution,"Minimum contribution is not met");

        if(contributors[msg.sender]==0){
            noOfContributors++;
        }
        contributors[msg.sender]+=msg.value;
        raisedAmount+=msg.value;
    }
    function getBalance() public view returns (uint){
        return address(this).balance;
    }
    function refund() public {
        require(block.timestamp>deadline && raisedAmount<target,"You can't take the refund");
        require(contributors[msg.sender]>0);
        address payable user=payable(msg.sender);
        user.transfer(contributors[msg.sender]);
        contributors[msg.sender]=0;
    }
    modifier onlyManager(){
        require(msg.sender==manager,"Only manger can call this function");
        _;
    }
    function createRequest(string memory _description,address payable _recipent,uint _value) public onlyManager{
        Request storage newrequest=request[numRequests];
        numRequests++;
        newrequest.description=_description;
        newrequest.recipent=_recipent;
        newrequest.value=_value;
        newrequest.completed=false;
        newrequest.noOfvoters=0;
    }
    function voteRequest(uint _requestNo) public {
        require(contributors[msg.sender]>0,"You must be a contributor");
        Request storage thisRequest=request[_requestNo];
        require(thisRequest.voters[msg.sender]==false,"You have already voted");
        thisRequest.voters[msg.sender]=true;
        thisRequest.noOfvoters++;
    }
    function makePayment(uint _requestNo) public  onlyManager{
        require(raisedAmount>target);
        Request storage thisRequest=request[_requestNo];
        require(thisRequest.completed==false,"The request has been completed");
        require(thisRequest.noOfvoters>noOfContributors/2,"Majority does not support");
        thisRequest.recipent.transfer(thisRequest.value);
        thisRequest.completed=true;
    }
}