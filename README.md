# TechEscrow

A secure, decentralized escrow service for IT freelancers and clients built on the Stacks blockchain.

## Overview

TechEscrow is a smart contract solution that facilitates secure milestone-based payments between IT freelancers and clients. By leveraging blockchain technology, it eliminates the need for traditional escrow services while providing transparency, security, and dispute resolution mechanisms.

## Features

- **Milestone-Based Payments**: Break projects into manageable milestones with individual payments
- **Secure Fund Management**: Client funds are locked in the contract until milestone completion
- **Dispute Resolution**: Built-in mechanism for handling disagreements
- **Transparent Workflow**: All parties can verify the state of the project at any time
- **Decentralized Trust**: No need for third-party escrow services

## Contract Structure

The TechEscrow contract consists of several key components:

### Data Maps

- `projects`: Stores project details including client, freelancer, amounts, and status
- `milestones`: Stores individual milestone information for each project
- `disputes`: Tracks any disputes raised for projects

### Functions

#### Project Management
- `create-project`: Initialize a new project with funds
- `add-milestone`: Define project milestones
- `cancel-project`: Cancel a project and refund remaining funds

#### Milestone Management
- `complete-milestone`: Mark a milestone as completed (freelancer)
- `approve-milestone`: Approve and pay for a completed milestone (client)

#### Dispute Handling
- `create-dispute`: Raise a dispute for a project
- `approve-resolution`: Approve a dispute resolution

## How to Use

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) installed (v0.31.1 or later)
- [Stacks Wallet](https://www.hiro.so/wallet) for deployment and interaction

### Deployment

1. Clone this repository
2. Navigate to the project directory
3. Deploy using Clarinet:

```bash
clarinet deploy --network testnet

### TechEscrow README.md

```markdown project="TechEscrow" file="README.md"
...
```

### Interacting with the Contract

#### As a Client

1. Create a new project:


```plaintext
(contract-call? .tech-escrow create-project "project-123" 'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG 1000 3)
```

2. Add milestones:


```plaintext
(contract-call? .tech-escrow add-milestone "project-123" u0 "Design phase" 300)
(contract-call? .tech-escrow add-milestone "project-123" u1 "Development" 500)
(contract-call? .tech-escrow add-milestone "project-123" u2 "Testing" 200)
```

3. Approve completed milestones:


```plaintext
(contract-call? .tech-escrow approve-milestone "project-123" u0)
```

#### As a Freelancer

1. Mark milestones as completed:


```plaintext
(contract-call? .tech-escrow complete-milestone "project-123" u0)
```

## Function Documentation

### create-project

Creates a new project with specified parameters.

**Parameters:**

- `project-id`: Unique identifier for the project (string-ascii 36)
- `freelancer`: Principal of the freelancer
- `total-amount`: Total project amount in STX
- `milestone-count`: Number of milestones in the project


**Returns:**

- `(ok true)` on success
- Error code on failure


### add-milestone

Adds a milestone to an existing project.

**Parameters:**

- `project-id`: Project identifier
- `milestone-id`: Milestone number (uint)
- `description`: Description of the milestone (string-utf8 256)
- `amount`: Payment amount for this milestone


**Returns:**

- `(ok true)` on success
- Error code on failure


### complete-milestone

Marks a milestone as completed (called by freelancer).

**Parameters:**

- `project-id`: Project identifier
- `milestone-id`: Milestone number


**Returns:**

- `(ok true)` on success
- Error code on failure


### approve-milestone

Approves and pays for a completed milestone (called by client).

**Parameters:**

- `project-id`: Project identifier
- `milestone-id`: Milestone number


**Returns:**

- `(ok true)` on success
- Error code on failure


### create-dispute

Creates a dispute for a project.

**Parameters:**

- `project-id`: Project identifier
- `reason`: Reason for the dispute (string-utf8 256)


**Returns:**

- `(ok true)` on success
- Error code on failure


### approve-resolution

Approves a dispute resolution.

**Parameters:**

- `project-id`: Project identifier


**Returns:**

- `(ok true)` if resolution is complete
- `(ok false)` if waiting for other party's approval
- Error code on failure


### cancel-project

Cancels a project and refunds remaining funds.

**Parameters:**

- `project-id`: Project identifier


**Returns:**

- `(ok true)` on success
- Error code on failure


## Error Codes

| Code | Description
|-----|-----
| `ERR-NOT-AUTHORIZED` | Caller is not authorized to perform this action
| `ERR-PROJECT-EXISTS` | Project with this ID already exists
| `ERR-PROJECT-NOT-FOUND` | Project with this ID does not exist
| `ERR-INSUFFICIENT-FUNDS` | Insufficient funds for this operation
| `ERR-MILESTONE-NOT-FOUND` | Milestone does not exist
| `ERR-MILESTONE-ALREADY-PAID` | Milestone has already been paid
| `ERR-DISPUTE-EXISTS` | Dispute already exists for this project
| `ERR-NO-DISPUTE` | No dispute exists for this project
| `ERR-TRANSFER-FAILED` | STX transfer failed
| `ERR-INVALID-FREELANCER` | Invalid freelancer principal
| `ERR-INVALID-MILESTONE-COUNT` | Invalid milestone count
| `ERR-INVALID-DESCRIPTION` | Invalid milestone description
| `ERR-INVALID-AMOUNT` | Invalid amount
| `ERR-INVALID-REASON` | Invalid dispute reason


## Security Considerations

The TechEscrow contract implements several security measures:

- **Input Validation**: All function parameters are validated before use
- **Authorization Checks**: Functions verify the caller has appropriate permissions
- **Fund Safety**: Funds are locked in the contract until explicit approval
- **Response Handling**: All responses from STX transfers are properly checked


## Testing

Run the included tests using Clarinet:

```shellscript
clarinet test
```

Create your own tests by adding scenarios to the `tests` directory.

## Future Enhancements

Potential future improvements include:

- Third-party arbitration for unresolved disputes
- Reputation tracking for freelancers and clients
- Time-based milestone deadlines
- Partial milestone approvals
- Multi-signature approval workflows


## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request