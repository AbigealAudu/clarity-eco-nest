# EcoNest
A decentralized community platform for sharing and incentivizing sustainable living tips and eco-friendly habits.

## Features
- Post eco-friendly tips and habits
- Vote on tips to highlight valuable content
- Earn eco-tokens for valuable contributions 
- Browse tips by category
- Tip leaderboard system

## Setup and Installation
1. Clone the repository
2. Install Clarinet
3. Run `clarinet check` to verify contracts
4. Run `clarinet test` to run test suite

## Usage Examples
```clarity
;; Post a new eco tip
(contract-call? .eco-nest post-tip "Composting Guide" "How to start composting at home..." u3)

;; Vote on a tip
(contract-call? .eco-nest vote-tip u1 true)

;; Get tip details
(contract-call? .eco-nest get-tip u1)
```

## Dependencies
- Clarity language
- Clarinet for testing and deployment
