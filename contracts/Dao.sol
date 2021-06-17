  // SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Dao {
  enum Side { Yes, No}
  enum Status { Undecided, Approved, Rejected}
  struct Proposal {
    address author;
    bytes32 hash;
    uint createdAt;
    uint votesYes;
    uint votesNo;
    Status status;
  }

  mapping(bytes32 => Proposal) public proposals;
  mapping(address => mapping(bytes32 => bool)) public votes;
  mapping(address => uint) public shares;
  uint public totalShares;
  IERC20 public token;
  uint constant CREATE_PROPOSAL_MIN_SHARE = 100 * 10 ** 18;
  uint constant VOTING_PERIOD = 7 days;

  constructor(address _token) {
    token = IERC20(_token);
  }

  function deposit(uint _amount) external {
    shares[msg.sender] += _amount;
    totalShares += _amount;
    token.transferFrom(msg.sender, address(this), _amount);
  }

  function withdraw (uint _amount) external {
    require(shares[msg.sender] >= _amount, "not enough shares");
    shares[msg.sender] -= _amount;
    totalShares -= _amount;
    token.transfer(msg.sender, _amount);
  }

  function createProposal(bytes32 _proposalHash) external {
    require(shares[msg.sender] >= CREATE_PROPOSAL_MIN_SHARE, "not enough shares to create proposal");
    require(proposals[_proposalHash].hash == bytes32(0), "proposal already exists");
    proposals[_proposalHash] = Proposal(msg.sender, _proposalHash, block.timestamp, 0, 0 , Status.Undecided);
  }

  function vote(bytes32 _proposalHash, Side _side) external {
    require(proposals[_proposalHash].hash != bytes32(0), "proposal does not exist");
    require(votes[msg.sender][_proposalHash] == false, "You voted already!");
    Proposal storage proposal = proposals[_proposalHash];
    require(block.timestamp <= proposal.createdAt + VOTING_PERIOD, "Voting period has ended!");
    votes[msg.sender][_proposalHash] = true;
    if (_side == Side.Yes) {
        proposal.votesYes += shares[msg.sender];
        if (proposal.votesYes * 100 / totalShares > 50) {
          proposal.status = Status.Approved;
        }
    } else {
      proposal.votesNo += shares[msg.sender];
      if (proposal.votesNo * 100 / totalShares > 50) {
        proposal.status = Status.Rejected;
      }
    }
  }
}