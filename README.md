<h1 align="center">Blockscout</h1>
<p align="center">Blockchain Explorer for inspecting and analyzing EVM Chains.</p>
<div align="center">

[![Blockscout](https://github.com/blockscout/blockscout/workflows/Blockscout/badge.svg?branch=master)](https://github.com/blockscout/blockscout/actions)
[![](https://dcbadge.vercel.app/api/server/blockscout?style=flat)](https://discord.gg/blockscout)

</div>


Blockscout provides a comprehensive, easy-to-use interface for users to view, confirm, and inspect transactions on EVM (Ethereum Virtual Machine) blockchains. This includes Ethereum Mainnet, Ethereum Classic, Optimism, Gnosis Chain and many other **Ethereum testnets, private networks, L2s and sidechains**.

See our [project documentation](https://docs.blockscout.com/) for detailed information and setup instructions.

For questions, comments and feature requests see the [discussions section](https://github.com/blockscout/blockscout/discussions) or via [Discord](https://discord.com/invite/blockscout).

## About Blockscout

Blockscout allows users to search transactions, view accounts and balances, verify and interact with smart contracts and view and interact with applications on the Ethereum network including many forks, sidechains, L2s and testnets.

Blockscout is an open-source alternative to centralized, closed source block explorers such as Etherscan, Etherchain and others.  As Ethereum sidechains and L2s continue to proliferate in both private and public settings, transparent, open-source tools are needed to analyze and validate all transactions.

## Supported Projects

Blockscout currently supports several hundred chains and rollups throughout the greater blockchain ecosystem. Ethereum, Cosmos, Polkadot, Avalanche, Near and many others include Blockscout integrations. [A comprehensive list is available here](https://docs.blockscout.com/about/projects). If your project is not listed, please submit a PR or [contact the team in Discord](https://discord.com/invite/blockscout).

## Getting Started

See the [project documentation](https://docs.blockscout.com/) for instructions:

- [Manual deployment](https://docs.blockscout.com/for-developers/deployment/manual-deployment-guide)
- [Docker-compose deployment](https://docs.blockscout.com/for-developers/deployment/docker-compose-deployment)
- [Kubernetes deployment](https://docs.blockscout.com/for-developers/deployment/kubernetes-deployment)
- [Manual deployment (backend + old UI)](https://docs.blockscout.com/for-developers/deployment/manual-old-ui)
- [Ansible deployment](https://docs.blockscout.com/for-developers/ansible-deployment)
- [ENV variables](https://docs.blockscout.com/setup/env-variables)
- [Configuration options](https://docs.blockscout.com/for-developers/configuration-options)

## Acknowledgements

We would like to thank the EthPrize foundation for their funding support.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for contribution and pull request protocol. We expect contributors to follow our [code of conduct](CODE_OF_CONDUCT.md) when submitting code or comments.

## MIDL API Transaction Field Mapping

This section documents the mapping between transaction fields returned by the API endpoint `/api/v2/transactions/:transaction_hash_param` and their data sources for MIDL chain type.

### Standard Transaction Fields

| API Field | Source | Description |
|-----------|--------|-------------|
| `hash` | `transaction.hash` | Transaction hash on EVM chain |
| `block_number` | `transaction.block_number` | Block number where transaction was included |
| `timestamp` | `transaction.block.timestamp` | Block timestamp |
| `from` | `transaction.from_address` | Sender address on EVM chain |
| `to` | `transaction.to_address` | Recipient address on EVM chain |
| `value` | `transaction.value` | Value transferred in wei |
| `gas_used` | `transaction.gas_used` | Gas consumed by transaction |
| `gas_price` | `transaction.gas_price` | Gas price in wei |
| `status` | `transaction.status` | Transaction status (success/failed) |
| `input` | `transaction.input` | Transaction input data |
| `nonce` | `transaction.nonce` | Sender account nonce |

### MIDL-Specific Fields

| API Field | Source | Description |
|-----------|--------|-------------|
| `btc_dapp_tx` | `transaction.btc_tx_hash` | Bitcoin transaction hash from mempool, first input used as identifier |
| `btc_from` / `btc_address` | Mempool API | Bitcoin sender address from first input's prevout.scriptpubkey_address via mempool API, fallback to computed from public_key (deprecated) |
| `public_key` | `transaction.public_key` | Public key from Bitcoin transaction, synced from mempool |
| `btc_address_byte` | `transaction.btc_address_byte` | Bitcoin address type indicator (0=P2PKH, 1=P2SH, etc.) |
| `eth_address` | Computed | Ethereum address derived from public_key using EVM address derivation |
| `intents` | `transaction.intents` | List of transactions referencing the same btc_tx_hash |
| `completion_tx` | `completion_transaction.completion_tx` | Completion event transaction hash, mapped by btc_dapp_tx |
| `initiation_tx` | `initiation_transaction.initiation_tx` | Initiation event transaction hash, mapped by btc_dapp_tx |
| `btc_result_tx` | `committed_send_event.btc_result_tx` | Result Bitcoin transaction from committed event logs, mapped by btc_dapp_tx |

### Data Flow and Relationships

1. **Bitcoin Integration**: The `btc_tx_hash`, `public_key`, and `btc_address_byte` are synced from Bitcoin mempool
2. **Event Processing**: 
   - Initiation events create `InitiationTransaction` records
   - Completion events create `CompletionTransaction` records  
   - Committed send events create `CommittedSentEvent` records
3. **Address Derivation**: Bitcoin and Ethereum addresses are computed from the public key
4. **Intent Grouping**: Multiple EVM transactions can reference the same Bitcoin transaction via `btc_tx_hash`

### API Example

```bash
GET /api/v2/transactions/0x1234...
```

Returns transaction data with both standard EVM fields and MIDL-specific Bitcoin integration fields.

## License

[![License: GPL v3.0](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)

This project is licensed under the GNU General Public License v3.0. See the [LICENSE](LICENSE) file for details.
