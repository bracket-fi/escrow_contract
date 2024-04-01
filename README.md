# Bracket Escrow Contracts

## Documentation

The Bracket Escrow allows users to stake ETH and liquid staking ETH derivatives into the escrow in order to accumulate bracket points while the brktETH infrastructure is built. At the end of the escrow period, the funds will be locked for them to be converted into brkETH, for escrows in other chains they will be bridged into Arbitrum where they will be withdrawn by the multisig and converted into brktETH and distributed to the users.

After the escrow breaks and the assets are converted they will be distributed through a merkle tree in the Arbitrum Escrow. Moreover, any points or airdrops accumulated during the escrow will be also distributed in the original chain through the merkle distribution mechanism.

### MainEscrow
This will be the main escrow in arbitrum it contains all the basic functionality from the escrow while also allowing to withdraw escrowed funds by the owner multisig for them to be converted into brkETH after escrow breaks.

### BridgeEscrow
This is the contract meant to be deployed on other chains than Arbitrum (for now only ETH Mainnet) and that will allow to bridge tokens into Arbitrum through the official Arbitrum bridge after escrow breaks.

### EscrowBase
This contains all the escrow functionality and is the contract from which both `MainEscrow` and `BridgeEscrow` contracts inherit from. For more information about each function functionality check the natspec in `IEscrow`.