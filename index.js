const ethers = require('ethers');
require('dotenv').config();
const express = require('express');
const jwt = require('jsonwebtoken');

const API_URL = process.env.API_URL;
const PRIVATE_KEY = process.env.PRIVATE_KEY;
const CONTRACT_ADDRESS = process.env.CONTRACT_ADDRESS;
const JWT_SECRET = process.env.JWT_SECRET;

const provider = new ethers.providers.JsonRpcProvider(API_URL);
const signer = new ethers.Wallet(PRIVATE_KEY, provider);
const { abi } = require("./artifacts/contracts/Election.sol/Election.json");
const contractInstance = new ethers.Contract(CONTRACT_ADDRESS, abi, signer);

const app = express();
app.use(express.json());

// Function to sign and send a transaction
const sendTransaction = async (method, ...params) => {
    const tx = await contractInstance[method](...params);
    return tx.wait();
};

// Endpoint for login
app.post('/login', async (req, res) => {
    const { voterId, password } = req.body;
    try {
        const [name, isLoginSuccessful] = await contractInstance.login(voterId, password);
        if (isLoginSuccessful) {
            const token = jwt.sign({ voterId }, JWT_SECRET, { expiresIn: '1h' });
            res.json({
                error: false,
                message: "success",
                loginResult: {
                    userId: voterId,
                    name: name,
                    token: token
                }
            });
        } else {
            res.status(401).json({ error: true, message: "Invalid credentials" });
        }
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Endpoint to add a new voter
app.post('/voters', async (req, res) => {
    const { id, name, email, password } = req.body;
    try {
        const receipt = await sendTransaction('addVoter', id, name, email, password);
        res.json({ receipt });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Endpoint to update a voter
app.put('/voters/:id', async (req, res) => {
    const { id } = req.params;
    const { name, email, password } = req.body;
    try {
        const receipt = await sendTransaction('updateVoter', id, name, email, password);
        res.json({ receipt });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Endpoint to delete a voter
app.delete('/voters/:id', async (req, res) => {
    const { id } = req.params;
    try {
        const receipt = await sendTransaction('deleteVoter', id);
        res.json({ receipt });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Endpoint to add a new candidate
app.post('/candidates', async (req, res) => {
    const { id, name, visi, misi } = req.body;
    try {
        const receipt = await sendTransaction('addCandidate', id, name, visi, misi);
        res.json({ receipt });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Endpoint to update a candidate
app.put('/candidates/:id', async (req, res) => {
    const { id } = req.params;
    const { name, visi, misi } = req.body;
    try {
        const receipt = await sendTransaction('updateCandidate', id, name, visi, misi);
        res.json({ receipt });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Endpoint to delete a candidate
app.delete('/candidates/:id', async (req, res) => {
    const { id } = req.params;
    try {
        const receipt = await sendTransaction('deleteCandidate', id);
        res.json({ receipt });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Endpoint to get all voters
app.get('/voters', async (req, res) => {
    try {
        const allVoters = await contractInstance.getAllVoters();
        const response = {
            error: false,
            message: "Voters fetched successfully",
            voters: allVoters.map(voter => ({
                id: voter.id,
                name: voter.name,
                email: voter.email,
                hasVoted: voter.hasVoted,
                lastUpdated: voter.lastUpdated
            }))
        };
        res.json(response);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Endpoint to get all candidates
app.get('/candidates', async (req, res) => {
    try {
        const allCandidates = await contractInstance.getAllCandidates();
        const response = {
            error: false,
            message: "Candidates fetched successfully",
            candidates: allCandidates.map(candidate => ({
                id: candidate.id,
                name: candidate.name,
                visi: candidate.visi,
                misi: candidate.misi,
                voteCount: candidate.voteCount,
                lastUpdated: candidate.lastUpdated
            }))
        };
        res.json(response);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Endpoint to get a specific voter by ID
app.get('/voters/:id', async (req, res) => {
    const voterId = req.params.id;
    try {
        const voter = await contractInstance.voters(voterId);
        res.json({
            id: voter.id,
            name: voter.name,
            email: voter.email,
            hasVoted: voter.hasVoted,
            lastUpdated: voter.lastUpdated
        });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Endpoint to get a specific candidate by ID
app.get('/candidates/:id', async (req, res) => {
    const candidateId = req.params.id;
    try {
        const candidate = await contractInstance.candidates(candidateId);
        res.json({
            id: candidate.id,
            name: candidate.name,
            visi: candidate.visi,
            misi: candidate.misi,
            voteCount: candidate.voteCount,
            lastUpdated: candidate.lastUpdated
        });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Endpoint to vote
app.post('/vote', async (req, res) => {
    const { voterId, candidateId, password } = req.body;
    try {
        const receipt = await sendTransaction('vote', voterId, candidateId, password);
        res.json({ receipt });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Endpoint to get vote count for a candidate
app.get('/vote-count/:id', async (req, res) => {
    const candidateId = req.params.id;
    try {
        const voteCount = await contractInstance.getVoteCount(candidateId);
        res.json({ voteCount });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Endpoint to get vote count for all candidates
app.get('/vote-counts', async (req, res) => {
    try {
        const allCandidates = await contractInstance.getAllCandidates();
        const voteCounts = allCandidates.map(candidate => ({
            id: candidate.id,
            voteCount: candidate.voteCount
        }));
        res.json({ voteCounts });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Endpoint to get vote status of a user
app.get('/voteStatus/:userId', async (req, res) => {
    const { userId } = req.params;

    try {
        const voter = await contractInstance.voters(userId);
        if (!voter.id) {
            return res.status(404).json({ hasVoted: false });
        }

        res.json({ hasVoted: voter.hasVoted });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Endpoint to get voter history
app.get('/voter-history/:id', async (req, res) => {
    const voterId = req.params.id;
    try {
        const history = await contractInstance.getVoterHistory(voterId);
        res.json(history);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Endpoint to get candidate history
app.get('/candidate-history/:id', async (req, res) => {
    const candidateId = req.params.id;
    try {
        const history = await contractInstance.getCandidateHistory(candidateId);
        res.json(history);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Endpoint to get vote count history
app.get('/vote-count-history/:id', async (req, res) => {
    const candidateId = req.params.id;
    try {
        const history = await contractInstance.getVoteCountHistory(candidateId);
        res.json(history);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Endpoint to get all voter histories
app.get('/all-voter-histories', async (req, res) => {
    try {
        const allHistories = await contractInstance.getAllVoterHistories();
        res.json(allHistories);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Endpoint to get all candidate histories
app.get('/all-candidate-histories', async (req, res) => {
    try {
        const allHistories = await contractInstance.getAllCandidateHistories();
        res.json(allHistories);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// Endpoint to get all vote count histories
app.get('/all-vote-count-histories', async (req, res) => {
    try {
        const allHistories = await contractInstance.getAllVoteCountHistories();
        res.json(allHistories);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

app.listen(3000, () => {
    console.log('Election API listening at http://localhost:3000');
});

