// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Crowdunding {
    struct Campaign {
        string name;
        string description;
        uint goal;
        address payable beneficiary;
        mapping(address => uint) contributions;
        uint numContributors;
        State state;
        uint endAt; 
    }
    
    enum State {
        Fundraising,
        Failed,
        Successful,
        PaidOut
    }

    mapping(uint => Campaign) public campaigns;
    uint public numCampaigns;

    event ContributionReceived(uint campaignId, address contributor, uint amount, uint totalAmount);
    event CampaignFailed(uint campaignId, uint totalAmount);
    event CampaignSucceeded(uint campaignId, uint totalAmount);
    event CampaignPaidOut(uint campaignId);

    constructor() {}

    function createCampaign(string memory _name, string memory _description, uint _goal, address payable _beneficiary, uint _durationMinutes) public payable {
        uint campaignId = numCampaigns++;
        Campaign storage campaign = campaigns[campaignId];
        campaign.name = _name;
        campaign.description = _description;
        campaign.goal = _goal;
        campaign.beneficiary = _beneficiary;
        campaign.state = State.Fundraising;
        campaign.endAt = block.timestamp + (_durationMinutes * 60); 
    }

    function contribute(uint campaignId) public payable {
        require(campaignId < numCampaigns, "Invalid campaign ID.");
        
        Campaign storage campaign = campaigns[campaignId];
        require(campaign.state == State.Fundraising, "Campaign is not in Fundraising state.");
        require(msg.value > 0, "Contribution amount must be greater than zero.");

        campaign.contributions[msg.sender] += msg.value;
        campaign.numContributors++;

        emit ContributionReceived(campaignId, msg.sender, msg.value, address(this).balance);

        if (address(this).balance >= campaign.goal) {
            campaign.state = State.Successful;
            emit CampaignSucceeded(campaignId, address(this).balance);
        }
    }

    function checkCampaignStatus(uint campaignId) public {
        require(campaignId < numCampaigns, "Invalid campaign ID.");

        Campaign storage campaign = campaigns[campaignId];
        if (campaign.state == State.Fundraising && block.timestamp >= campaign.endAt) {
            campaign.state = State.Failed;
            emit CampaignFailed(campaignId, address(this).balance);
        }
    }

    function withdraw(uint campaignId) public payable  {
        require(campaignId < numCampaigns, "Invalid campaign ID.");

        Campaign storage campaign = campaigns[campaignId];
        require(campaign.state == State.Successful, "Campaign is not in Successful state.");
        require(msg.sender == campaign.beneficiary, "Only the beneficiary can withdraw the funds.");

        uint amount = address(this).balance;
        campaign.beneficiary.transfer(amount);

        campaign.state = State.PaidOut;
        emit CampaignPaidOut(campaignId);

    }

    fallback() external payable {
        
    }

}

