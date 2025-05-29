# 🌉 MindBridge

**Decentralized Mental Health Support Platform**

*Empowering communities through transparent, blockchain-based mental health funding*

---

## 🎯 Mission

MindBridge revolutionizes mental health support by creating a transparent, community-driven funding platform built on the Stacks blockchain. We believe that mental health support should be accessible, transparent, and community-powered.

## ✨ Features

### 🏛️ Core Platform
- **Community Vault**: Secure, transparent fund management
- **Smart Contributions**: Automated contribution processing with tier-based recognition
- **Crisis Mode**: Emergency response system for urgent mental health needs
- **Daily Limits**: Built-in safeguards to ensure responsible fund distribution

### 👥 Community-Driven
- **Contributor Tiers**: Bronze, Silver, Gold, and Platinum recognition levels
- **Support Recipients**: Verified individuals receiving mental health support
- **Batch Distribution**: Efficient support delivery to multiple recipients
- **Transparent Tracking**: Complete audit trail of all transactions

### 🛡️ Security & Governance
- **Guardian System**: Trusted administration with transfer capabilities
- **Multi-tier Validation**: Comprehensive input validation and error handling
- **Emergency Controls**: Crisis mode activation and platform status management
- **Daily Withdrawal Limits**: Configurable spending controls

## 🚀 Getting Started

### Prerequisites
- [Clarinet](https://github.com/hirosystems/clarinet) for local development
- [Stacks Wallet](https://www.hiro.so/wallet) for testnet interactions
- Basic understanding of Clarity smart contracts

### Local Development

1. **Clone the repository**
   ```bash
   git clone https:/nnadi-cmd/github.com//mindbridge
   cd mindbridge
   ```

2. **Initialize Clarinet project**
   ```bash
   clarinet new mindbridge-platform
   cd mindbridge-platform
   ```

3. **Add the contract**
   ```bash
   # Copy the MindBridge contract to contracts/mindbridge.clar
   clarinet contract add mindbridge
   ```

4. **Run tests**
   ```bash
   clarinet test
   ```

5. **Check contract syntax**
   ```bash
   clarinet check
   ```

## 📋 Smart Contract Overview

### Key Functions

#### 🤝 Community Participation
- `contribute-to-community-vault()` - Make contributions to support mental health initiatives
- `get-contributor-profile(principal)` - View contributor statistics and tier

#### 🎯 Support Management
- `register-support-recipient(principal, string-ascii)` - Register verified support recipients
- `distribute-support(principal, uint)` - Distribute funds to recipients
- `batch-distribute-support(list)` - Efficient multi-recipient distribution
- `update-recipient-tier(principal, string-ascii)` - Manage recipient support levels

#### ⚙️ Platform Administration
- `activate-crisis-mode()` / `deactivate-crisis-mode()` - Emergency response controls
- `set-daily-withdrawal-limit(uint)` - Configure spending limits
- `transfer-guardianship(principal)` - Transfer platform administration
- `toggle-platform-status()` - Enable/disable platform operations

### Support Tiers
- **Active**: Regular ongoing support
- **Priority**: Increased support needs
- **Crisis**: Emergency mental health situations
- **Recovering**: Transitional support phase
- **Graduated**: Successfully completed support program

### Contributor Tiers
- **Bronze**: 0-5 STX contributed
- **Silver**: 5-20 STX contributed  
- **Gold**: 20-50 STX contributed
- **Platinum**: 50+ STX contributed

## 🔍 Usage Examples

### Making a Contribution
```clarity
;; Contribute STX from your wallet to the community vault
(contract-call? .mindbridge contribute-to-community-vault)
```

### Registering a Support Recipient
```clarity
;; Register someone needing mental health support (admin only)
(contract-call? .mindbridge register-support-recipient 'SP2X... "active")
```

### Distributing Support
```clarity
;; Distribute 5 STX to a verified recipient (admin only)
(contract-call? .mindbridge distribute-support 'SP2X... u5000000)
```

## 📊 Platform Statistics

View real-time platform metrics:
```clarity
(contract-call? .mindbridge get-platform-statistics)
```

Returns:
- Total vault balance
- Number of active supporters  
- Minimum contribution threshold
- Daily withdrawal limit
- Crisis mode status

## 🔐 Security Features

### Input Validation
- Amount limits and bounds checking
- Principal address validation
- Support tier validation
- Daily withdrawal limits

### Access Controls
- Guardian-only administrative functions
- Crisis mode emergency protocols
- Platform operational status controls

### Transparency
- Complete transaction history
- Public contributor and recipient profiles
- Real-time vault balance reporting

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

### Development Workflow
1. Fork the repository
2. Create a feature branch
3. Write tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

For technical support or questions:
- Open an issue on GitHub
- Join our community Discord
- Email: support@mindbridge.community

## 🗺️ Roadmap

- [ ] Web dashboard for platform interaction
- [ ] Mobile app development
- [ ] Integration with mental health providers
- [ ] Multi-token support (beyond STX)
- [ ] Automated support scheduling
- [ ] Community voting mechanisms

---

**Building bridges to better mental health, one transaction at a time.** 🌉💙