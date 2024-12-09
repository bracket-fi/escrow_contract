import {Script} from "forge-std/Script.sol";

import {BracketEscrow} from "src/BracketEscrow.sol";

contract SetMerkleRoot is Script {
    BracketEscrow constant ESCROW = BracketEscrow(0x9b9d7297C3374DaFA2A609d47C79904e467970Bc);

    address constant TOKEN = address(0);
    bytes32 constant MERKLE_ROOT = bytes32(0x00);

    function run() public {
        vm.startBroadcast();
        ESCROW.addMerkleRoot(TOKEN, MERKLE_ROOT);
        vm.stopBroadcast();
    }
}
