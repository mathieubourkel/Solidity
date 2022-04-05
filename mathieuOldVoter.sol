//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;
import "@openzeppelin/contracts/access/Ownable.sol";

contract Voting is Ownable {

    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint16 votedProposalId;
    }
    struct Proposal {
        string description;
        uint16 voteCount;
    }

    // Add "VoteIsClosed" to have a default state of the contract before the beggining and at the the end
    enum WorkflowStatus { VoteIsClosed, RegisteringVoters, ProposalsRegistrationStarted,
                        ProposalsRegistrationEnded, VotingSessionStarted, 
                        VotingSessionEnded, VotesTallied }

    WorkflowStatus public status;

    // All of uint in uint16 to have a low coast gas
    uint16 winningProposalId;

    // No public mapping because just the voters can acces to the vote information not "everyone"
    mapping (address => Voter) whitelist;
    Proposal[] public proposals;

    // Events
    event VoterRegistered(address voterAddress); 
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);
    event ProposalRegistered(uint16 proposalId);
    event Voted (address voter, uint16 proposalId);

    // Factorize in the code the function for checking the status
    modifier checkStatus(WorkflowStatus _status) {
        require(status == _status, "The administrator has not activate this function for now, please retry later");
        _;
    }

    // Factorize in the code the check of the registering of the voter
    modifier isRegistred(){
        require (whitelist[msg.sender].isRegistered == true, "You are not allowed to vote, access to the voter or propose something  on this election");
        _;
    }

    // Factorize in the code the access of the next status
    modifier nextStatus() {
        _;
        emit WorkflowStatusChange(status, WorkflowStatus(uint16(status) + 1));
        status = WorkflowStatus(uint16(status) + 1);
    }

    // Initiate the registering of the voters
    function startRegisteringVoters() external onlyOwner checkStatus(WorkflowStatus.VoteIsClosed) nextStatus{}

    // Administrator can add an address to the whitelist
    function addVoterToWhiteListe(address _address) external onlyOwner checkStatus(WorkflowStatus.RegisteringVoters){
        whitelist[_address] = Voter(true, false, 0);
        emit VoterRegistered(_address);
    }

    function startProposalsRegistration() external onlyOwner checkStatus(WorkflowStatus.RegisteringVoters) nextStatus{}
    
    // Everyone on the whitelist can make some proposals
    function doProposal(string memory _description) external isRegistred checkStatus(WorkflowStatus.ProposalsRegistrationStarted){
        proposals.push(Proposal(_description, 0));
        emit ProposalRegistered(uint16(proposals.length - 1));
    }
    // OPTIONAL - Display all of the proposals easily than one-by-one with the ID of the proposal
    function getAllProposals() external view isRegistred returns(Proposal[] memory LISTE){
        return proposals;
    }

    function endProposalsRegistration() external onlyOwner checkStatus(WorkflowStatus.ProposalsRegistrationStarted) nextStatus{
        // OPTIONAL - Need 1 proposal to get next step
        require(proposals.length > 0, "No proposals has been sent, please inform your voters to make some proposals");
    }
    
    function startVotingSession() external onlyOwner checkStatus(WorkflowStatus.ProposalsRegistrationEnded) nextStatus{}

    // Voters on the whitelist can make one vote for a proposal
    function doVote(uint16 _proposalId) external isRegistred checkStatus(WorkflowStatus.VotingSessionStarted){
        require (whitelist[msg.sender].hasVoted == false, "You have already voted");
        proposals[_proposalId].voteCount++;
        whitelist[msg.sender].hasVoted = true;
        whitelist[msg.sender].votedProposalId = _proposalId;
        emit Voted(msg.sender, _proposalId);
    }

    // Function for all of the voters to have access of the vote of every other voters
    function getInfoVoter(address _address) external isRegistred view returns(bool VOTED, uint ID){
        return (whitelist[_address].hasVoted, whitelist[_address].votedProposalId); 
    }

    function endVotingSession() external onlyOwner checkStatus(WorkflowStatus.VotingSessionStarted) nextStatus{
        // OPTIONAL - Need 1 vote to go to the next step
        uint16 tempCountVoters;
        for (uint16 i = 0; i < proposals.length; i++) {
            tempCountVoters += proposals[i].voteCount;
        }
        require(tempCountVoters > 0, "Nobody has voted, please inform yours voters to do something");
    }

    // Administrator use this function to count the votes and give access to the result to everyone
    function talliedVoting() external onlyOwner checkStatus(WorkflowStatus.VotingSessionEnded) nextStatus{
        // No using storage variable but temp variable (low coast gas)
        uint16 tempIdProposal;
        // Iterating on the array to find the winner of the vote by comparing the bigest value to the next one
        for (uint16 i = 0; i < proposals.length; i++) {  
            if (proposals[i].voteCount > proposals[tempIdProposal].voteCount){
                tempIdProposal = i;
            }
        }
        winningProposalId = tempIdProposal;
    }

    // Everyone can access to the result of the vote wth all of the details
    function getWinner() external view checkStatus(WorkflowStatus.VotesTallied) returns(uint16 ID, string memory NAME, uint16 COUNT){
        return (winningProposalId, proposals[winningProposalId].description, proposals[winningProposalId].voteCount);
    }

    // OPTIONAL - Closing the vote by switching the status to the default state (no more access to the result after that)
    function closeTheVote() external onlyOwner checkStatus(WorkflowStatus.VotesTallied) {  
        emit WorkflowStatusChange(status, WorkflowStatus.VoteIsClosed);
        status = WorkflowStatus.VoteIsClosed;
    }
}
