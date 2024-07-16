// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

contract Election {
    address payable public owner;

    struct Voter {
        uint256 id;
        string name;
        string email;
        bool hasVoted;
        bytes32 passwordHash;
        uint256 lastUpdated; // Timestamp of the last update
        bool isActive; // To mark if a voter is active
        bytes32 transactionHash;
        uint256 blockNumber;
    }

    struct Candidate {
        uint256 id;
        string name;
        string visi;
        string misi;
        uint256 voteCount;
        uint256 lastUpdated; // Timestamp of the last update
        bool isActive; // To mark if a voter is active
        bytes32 transactionHash;
        uint256 blockNumber;
    }

    struct VoterHistory {
        uint256 id;
        string name;
        string email;
        bool hasVoted;
        bytes32 passwordHash;
        uint256 timestamp;
        bytes32 transactionHash;
        uint256 blockNumber;
    }

    struct CandidateHistory {
        uint256 id;
        string name;
        string visi;
        string misi;
        uint256 voteCount;
        uint256 timestamp;
        bytes32 transactionHash;
        uint256 blockNumber;
    }

    struct VoteCountHistory {
        uint256 candidateId;
        uint256 voteCount;
        uint256 timestamp;
        bytes32 transactionHash;
        uint256 blockNumber;
    }

    event VoterAdded(uint256 id, string name);
    event VoterUpdated(uint256 id, string name);
    event VoterDeleted(uint256 id, string name);
    event CandidateAdded(uint256 id, string name);
    event CandidateUpdated(uint256 id, string name);
    event CandidateDeleted(uint256 id, string name);
    event ElectionEnded();

    bool public electionActive;
    uint256[] public voterIds;
    uint256[] public candidateIds;

    mapping(uint256 => Voter) public voters;
    mapping(uint256 => Candidate) public candidates;
    mapping(uint256 => VoterHistory[]) public voterHistories;
    mapping(uint256 => CandidateHistory[]) public candidateHistories;
    mapping(uint256 => VoteCountHistory[]) public voteCountHistories;

    modifier onlyActiveElection() {
        require(electionActive, "Election is not active");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only contract owner can call this function");
        _;
    }

    constructor() {
        owner = payable(msg.sender);
        electionActive = true;
    }

    function addVoter(uint256 _id, string memory _name, string memory _email, string memory _password) public onlyOwner {
        require(voters[_id].id == 0, "Voter already registered");

        voters[_id] = Voter({
            id: _id,
            name: _name,
            email: _email,
            hasVoted: false,
            passwordHash: keccak256(abi.encodePacked(_password)),
            lastUpdated: block.timestamp,
            isActive: true,
            transactionHash: blockhash(block.number - 1),
            blockNumber: block.number

        });

        voterIds.push(_id);
        emit VoterAdded(_id, _name);
    }

    function updateVoter(uint256 _id, string memory _name, string memory _email, string memory _password) public onlyOwner {
        require(voters[_id].id != 0, "Voter not registered");

        // Record the current state to history before updating
        voterHistories[_id].push(VoterHistory({
            id: _id,
            name: voters[_id].name,
            email: voters[_id].email,
            hasVoted: voters[_id].hasVoted,
            passwordHash: voters[_id].passwordHash,
            timestamp: block.timestamp,
            transactionHash: blockhash(block.number - 1),
            blockNumber: block.number
        }));

        voters[_id].name = _name;
        voters[_id].email = _email;
        voters[_id].passwordHash = keccak256(abi.encodePacked(_password));
        voters[_id].lastUpdated = block.timestamp;
        voters[_id].transactionHash = blockhash(block.number - 1);
        voters[_id].blockNumber = block.number;

        emit VoterUpdated(_id, _name);
    }

    function deleteVoter(uint256 _id) public onlyOwner {
        require(voters[_id].id != 0, "Voter not registered");

        // Record the current state to history before deleting
        voterHistories[_id].push(VoterHistory({
            id: _id,
            name: voters[_id].name,
            email: voters[_id].email,
            hasVoted: voters[_id].hasVoted,
            passwordHash: voters[_id].passwordHash,
            timestamp: block.timestamp,
            transactionHash: blockhash(block.number - 1),
            blockNumber: block.number
        }));

        voters[_id].isActive = false; // Mark voter as inactive instead of deleting

        emit VoterDeleted(_id, voters[_id].name);
    }

    function addCandidate(uint256 _id, string memory _name, string memory _visi, string memory _misi) public onlyOwner {
        require(candidates[_id].id == 0, "Candidate already exists");

        candidates[_id] = Candidate({
            id: _id,
            name: _name,
            visi: _visi,
            misi: _misi,
            voteCount: 0,
            lastUpdated: block.timestamp,
            isActive: true,
            transactionHash: blockhash(block.number - 1),
            blockNumber: block.number
        });

        candidateIds.push(_id);
        emit CandidateAdded(_id, _name);
    }

    function updateCandidate(uint256 _id, string memory _name, string memory _visi, string memory _misi) public onlyOwner {
        require(candidates[_id].id != 0, "Candidate not registered");

        // Record the current state to history before updating
        candidateHistories[_id].push(CandidateHistory({
            id: _id,
            name: candidates[_id].name,
            visi: candidates[_id].visi,
            misi: candidates[_id].misi,
            voteCount: candidates[_id].voteCount,
            timestamp: block.timestamp,
            transactionHash: blockhash(block.number - 1),
            blockNumber: block.number
        }));

        candidates[_id].name = _name;
        candidates[_id].visi = _visi;
        candidates[_id].misi = _misi;
        candidates[_id].lastUpdated = block.timestamp;
        candidates[_id].transactionHash = blockhash(block.number - 1);
        candidates[_id].blockNumber = block.number;

        emit CandidateUpdated(_id, _name);
    }

    function deleteCandidate(uint256 _id) public onlyOwner {
        require(candidates[_id].id != 0, "Candidate not registered");

        // Record the current state to history before marking as inactive
        candidateHistories[_id].push(CandidateHistory({
            id: _id,
            name: candidates[_id].name,
            visi: candidates[_id].visi,
            misi: candidates[_id].misi,
            voteCount: candidates[_id].voteCount,
            timestamp: block.timestamp,
            transactionHash: blockhash(block.number - 1),
            blockNumber: block.number
        }));

        candidates[_id].isActive = false; // Mark candidate as inactive instead of deleting

        emit CandidateDeleted(_id, candidates[_id].name);
    }

    function vote(uint256 _voterId, uint256 _candidateId, string memory _password) public onlyActiveElection {
        require(voters[_voterId].id != 0, "Voter not registered");
        require(!voters[_voterId].hasVoted, "Voter already voted");
        require(candidates[_candidateId].id != 0, "Candidate not found");
        require(voters[_voterId].passwordHash == keccak256(abi.encodePacked(_password)), "Invalid password");

        // Record the current state to history before voting
        voterHistories[_voterId].push(VoterHistory({
            id: _voterId,
            name: voters[_voterId].name,
            email: voters[_voterId].email,
            hasVoted: voters[_voterId].hasVoted,
            passwordHash: voters[_voterId].passwordHash,
            timestamp: block.timestamp,
            transactionHash: blockhash(block.number - 1),
            blockNumber: block.number
        }));

        candidates[_candidateId].voteCount++;

        // Record vote count history
        voteCountHistories[_candidateId].push(VoteCountHistory({
            candidateId: _candidateId,
            voteCount: candidates[_candidateId].voteCount,
            timestamp: block.timestamp,
            transactionHash: blockhash(block.number - 1),
            blockNumber: block.number
        }));

        voters[_voterId].hasVoted = true;
        voters[_voterId].lastUpdated = block.timestamp;
        voters[_voterId].transactionHash = blockhash(block.number - 1);
        voters[_voterId].blockNumber = block.number;
    }

    function endElection() public onlyOwner {
        electionActive = false;
        emit ElectionEnded();
    }

    function getVoteCount(uint256 _candidateId) public view returns (uint256) {
        require(candidates[_candidateId].id != 0, "Candidate not found");
        return candidates[_candidateId].voteCount;
    }

    function getAllVoters() public view returns (Voter[] memory) {
        uint256 activeCount = 0;

        // Count active voters
        for (uint256 i = 0; i < voterIds.length; i++) {
            if (voters[voterIds[i]].isActive) {
                activeCount++;
            }
        }

        Voter[] memory allVoters = new Voter[](activeCount);
        uint256 index = 0;
        for (uint256 i = 0; i < voterIds.length; i++) {
            uint256 voterId = voterIds[i];
            if (voters[voterId].isActive) {
                allVoters[index] = voters[voterId];
                index++;
            }
        }
        return allVoters;
    }

    function getAllCandidates() public view returns (Candidate[] memory) {
        Candidate[] memory allCandidates = new Candidate[](candidateIds.length);
        uint256 index = 0;
        for (uint256 i = 0; i < candidateIds.length; i++) {
            uint256 candidateId = candidateIds[i];
            if (candidates[candidateId].id != 0) {
                allCandidates[index] = candidates[candidateId];
                index++;
            }
        }
        return allCandidates;
    }

    function isVoterEligible(uint256 _voterId) public view returns (bool) {
        return voters[_voterId].id != 0 && !voters[_voterId].hasVoted;
    }

    function getAllVoterHistories() public view returns (VoterHistory[] memory) {
        uint256 totalHistories = 0;

        // Count total histories
        for (uint256 i = 0; i < voterIds.length; i++) {
            totalHistories += voterHistories[voterIds[i]].length + 1; // +1 for initial state
        }

        VoterHistory[] memory allHistories = new VoterHistory[](totalHistories);
        uint256 index = 0;

        // Gather all histories
        for (uint256 i = 0; i < voterIds.length; i++) {
            uint256 voterId = voterIds[i];

            // Add initial state
            allHistories[index] = VoterHistory({
                id: voters[voterId].id,
                name: voters[voterId].name,
                email: voters[voterId].email,
                hasVoted: voters[voterId].hasVoted,
                passwordHash: voters[voterId].passwordHash,
                timestamp: voters[voterId].lastUpdated,
                transactionHash: voters[voterId].transactionHash,
                blockNumber: voters[voterId].blockNumber
            });
            index++;

            // Add historical states
            VoterHistory[] memory histories = voterHistories[voterId];
            for (uint256 j = 0; j < histories.length; j++) {
                allHistories[index] = histories[j];
                index++;
            }
        }

        return allHistories;
    }

    function getAllCandidateHistories() public view returns (CandidateHistory[] memory) {
        uint256 totalHistories = 0;

        // Count total histories
        for (uint256 i = 0; i < candidateIds.length; i++) {
            totalHistories += candidateHistories[candidateIds[i]].length + 1; // +1 for initial state
        }

        CandidateHistory[] memory allHistories = new CandidateHistory[](totalHistories);
        uint256 index = 0;

        // Gather all histories
        for (uint256 i = 0; i < candidateIds.length; i++) {
            uint256 candidateId = candidateIds[i];

            // Add initial state
            allHistories[index] = CandidateHistory({
                id: candidates[candidateId].id,
                name: candidates[candidateId].name,
                visi: candidates[candidateId].visi,
                misi: candidates[candidateId].misi,
                voteCount: candidates[candidateId].voteCount,
                timestamp: candidates[candidateId].lastUpdated,
                transactionHash: candidates[candidateId].transactionHash,
                blockNumber: candidates[candidateId].blockNumber
            });
            index++;

            // Add historical states
            CandidateHistory[] memory histories = candidateHistories[candidateId];
            for (uint256 j = 0; j < histories.length; j++) {
                allHistories[index] = histories[j];
                index++;
            }
        }

        return allHistories;
    }

    function getAllVoteCountHistories() public view returns (VoteCountHistory[] memory) {
        uint256 totalHistories = 0;

        // Count total histories
        for (uint256 i = 0; i < candidateIds.length; i++) {
            totalHistories += voteCountHistories[candidateIds[i]].length;
        }

        VoteCountHistory[] memory allHistories = new VoteCountHistory[](totalHistories);
        uint256 index = 0;

        // Gather all histories
        for (uint256 i = 0; i < candidateIds.length; i++) {
            uint256 candidateId = candidateIds[i];
            VoteCountHistory[] memory histories = voteCountHistories[candidateId];
            for (uint256 j = 0; j < histories.length; j++) {
                allHistories[index] = histories[j];
                index++;
            }
        }

        return allHistories;
    }

    // Add login function
    function login(uint256 _voterId, string memory _password) public view returns (string memory, bool) {
        Voter memory voter = voters[_voterId];
        if (voter.id != 0 && voter.passwordHash == keccak256(abi.encodePacked(_password))) {
            return (voter.name, true);
        } else {
            return ("", false);
        }
    }
}