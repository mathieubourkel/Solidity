# Project 2 - Alyra Tests Voting

## Unit Tests
44 valid tests

All functions on this contract are tested and then all the requires

1 file: Voting.js

### 1) FUNCTION addVoter Tests
- should add a Voter, get registered
- should add a Voter, get event registered

### 2) FUNCTIONS addProposal/setVote/tallyVote tests
- should add a Proposal, check the description with getter
- should add a Proposal, check the voteCount at 0 with getter
- should add a Proposal, get event registered
- should get the Voter status to false
- should get the proposal voteCount at 0
- should set a Vote, check the voteCount at 1 with getter
- should get the Voter status to true
- should set a Vote, get event registered
- should check the count, get the winningProposalId (id: 1)

### 3) FUNCTIONS State change tests
- should check if status registering at start
- should change status and check if event is new status ProposalsRegistrationStarted
- should check if status ProposalsRegistrationStarted
- should change status and check if event is new status ProposalsRegistrationEnded
- should check if status ProposalsRegistrationEnded
- should change status and check if event is new status VotingSessionStarted
- should check if status VotingSessionStarted
- should change status and check if event is new status VotingSessionEnded
- should check if status VotingSessionEnded
- should change status and check if event is new status VotesTallied
- should check if status VotesTallied

### 4) REQUIRE "functionals" tests
- should check require Voter is not Registered
- should check require addProposal propose something
- should check setVote require use an existent proposal
- should check setVote require voter not already vote

### 5) REQUIRE Only VOTERS and OWNER tests
- should check only Voters can use the Getter Voter
- should check only Voters can use the Getter Proposal
- should check only Voters can use the Add Proposal
- should check only Voters can use the setVote
- should check only Owner can use the addVoter
- should check only Owner can startProposalsRegistering
- should check only Owner can endProposalsRegistering
- should check only Owner can startVotingSession
- should check only Owner can endVotingSession
- should check only Owner can tallyVotes

### 6) REQUIRE State change tests
- should check status require for endProposalsRegistering
- should check status require for StartVotingSession
- should check status require for endVotingSession
- should check status require for tallyVotes
- should check status require for addProposal
- should check status require for setVote
- should check status require for startProposalsRegistering
- should check status require for addVoter