# Staking Pool Smart Contract
[![MIT License](https://img.shields.io/badge/License-MIT-blue.svg)](https://choosealicense.com/licenses/mit/)

## Features of the contract
- Owner can add token to the staking pool
- Anyone can stake any amount of token in the pool (based on pool amount)
- User will be able to unstake with interest after the mature date of staking
- User can withdraw any specific staking amount by providing penalty
- Owner can withdraw any residual BNB or token from the contract

> **NOTE:**  For calling addTokenToPool() and stakeToken(), you have to approve for the allowance. For that you can use any erc20/bep20 contract.

## BSC Testnet Result
Staking Contract Address: [0xf6506574D34301f4AD1dfE179cB71305D732f698](https://testnet.bscscan.com/address/0xf6506574D34301f4AD1dfE179cB71305D732f698)