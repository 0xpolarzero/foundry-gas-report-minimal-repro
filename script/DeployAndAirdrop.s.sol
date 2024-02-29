// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Script} from "forge-std/Script.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {LibString} from "@solady/utils/LibString.sol";

import {GasliteDrop1155} from "src/GasliteDrop1155.sol";
import {MockERC1155} from "src/Mock.ERC1155.sol";

/// @dev Deploy the mock contract, mint and airdrop tokens
// forge script script/DeployAndAirdrop.s.sol:DeployAndAirdrop --rpc-url $RPC_URL_SEPOLIA --broadcast -vvvv

contract DeployAndAirdrop is Script {
    GasliteDrop1155 gasliteDrop;
    MockERC1155 mockERC1155;

    GasliteDrop1155.AirdropToken[] airdropTokens;
    uint256[] totalAmounts;

    function run() public {
        (airdropTokens, totalAmounts) = getAirdropData();
        uint256[] memory ids = new uint256[](totalAmounts.length);
        for (uint256 i = 0; i < totalAmounts.length; i++) {
            ids[i] = i;
        }

        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        mockERC1155 = new MockERC1155(ids, totalAmounts);

        gasliteDrop = new GasliteDrop1155();
        mockERC1155.setApprovalForAll(address(gasliteDrop), true);

        gasliteDrop.airdropERC1155(address(mockERC1155), airdropTokens);
        vm.stopBroadcast();
    }

    /* -------------------------------------------------------------------------- */
    /*                                    UTILS                                   */
    /* -------------------------------------------------------------------------- */

    function getAirdropData()
        internal
        view
        returns (GasliteDrop1155.AirdropToken[] memory airdropTokens, uint256[] memory totalAmounts)
    {
        // Retrieve the array of amounts for each id
        string memory totalAmountsRaw = vm.readFile("./constants/totalAmounts.json");
        totalAmounts = abi.decode(stdJson.parseRaw(totalAmountsRaw, ""), (uint256[]));

        // Retrieve the airdrop tokens for each id
        string memory airdropTokensRaw = vm.readFile("./constants/airdropTokens.json");
        airdropTokens = new GasliteDrop1155.AirdropToken[](totalAmounts.length);

        for (uint256 i = 0; i < totalAmounts.length; i++) {
            GasliteDrop1155.AirdropTokenAmount[] memory airdropAmounts = abi.decode(
                stdJson.parseRaw(airdropTokensRaw, string.concat("[", LibString.toString(i), "].airdropAmounts")),
                (GasliteDrop1155.AirdropTokenAmount[])
            );
            airdropTokens[i] = GasliteDrop1155.AirdropToken({tokenId: i, airdropAmounts: airdropAmounts});
        }
    }
}
