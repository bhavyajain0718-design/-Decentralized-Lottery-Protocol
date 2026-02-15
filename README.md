# 🎲 Decentralized Lottery Protocol

> A trustless, automated lottery smart contract powered by verifiable randomness.  
> Built with Solidity + Foundry + Chainlink infrastructure.

---

## 👋 About Me

Hi, I'm **Bhavya**  
Blockchain & DeFi developer focused on **smart contract engineering and protocol security**.

I build real-world protocols to understand how money systems behave under risk — not just tutorials.

---

## 🚀 Overview

This project implements a fully decentralized lottery where:

- Players enter by paying ETH
- A winner is selected automatically
- Randomness is cryptographically verifiable
- No admin can manipulate results

The protocol removes:
❌ manual selection  
❌ owner bias  
❌ predictable randomness  

And replaces it with:
✅ Verifiable randomness  
✅ Trustless automation  
✅ Deterministic smart contract logic  

---

## ⚙️ Architecture

### Randomness
Uses **Chainlink VRF** for provably fair winner selection.

### Automation
Uses **Chainlink Automation (Keepers)** to trigger draws automatically.

### Testing
Built with **Foundry** for:
- Unit tests
- Fuzz tests
- Invariant tests
- Gas reports

---

## ✨ Features

### Core
- Enter lottery with ETH
- Automatic round closing
- Random winner selection
- Prize pool distribution

### Security
- Reentrancy-safe withdrawals
- State machine checks
- No admin control over randomness
- Safe ETH transfers

### Testing
- Full unit tests
- Fuzzed entry logic
- Edge case coverage
- Gas optimization

---

## 🧠 What I Learned

- Chainlink VRF integration
- Oracle-based architecture
- Automation/keeper systems
- Secure fund handling
- State machine design
- Writing invariant tests
- Thinking like a protocol engineer

---

## 🧱 Tech Stack

- Solidity
- Foundry
- Chainlink VRF
- Chainlink Automation

---

## 📂 Project Structure

src/        → Lottery contracts  
script/     → deployment scripts  
test/       → unit + fuzz tests  

---

## ⚙️ Setup

### Install
```bash
forge install
