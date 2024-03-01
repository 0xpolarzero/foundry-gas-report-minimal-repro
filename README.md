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

4. Deploy reference tx on Sepolia

Add `RPC_URL_SEPOLIA` and `PRIVATE_KEY` to .env and run `source .env`.

Then run:

```shell
forge script script/DeployAndAirdrop.s.sol:DeployAndAirdrop --rpc-url $RPC_URL_SEPOLIA --broadcast -vvvv
```

## Notes/issues

### `--gas-report` won't report accurate values

1. Run `forge test --mt test_airdropERC1155_base --gas-report` and notice the values reported with `--gas-report`:

- `GasliteDrop1155:airdropERC1155`: 14,934,491
- `AirdropERC1155:airdropERC1155`: 14,802,928

... which by the way indicates that using AirdropERC1155 would be cheaper.

2. Run scripts to compare to Sepolia tx:

```shell
forge script script/DeployAndAirdrop.s.sol:DeployAndAirdrop --rpc-url $RPC_URL_SEPOLIA --broadcast
# and
forge script script/DeployAndAirdropThirdweb.s.sol:DeployAndAirdropThirdweb --rpc-url $RPC_URL_SEPOLIA --broadcast
```

The results, which would use the exact same data from [constants/airdropTokens.json](./constants/airdropTokens.json), are:

- [`GasliteDrop1155:airdropERC1155`: 14,934,491](https://sepolia.etherscan.io/tx/0x319180ecb6421e686df92e3652c58852e3f28c19261c272676f4a4f8b5618d68)
- [`AirdropERC1155:airdropERC1155`: 15,205,153](https://sepolia.etherscan.io/tx/0x4f0f67b7206467d1ee47681552217eaa0df0b03df77adbcbca9db6098f217e8e)

**The gas usage reported for GasliteDrop1155 is perfectly accurate, but the gas usage for AirdropERC1155 is underestimated in the gas report.**

---

### (unrelated) `--gas-report` will ignore the contract when performing a low-level call to the airdrop contract.

See [GasliteDrop1155LowLevelCall.t.sol](./test/GasliteDrop1155LowLevelCall.t.sol).

Run with `forge test --mt test_airdropERC1155_lowLevelCall --gas-report`.
