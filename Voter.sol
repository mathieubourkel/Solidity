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

    // Ajout du "VoteIsClosed" afin d'avoir un état par défaut du contract avant le commencement du vote puis à la fin
    enum WorkflowStatus { VoteIsClosed, RegisteringVoters, ProposalsRegistrationStarted,
                        ProposalsRegistrationEnded, VotingSessionStarted, 
                        VotingSessionEnded, VotesTallied }

    WorkflowStatus public status;

    // Tous les uint sont en uint16 (proposalId, voteCount..) pour un coût plus optimisé en gas
    uint16 winningProposalId;

    // Pas de mapping public car "chaque électeur peut voir les votes des autres" et non tout le monde
    mapping (address => Voter) whitelist;
    Proposal[] public proposals;

    // Events
    event VoterRegistered(address voterAddress); 
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);
    event ProposalRegistered(uint16 proposalId);
    event Voted (address voter, uint16 proposalId);

    // Permet de factoriser dans le code la vérification du status à chaque fonction
    modifier checkStatus(WorkflowStatus _status) {
        require(status == _status, "The administrator has not activate this function for now, please retry later");
        _;
    }

    // Permet de factoriser dans le code la vérification de l'enregistrement du votant
    modifier isRegistred(){
        require (whitelist[msg.sender].isRegistered == true, "You are not allowed to vote, access to the voter or propose something  on this election");
        _;
    }

    // Permet de factoriser dans le code la changement de status
    modifier nextStatus() {
        _;
        emit WorkflowStatusChange(status, WorkflowStatus(uint16(status) + 1));
        status = WorkflowStatus(uint16(status) + 1);
    }

    // Permet d'initier le début du vote et de la phase d'enregistrement des voters
    function startRegisteringVoters() external onlyOwner checkStatus(WorkflowStatus.VoteIsClosed) nextStatus{}

    // Permet à l'administrateur d'ajouter une addresse à la whitelist
    function addVoterToWhiteListe(address _address) external onlyOwner checkStatus(WorkflowStatus.RegisteringVoters){
        whitelist[_address] = Voter(true, false, 0);
        emit VoterRegistered(_address);
    }

    // L'admin commence la session d'enregistrement de la proposition en changeant le status en ProposalStarted
    function startProposalsRegistration() external onlyOwner checkStatus(WorkflowStatus.RegisteringVoters) nextStatus{}
    
    // Fonction de propositions
    function doProposal(string memory _description) external isRegistred checkStatus(WorkflowStatus.ProposalsRegistrationStarted){
        proposals.push(Proposal(_description, 0));
        emit ProposalRegistered(uint16(proposals.length - 1));
    }
    // FACULTATIF - Permet d'afficher toutes les propositions faites (peut etre faite n'importe quand afin de permettre 
    //aux électeurs de regarder plus facilement si qqn n'a pas fais la meme proposition qu'eux (plutot que par ID via le tableau)
    // ainsi que d'avoir le voteCount pour toutes les propositions d'un coup
    function getAllProposals() external view isRegistred returns(Proposal[] memory LISTE){
        return proposals;
    }

    // Fin des propositions; Début de la session de vote
    function endProposalsRegistration() external onlyOwner checkStatus(WorkflowStatus.ProposalsRegistrationStarted) nextStatus{}
    function startVotingSession() external onlyOwner checkStatus(WorkflowStatus.ProposalsRegistrationEnded) nextStatus{}

    // Fonction permettant aux électeurs inscrits de voter une fois
    function doVote(uint16 _proposalId) external isRegistred checkStatus(WorkflowStatus.VotingSessionStarted){
        require (whitelist[msg.sender].hasVoted == false, "You have already voted");
        proposals[_proposalId].voteCount++;
        whitelist[msg.sender].hasVoted = true;
        whitelist[msg.sender].votedProposalId = _proposalId;
        emit Voted(msg.sender, _proposalId);
    }

    // Permet à seulement les électeurs de connaître le vote d'un Voter et de savoir si il a voté
    function getInfoVoter(address _address) external isRegistred view returns(bool VOTED, uint ID){
        return (whitelist[_address].hasVoted, whitelist[_address].votedProposalId); 
    }

    function endVotingSession() external onlyOwner checkStatus(WorkflowStatus.VotingSessionStarted) nextStatus{}

    // L'admin comptabilise les votes et change le status en VotesTallied
    function talliedVoting() external onlyOwner checkStatus(WorkflowStatus.VotingSessionEnded) nextStatus{
        // Evite d'agir sur une variable de stockage dans la blockchain
        uint16 tempIdProposal;
        // Parcours le tableau des propositions; et pour chaque élement vérifié cela modifie la variable si il y a un VoteCount supérieur
        for (uint16 i = 0; i < proposals.length; i++) {  
            if (proposals[i].voteCount > proposals[tempIdProposal].voteCount){
                tempIdProposal = i;
            }
        }
        winningProposalId = tempIdProposal;
    }

    // Tout le monde peut accéder aux résultats du vote lorsque le compte est terminé (status VoteIsClosed)
    function getWinner() external view checkStatus(WorkflowStatus.VotesTallied) returns(uint16 ID, string memory NAME, uint16 COUNT){
        return (winningProposalId, proposals[winningProposalId].description, proposals[winningProposalId].voteCount);
    }

    // FACULTATIF - Permet de clôturer le vote si besoin en le rabsculant dans son état par défaut (VoteIsClosed)
    function closeTheVote() external onlyOwner checkStatus(WorkflowStatus.VotesTallied) {  
        emit WorkflowStatusChange(status, WorkflowStatus.VoteIsClosed);
        status = WorkflowStatus.VoteIsClosed;
    }
}
