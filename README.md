# DAMM Contracts

The DAMM protocol is an ALM (Automated Liquidity Management) toolkit for decentralized mutual funds.

## This Repository
Inside this repository you will find contracts for creating and managing mutual funds. Mutual funds are Gnosis Safe Multisigs with extended functionality provided by Zodiac Modules. As of right now, the only DAMM specific module is the Deposit Module. This module is responsible for the tokenization of deposits and withdrawals into the safe. Other zodiac modules can be used to alongside the Deposit Module to enhance the functionality of the mutual fund, for example, the Zodiac Roles Module can be used to allow operators to manage the fund assets.

## Links

- Documentation: [docs.dammcap.finance](https://docs.dammcap.finance)
- Website: [dammcap.finance](https://dammcap.finance)
- Twitter: [@DAMM_Capital](https://x.com/DAMM_Capital)

## Getting Started

This project is built with the foundry development kit. You can install it by following the instructions [here](https://book.getfoundry.sh/getting-started/installation.html).

### Install dependencies

```bash
forge install
```

### Run tests

> Note: Fork tests require you to set `ARBI_RPC_URL` in the `.env` file. You can get a free RPC URL [here](https://www.alchemy.com/). The `.env` file should be at the root of the project.

```bash
forge test
```
