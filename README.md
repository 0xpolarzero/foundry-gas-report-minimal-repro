## How to run

1. Clone and install dependencies: `pnpm install` && `forge build`

2. Modify the amount of recipients in [generateCallData.ts](./scripts/generateCallData.ts) and run `pnpm run generateCallData`

3. Run the tests with Hardhat and Foundry

```shell
$ pnpm hardhat test
$ forge test --mt test_airdropERC1155_base --gas-report
# or
$ forge test --mt test_airdropERC1155_base -vvvv --isolate
```

## Notes/issues

### 1. `--gas-report` will ignore the contract when performing a low-level call to the airdrop contract.

See [GasliteDrop1155LowLevelCall.t.sol](./test/GasliteDrop1155LowLevelCall.t.sol).

Run with `forge test --mt test_airdropERC1155_lowLevelCall --gas-report`.
