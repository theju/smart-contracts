# Smart Contracts

A random collection of programs that I primarily wrote to learn about Solidity and smart contracts.

## List of Smart Contracts

### Auction

An auction that allows people to bid, withdraw their bid (after being outbid) and for the auctioneer to claim the winning bid after deducting commission.

### Recurring Subscriptions

A set of scripts (two currently) that allows recurring subscriptions. The payer can deposit payment in lumpsum or in tranches which can be withdrawn by the merchant at predefined frequencies. Either party may cancel the payment and withdraw their balances.

TODO: The payer may deposit into an Aave or Curve wallet for yield farming.

## Install and Usage

```
$ npm install
$ npx truffle migrate
```

## License

`MIT`. Please refer to the `LICENSE` file. All these smart contracts are unaudited and were intended as a learning exercise. Please exercise due diligence before you use them.
