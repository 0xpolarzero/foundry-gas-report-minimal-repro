// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Script} from "forge-std/Script.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {LibString} from "@solady/utils/LibString.sol";
import {LibClone} from "@solady/utils/LibClone.sol";
import {console} from "forge-std/console.sol";

import "src/thirdweb/AirdropERC1155.sol";
import {GasliteDrop1155} from "src/GasliteDrop1155.sol";
import {MockERC1155} from "src/Mock.ERC1155.sol";

/// @dev Deploy the mock contract, mint and airdrop tokens
// forge script script/DeployAndAirdropThirdweb.s.sol:DeployAndAirdropThirdweb --rpc-url $RPC_URL_SEPOLIA --broadcast -vvvv

contract DeployAndAirdropThirdweb is Script {
    AirdropERC1155 airdropERC1155;
    MockERC1155 mockERC1155;

    function run() public {
        (IAirdropERC1155.AirdropContent[] memory airdropContents, uint256[] memory totalAmounts) = getAirdropData();
        uint256[] memory ids = new uint256[](totalAmounts.length);
        for (uint256 i = 0; i < totalAmounts.length; i++) {
            ids[i] = i;
        }

        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        mockERC1155 = new MockERC1155(ids, totalAmounts);

        airdropERC1155 = AirdropERC1155(LibClone.deployERC1967(address(new AirdropERC1155())));
        airdropERC1155.initialize(
            address(0xAD285b5dF24BDE77A8391924569AF2AD2D4eE4A7), "https://example.com", new address[](0)
        );
        mockERC1155.setApprovalForAll(address(airdropERC1155), true);

        airdropERC1155.airdropERC1155(
            address(mockERC1155), address(0xAD285b5dF24BDE77A8391924569AF2AD2D4eE4A7), airdropContents
        );
        vm.stopBroadcast();
    }

    /* -------------------------------------------------------------------------- */
    /*                                    UTILS                                   */
    /* -------------------------------------------------------------------------- */

    function getAirdropData()
        internal
        view
        returns (IAirdropERC1155.AirdropContent[] memory airdropContents, uint256[] memory totalAmounts)
    {
        // Retrieve the array of amounts for each id
        string memory totalAmountsRaw = vm.readFile("./constants/totalAmounts.json");
        totalAmounts = abi.decode(stdJson.parseRaw(totalAmountsRaw, ""), (uint256[]));

        // Retrieve the airdrop tokens for each id
        string memory airdropTokensRaw = vm.readFile("./constants/airdropTokens.json");
        airdropContents = new IAirdropERC1155.AirdropContent[](500);
        uint256 airdropContentsIndex = 0;
        for (uint256 i = 0; i < totalAmounts.length; i++) {
            GasliteDrop1155.AirdropTokenAmount[] memory airdropAmounts = abi.decode(
                stdJson.parseRaw(airdropTokensRaw, string.concat("[", LibString.toString(i), "].airdropAmounts")),
                (GasliteDrop1155.AirdropTokenAmount[])
            );
            for (uint256 j = 0; j < airdropAmounts.length; j++) {
                for (uint256 k = 0; k < airdropAmounts[j].recipients.length; k++) {
                    airdropContents[airdropContentsIndex] = IAirdropERC1155.AirdropContent({
                        recipient: airdropAmounts[j].recipients[k],
                        tokenId: i,
                        amount: airdropAmounts[j].amount
                    });
                    airdropContentsIndex++;
                }
            }
        }
    }
}
