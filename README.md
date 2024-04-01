# Bracket Escrow Contracts

## Documentation

The Bracket Escrow allows users to stake ETH and liquid staking ETH derivatives into the escrow
on either L1 Ethereum or Arbitrum.  Many will be doing this in order to accumulate bracket reward 
points (off-chain) while the brktETH infrastructure is built and TVL is built. During the pre-break 
period, a user will be free to remove their funds in amounts of the assets they deposited.

At the end of the escrow period, the funds will be locked and no longer be available for withdraw.
All funds will be bridged to Arbitrum and become part of the pooled treasury initially in the escrow
contract and then eventually within the brktETH contract.
The users will receive brktETH for the amount of equivalent ETH they held at the time of escrow-break. 
Once the assets are bridged to Aribitrum, brktETH will be issued on Arbitrum.  BrktETH will be a
separate contract and owned by a multisig.  BrktETH will deposited within the escrow contract 
and the bridged assets will be withdrawn into the brktETH contract.  

Users will then be able to claim their brktETH on Aribtrum though the escrow contract 
on Arbitrum based on a merkle tree in the Arbitrum Escrow to verify their brktETH withdrawal amounts.

### MainEscrow
This will be the main escrow on arbitrum and contains all the basic functionality from the 
escrow while also allowing to withdraw escrowed funds by the brktETH's owner's multisig for 
them to be converted into brkETH after escrow breaks.

### BridgeEscrow
This is the contract meant to be deployed on L1 Ethereum and this will allow the assets to be bridged
to Arbitrum through the official Arbitrum bridge after escrow breaks.

### EscrowBase
This contains all the escrow functionality and is the contract from which both `MainEscrow` and 
`BridgeEscrow` contracts inherit from. For more information about each function functionality 
check the natspec in `IEscrow`.

## Instructions

To build do `forge b` to run tests do `forge t`