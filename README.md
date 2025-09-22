# Carbon Credits - Decentralized Carbon Offset Marketplace

A revolutionary Clarity smart contract for Stacks (STX) that enables transparent, verifiable carbon credit trading with full blockchain immutability.

## 🌍 Overview

Carbon Credits creates a complete ecosystem for environmental sustainability on the blockchain. Organizations can mint verified carbon credits, trade them in a decentralized marketplace, and permanently retire them to offset carbon footprints - all with unprecedented transparency and fraud prevention.

## ✨ Key Features

### 🏭 **Project Registry System**
- Register carbon offset projects with comprehensive metadata
- Track project locations, types, and verification status
- Monitor total credits issued per project
- Multi-verifier support for enhanced credibility

### 🪙 **Carbon Credit Lifecycle**
- **Mint**: Create new carbon credits from verified projects
- **Verify**: Third-party verification before trading
- **Trade**: Transfer credits between parties (full or fractional)
- **Retire**: Permanently remove credits from circulation

### 🔐 **Multi-Layer Security**
- Role-based access control (Owner, Issuers, Verifiers)
- Verified issuer requirements for minting
- Project verifier validation system
- Emergency pause/unpause functionality
- Comprehensive input validation

### 💰 **Economic Features**
- Fractional credit trading
- Customizable pricing per credit
- Verification fees to prevent spam
- Balance tracking system
- Double-spending prevention

## 🚀 Getting Started

### Prerequisites
- [Clarinet](https://github.com/hirosystems/clarinet) installed
- Basic understanding of Clarity smart contracts
- Stacks wallet for deployment

### Installation

1. Clone the repository:
```bash
git clone <your-repo-url>
cd carbon-credits
```

2. Check contract validity:
```bash
clarinet check
```

3. Run tests:
```bash
clarinet test
```

4. Deploy to testnet:
```bash
clarinet deploy --testnet
```

## 📋 Contract Functions

### Admin Functions

#### `add-verified-issuer(issuer: principal)`
Authorize a principal to issue carbon credits.
- **Access**: Contract owner only
- **Returns**: `(response bool uint)`

#### `add-project-verifier(verifier: principal)`
Authorize a principal to verify carbon credits.
- **Access**: Contract owner only
- **Returns**: `(response bool uint)`

#### `set-verification-fee(new-fee: uint)`
Update the verification fee amount.
- **Access**: Contract owner only
- **Returns**: `(response bool uint)`

### Project Management

#### `register-project(...)`
Register a new carbon offset project.
- **Parameters**:
  - `project-id`: Unique project identifier
  - `name`: Project name (max 256 chars)
  - `location`: Geographic location
  - `project-type`: Type of carbon offset project
  - `verifier`: Authorized verifier principal
- **Access**: Verified issuers only
- **Returns**: `(response bool uint)`

### Carbon Credit Operations

#### `mint-carbon-credits(...)`
Create new carbon credits for a registered project.
- **Parameters**:
  - `project-id`: Associated project
  - `amount`: Number of credits to mint
  - `price-per-ton`: Price in microSTX
  - `vintage-year`: Year credits were generated
  - `methodology`: Carbon accounting methodology
- **Access**: Verified issuers only
- **Returns**: `(response uint uint)` - Returns credit ID

#### `verify-carbon-credit(credit-id: uint)`
Verify carbon credits for trading.
- **Access**: Authorized project verifiers only
- **Fee**: Verification fee paid to contract owner
- **Returns**: `(response bool uint)`

#### `transfer-carbon-credits(credit-id: uint, recipient: principal, amount: uint)`
Transfer carbon credits to another user.
- **Requirements**: Credits must be verified and not retired
- **Returns**: `(response bool uint)`

#### `retire-carbon-credits(credit-id: uint, amount: uint)`
Permanently retire carbon credits from circulation.
- **Effect**: Credits become non-transferable
- **Returns**: `(response bool uint)`

### Read-Only Functions

#### `get-carbon-credit(credit-id: uint)`
Retrieve complete carbon credit information.

#### `get-project-info(project-id: string-ascii)`
Get project registry details.

#### `get-user-balance(user: principal, project-id: string-ascii)`
Check user's credit balance for a specific project.

## 🎯 Usage Examples

### 1. Setting Up the System

```clarity
;; 1. Add a verified issuer (owner only)
(contract-call? .carbon-credits add-verified-issuer 'SP1234...ISSUER)

;; 2. Add a project verifier (owner only)
(contract-call? .carbon-credits add-project-verifier 'SP5678...VERIFIER)

;; 3. Register a carbon project (verified issuer only)
(contract-call? .carbon-credits register-project 
    "FOREST-001" 
    "Amazon Rainforest Conservation"
    "Brazil, Amazon Basin"
    "Forest Conservation"
    'SP5678...VERIFIER)
```

### 2. Minting and Trading Credits

```clarity
;; 1. Mint carbon credits (verified issuer only)
(contract-call? .carbon-credits mint-carbon-credits
    "FOREST-001"
    u1000  ;; 1000 credits
    u50000000  ;; 50 STX per credit
    u2024  ;; 2024 vintage
    "Verified Carbon Standard (VCS)")

;; 2. Verify credits (project verifier only)
(contract-call? .carbon-credits verify-carbon-credit u1)

;; 3. Transfer credits
(contract-call? .carbon-credits transfer-carbon-credits
    u1  ;; credit ID
    'SP9999...BUYER  ;; recipient
    u100)  ;; 100 credits

;; 4. Retire credits to offset emissions
(contract-call? .carbon-credits retire-carbon-credits u1 u50)
```

## 🔒 Security Features

### Access Control
- **Contract Owner**: Full administrative control
- **Verified Issuers**: Can register projects and mint credits
- **Project Verifiers**: Can verify specific project credits
- **Users**: Can trade and retire verified credits

### Safety Mechanisms
- Balance validation prevents overdrafts
- Status checks prevent invalid operations
- Retirement prevention stops double-counting
- Emergency pause for critical situations

### Error Handling
| Error Code | Description |
|------------|-------------|
| u100 | Owner only access required |
| u101 | Resource not found |
| u102 | Insufficient balance |
| u103 | Invalid amount |
| u104 | Unauthorized access |
| u105 | Credit already retired |
| u106 | Invalid project |
| u107 | Transfer failed |

## 🌱 Environmental Impact

This contract enables:
- **Transparent Carbon Markets**: All transactions recorded on blockchain
- **Fraud Prevention**: Immutable record of credit lifecycle
- **Global Accessibility**: Anyone can participate in carbon offsetting
- **Standardization**: Consistent methodology tracking
- **Accountability**: Permanent retirement prevents double-counting

## 🛠 Development

### Contract Architecture
```
Carbon Credits Contract
├── Admin Functions (Owner)
├── Project Registry (Verified Issuers)
├── Credit Lifecycle (All Users)
├── Verification System (Project Verifiers)
└── Emergency Controls (Owner)
```

### Data Structures
- **carbon-credits**: Core credit information and ownership
- **project-registry**: Project metadata and status
- **user-balances**: Efficient balance tracking
- **verified-issuers**: Authorized credit issuers
- **project-verifiers**: Authorized verifiers

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Add comprehensive tests
4. Ensure `clarinet check` passes
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

For questions, issues, or feature requests:
- Create an issue on GitHub
- Join our community Discord
- Contact the development team

---

**Built with ❤️ for a sustainable future on Stacks blockchain**

*Making carbon offsetting transparent, accessible, and fraud-proof for everyone.*
