# Overview

The ContractManager smart contract is designed to manage a registry of contracts within a decentralized application. It provides functionalities to add, update, remove, and manage contract addresses and their descriptions.

This contract aims to enhance security and organization in managing contract addresses.


### Run project by following the steps below:

Copy the ``.env.example`` file in a new file ``.env``.

Install node:
```shell
nvm install v18.0.0
```

Then run command to use the installed node version
```shell
nvm use v18.0.0
```

First install the dependencies:
```shell
yarn install
```
To compile the smart contracts use command:
```shell
npx hardhat compile
```

To run test cases use command:
```shell
npx hardhat test
```

To deploy on hardhat local network use command:
```shell
npx hardhat run scripts/deployContractManager.js
```

To deploy on testnet or mainnet use command:
```shell
npx hardhat run scripts/deployContractManager.js --network <network name>
```

To deploy on network remember to save network url, api key, private key in .env file which will be exported in hardhat.config.js file.

The following contract is deployed on bsctestnet:

[`0xaf12518E8089549FAde1Dd442A27Cc4C584A9c56`](https://testnet.bscscan.com/address/0xaf12518E8089549FAde1Dd442A27Cc4C584A9c56)
