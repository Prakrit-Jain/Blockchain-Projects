# DEFI Staking Contract
## Introduction
The DEFI Staking Contract is a Solidity smart contract designed to enable users to stake DEFI tokens and earn additional DEFI tokens as rewards based on the amount staked and the duration of the stake. This contract provides a decentralized solution for users to participate in staking activities and earn rewards in a transparent and automated manner.

### Features
 - Staking: Users can stake their DEFI tokens into the contract, locking them up for a certain period.
 - Rewards: Users earn additional DEFI tokens as rewards for staking, with the reward rate determined by the amount staked and the duration of the stake.
 - Withdrawal: Users can withdraw their staked DEFI tokens along with any accrued rewards at any time.
 - Flexible: The contract allows for dynamic adjustment of staking parameters, providing flexibility to adapt to changing conditions.

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/DEFIStaking.s.sol:DEFIStakingScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```
