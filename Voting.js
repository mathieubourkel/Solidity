const Voting = artifacts.require("./Voting.sol");
const { BN, expectRevert, expectEvent } = require('@openzeppelin/test-helpers');
const { expect } = require('chai');

contract('Voters', accounts => {
    const owner = accounts[0];
    const second = accounts[1];
    const third = accounts[2];

    let VotingInstance;

    describe("FUNCTION addVoter tests", function () {

        before(async function () {
            VotingInstance = await Voting.new({from:owner});
        });

        it("should add a Voter, get registered", async () => {
            await VotingInstance.addVoter(owner, { from: owner });
            const storedData = await VotingInstance.getVoter(owner);
            expect(storedData.isRegistered).to.be.true;
        });

        it("should add a Voter, get event registered", async () => {
            const findEvent = await VotingInstance.addVoter(third, { from: owner });
            expectEvent(findEvent, "VoterRegistered", {voterAddress: third});
        });
    });

    describe("FUNCTIONS addProposal/SetVote/TallyVote tests", function () {

        before(async function () {
            VotingInstance = await Voting.new({from:owner});
            await VotingInstance.addVoter(owner, { from: owner });
            await VotingInstance.addVoter(second, { from: owner });
            await VotingInstance.addVoter(third, { from: owner });
            await VotingInstance.startProposalsRegistering({ from: owner });
        });

        it("should add a Proposal, check the description with getter", async () => {
            await VotingInstance.addProposal("John", { from: owner });
            const storedData = await VotingInstance.getOneProposal(0);
            expect(storedData.description).to.equal("John");
        });

        it("should add a Proposal, check the voteCount at 0 with getter", async () => {
            await VotingInstance.addProposal("Doe", { from: owner });
            const storedData = await VotingInstance.getOneProposal(1);
            expect(new BN(storedData.voteCount)).to.be.bignumber.equal(new BN(0));
        });

        it("should add a Proposal, get event registered", async () => {
            const findEvent = await VotingInstance.addProposal("Bob", { from: owner });
            expectEvent(findEvent, "ProposalRegistered", {proposalId: new BN(2)});
        });

        it("should get the Voter status to false", async () => {
            const storedData = await VotingInstance.getVoter(owner);
            expect(storedData.hasVoted).to.be.false;
        });

        it("should get the proposal voteCount at 0", async () => {
            const storedData = await VotingInstance.getOneProposal(0);
            expect(new BN(storedData.voteCount)).to.be.bignumber.equal(new BN(0));
        });

        it("should set a Vote, check the voteCount at 1 with getter", async () => {
            await VotingInstance.endProposalsRegistering({ from: owner });
            await VotingInstance.startVotingSession({ from: owner });
            await VotingInstance.setVote(1, { from: owner });
            const storedData = await VotingInstance.getOneProposal(1);
            expect(new BN(storedData.voteCount)).to.be.bignumber.equal(new BN(1));
        });

        it("should get the Voter status to true", async () => {
            const storedData = await VotingInstance.getVoter(owner);
            expect(storedData.hasVoted).to.be.true;
        });

        it("should set a Vote, get event registered", async () => {
            const findEvent = await VotingInstance.setVote(1, { from: second });
            expectEvent(findEvent, "Voted", {voter: second, proposalId: new BN(1)});
        });

        it("should check the count, get the winningProposalId (id: 1)", async () => {
            await VotingInstance.endVotingSession({ from: owner });
            await VotingInstance.tallyVotes({ from: owner });
            const storedData = await VotingInstance.winningProposalID();
            expect(new BN(storedData)).to.be.bignumber.equal(new BN(1));
        });

    });

    describe("FUNCTIONS State Change tests", function () {

        before(async function () {
            VotingInstance = await Voting.new({from:owner}); 
        });

        it("should check if status registering at start", async () => {
            const storedData = await VotingInstance.workflowStatus();
            expect(new BN(storedData)).to.be.bignumber.equal(new BN(0));
        });

        it("should change status and check if event is new status ProposalsRegistrationStarted", async () => {
            const findEvent = await VotingInstance.startProposalsRegistering({ from: owner });
            expectEvent(findEvent, "WorkflowStatusChange", {previousStatus: new BN(0), newStatus: new BN(1)});
        });

        it("should check if status ProposalsRegistrationStarted", async () => {   
            const storedData = await VotingInstance.workflowStatus();
            expect(new BN(storedData)).to.be.bignumber.equal(new BN(1));
        });

        it("should change status and check if event is new status ProposalsRegistrationEnded", async () => {
            const findEvent = await VotingInstance.endProposalsRegistering({ from: owner });
            expectEvent(findEvent, "WorkflowStatusChange", {previousStatus: new BN(1), newStatus: new BN(2)});
        });

        it("should check if status ProposalsRegistrationEnded", async () => {
            const storedData = await VotingInstance.workflowStatus();
            expect(new BN(storedData)).to.be.bignumber.equal(new BN(2));
        });

        it("should change status and check if event is new status VotingSessionStarted", async () => {
            const findEvent = await VotingInstance.startVotingSession({ from: owner });
            expectEvent(findEvent, "WorkflowStatusChange", {previousStatus: new BN(2), newStatus: new BN(3)});
        });

        it("should check if status VotingSessionStarted", async () => {
            const storedData = await VotingInstance.workflowStatus();
            expect(new BN(storedData)).to.be.bignumber.equal(new BN(3));
        });

        it("should change status and check if event is new status VotingSessionEnded", async () => {
            const findEvent = await VotingInstance.endVotingSession({ from: owner });
            expectEvent(findEvent, "WorkflowStatusChange", {previousStatus: new BN(3), newStatus: new BN(4)});
        });

        it("should check if status VotingSessionEnded", async () => {
            const storedData = await VotingInstance.workflowStatus();
            expect(new BN(storedData)).to.be.bignumber.equal(new BN(4));
        });

        it("should change status and check if event is new status VotesTallied", async () => {
            const findEvent = await VotingInstance.tallyVotes({ from: owner });
            expectEvent(findEvent, "WorkflowStatusChange", {previousStatus: new BN(4), newStatus: new BN(5)});
        });

        it("should check if status VotesTallied", async () => {
            const storedData = await VotingInstance.workflowStatus();
            expect(new BN(storedData)).to.be.bignumber.equal(new BN(5));
        });

    });

    describe("REQUIRE Functional tests", function () {

        before(async function () {
            VotingInstance = await Voting.new({from:owner});
            await VotingInstance.addVoter(second, { from: owner });
        });

        it("should check require Voter is not Registered", async () => {
            await expectRevert(VotingInstance.addVoter(second, { from: owner }), "Already registered");
        });

        it("should check require addProposal propose something", async () => {
            await VotingInstance.startProposalsRegistering({ from: owner });
            await expectRevert(VotingInstance.addProposal("", { from: second }), "Vous ne pouvez pas ne rien proposer");
        });

        it("should check setVote require use an existent proposal", async () => {
            await VotingInstance.addProposal("John", { from: second });
            await VotingInstance.endProposalsRegistering({ from: owner });
            await VotingInstance.startVotingSession({ from: owner });   
            await expectRevert(VotingInstance.setVote(5, { from: second }), "Proposal not found");
        });

        it("should check setVote require voter not already vote", async () => {
            await VotingInstance.setVote(0, { from: second })
            await expectRevert(VotingInstance.setVote(0, { from: second }), "You have already voted");
        });

    });

    describe("REQUIRE Only VOTERS and OWNER", function () {

        before(async function () {
            VotingInstance = await Voting.new({from:owner});
            await VotingInstance.addVoter(second, { from: owner });
        });

        it("should check only Voters can use the Getter Voter", async () => {
            await expectRevert(VotingInstance.getVoter(owner, { from: owner }), "You're not a voter");
        });

        it("should check only Voters can use the Getter Proposal", async () => {
            await expectRevert(VotingInstance.getOneProposal(0, { from: owner }), "You're not a voter");
        });

        it("should check only Voters can use the Add Proposal", async () => {
            await expectRevert(VotingInstance.addProposal("Momo", { from: owner }), "You're not a voter");
        });

        it("should check only Voters can use the setVote", async () => {
            await expectRevert(VotingInstance.setVote(0, { from: owner }), "You're not a voter");
        });

        it("should check only Owner can use the addVoter", async () => {
            await expectRevert(VotingInstance.addVoter(third, { from: second }), "caller is not the owner");
        });

        it("should check only Owner can startProposalsRegistering", async () => {
            await expectRevert(VotingInstance.startProposalsRegistering({ from: second }), "caller is not the owner");
        });

        it("should check only Owner can endProposalsRegistering", async () => {
            await expectRevert(VotingInstance.endProposalsRegistering({ from: second }), "caller is not the owner");
        });

        it("should check only Owner can startVotingSession", async () => {
            await expectRevert(VotingInstance.startVotingSession({ from: second }), "caller is not the owner");
        });

        it("should check only Owner can endVotingSession", async () => {
            await expectRevert(VotingInstance.endVotingSession({ from: second }), "caller is not the owner");
        });

        it("should check only Owner can tallyVotes", async () => {
            await expectRevert(VotingInstance.tallyVotes({ from: second }), "caller is not the owner");
        });
    });

    describe("REQUIRE State Change tests", function () {

        before(async function () {
            VotingInstance = await Voting.new({from:owner});
            await VotingInstance.addVoter(owner, { from: owner });
        });
       
        it("should check status require for endProposalsRegistering", async () => {
            await expectRevert(VotingInstance.endProposalsRegistering({ from: owner }), "Registering proposals havent started yet");
        });

        it("should check status require for StartVotingSession", async () => {
            await expectRevert(VotingInstance.startVotingSession({ from: owner }), "Registering proposals phase is not finished");
        });

        it("should check status require for endVotingSession", async () => {
            await expectRevert(VotingInstance.endVotingSession({ from: owner }), "Voting session havent started yet");
        });

        it("should check status require for tallyVotes", async () => {
            await expectRevert(VotingInstance.tallyVotes({ from: owner }), "Current status is not voting session ended");
        });

        it("should check status require for addProposal", async () => {
            await expectRevert(VotingInstance.addProposal("Rick", { from: owner }), "Proposals are not allowed yet");
        });

        it("should check status require for setVote", async () => {
            await expectRevert(VotingInstance.setVote(0, { from: owner }), "Voting session havent started yet");
        });

        it("should check status require for startProposalsRegistering", async () => {
            await VotingInstance.startProposalsRegistering({ from: owner });
            await expectRevert(VotingInstance.startProposalsRegistering({ from: owner }), "Registering proposals cant be started now");
        });

        it("should check status require for addVoter", async () => {
            await expectRevert(VotingInstance.addVoter(second, { from: owner }), "Voters registration is not open yet");
        });
    
    });
});

