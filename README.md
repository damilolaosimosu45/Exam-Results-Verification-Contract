# 🎓 Exam Results Verification Contract

A Clarity-based smart contract system that enables educational institutions to publish verifiable exam results tied to student wallet addresses on the Stacks blockchain.

## 📋 Overview

This contract provides a decentralized solution for exam result verification, ensuring authenticity and preventing fraud through blockchain technology. Institutions can register, get verified, and publish tamper-proof exam results that students can prove ownership of through their wallet addresses.

## ✨ Features

- 🏫 **Institution Registration**: Educational institutions can register and get verified
- 📊 **Result Publishing**: Verified institutions can publish exam results for students
- 🔍 **Result Verification**: Anyone can verify the authenticity of exam results
- 👨‍💼 **Admin Management**: Institution admins can manage their results
- 🔒 **Secure Access**: Role-based access control for different operations
- 📝 **Result Updates**: Institutions can update or revoke results when necessary

## 🚀 Getting Started

### Prerequisites

- Clarinet CLI installed
- Stacks wallet for testing

### Installation

1. Clone the repository
2. Navigate to the project directory
3. Deploy the contract using Clarinet

```bash
clarinet deploy
```

## 📖 Usage

### For Contract Owner

**Register an Institution:**
```clarity
(contract-call? .exam-results-verification register-institution "University Name")
```

**Verify an Institution:**
```clarity
(contract-call? .exam-results-verification verify-institution u1)
```

### For Institution Admins

**Publish Exam Result:**
```clarity
(contract-call? .exam-results-verification publish-result 
  'ST1STUDENT-WALLET-ADDRESS
  "Final Examination 2024"
  "Mathematics"
  "A+"
  u95
  u100
  u1234567890)
```

**Update Result:**
```clarity
(contract-call? .exam-results-verification update-result u1 "A" u90)
```

**Revoke Result:**
```clarity
(contract-call? .exam-results-verification revoke-result u1)
```

### For Anyone (Read-Only)

**Verify a Result:**
```clarity
(contract-call? .exam-results-verification verify-result u1)
```

**Get Institution Info:**
```clarity
(contract-call? .exam-results-verification get-institution u1)
```

**Get Student Results:**
```clarity
(contract-call? .exam-results-verification get-student-results 'ST1STUDENT-WALLET u1)
```

## 🏗️ Contract Structure

### Data Maps

- **institutions**: Stores institution information and verification status
- **exam-results**: Contains all exam result records
- **student-results**: Maps students to their result IDs per institution
- **institution-admins**: Links admin addresses to their institutions

### Key Functions

| Function | Access | Description |
|----------|--------|-------------|
| `register-institution` | Owner Only | Register a new educational institution |
| `verify-institution` | Owner Only | Verify an institution's legitimacy |
| `publish-result` | Institution Admin | Publish a new exam result |
| `update-result` | Institution Admin | Update an existing result |
| `revoke-result` | Institution Admin | Revoke/invalidate a result |
| `verify-result` | Public | Verify authenticity of any result |

## 🔐 Security Features

- ✅ Role-based access control
- ✅ Institution verification requirement
- ✅ Result authenticity validation
- ✅ Immutable audit trail
- ✅ Secure admin management

## 🧪 Testing

Run the test suite:

```bash
clarinet test
```

## 📄 Error Codes

| Code | Description |
|------|-------------|
| u100 | Not authorized |
| u101 | Institution not found |
| u102 | Result not found |
| u103 | Already exists |
| u104 | Invalid grade |
| u105 | Invalid institution |

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## 📜 License

This project is open source and available under the MIT License.

---

Built with ❤️ using Clarity and Stacks blockchain technology
```

**Git Commit Message:**
```
feat: implement exam results verification smart contract with institution management
```

**GitHub Pull Request Title:**
```
🎓 Add Exam Results Verification Smart Contract
```

**GitHub Pull Request Description:**
```
## Summary
Added a comprehensive Clarity smart contract for exam results verification that enables educational institutions to publish tamper-proof exam results on the Stacks blockchain.

## What's Added
- Complete smart contract implementation with 150+ lines of Clarity code
- Institution registration and verification system
- Exam result publishing and management functionality
- Role-based access control for contract owner and institution admins
- Comprehensive read-only functions for result verification
- Detailed README with usage instructions and examples
- Error handling with descriptive error codes

## Key Features
- 🏫 Institution registration and verification
- 📊 Secure exam result publishing
- 🔍 Public result verification
- 👨‍💼 Admin management system
- 📝 Result update and revocation capabilities
- 🔒 Role-based security controls

## Technical Details
- Uses updated Stacks functions (stacks-block-height)
- Implements proper data mapping structures
- Includes comprehensive error handling
- Follows Clarity best practices
- Ready for Clarinet deployment

This contract provides a foundation for building decentralized educational credential systems with blockchain-verified authenticity.
