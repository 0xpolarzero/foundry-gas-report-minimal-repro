// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test, console2 as console} from "forge-std/Test.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {LibClone} from "@solady/utils/LibClone.sol";
import {LibString} from "@solady/utils/LibString.sol";

import "src/thirdweb/AirdropERC1155.sol";
import {GasliteDrop1155} from "src/GasliteDrop1155.sol";
import {MockERC1155} from "src/Mock.ERC1155.sol";

/// @dev Run with `forge test --mt AirdropERC1155Base --gas-report`

contract AirdropERC1155Base is Test {
    AirdropERC1155 airdropERC1155;
    MockERC1155 mockERC1155;

    address CALLER = address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);

    function setUp() public {}

    function test_airdropERC1155_base() public {
        // Retrieve airdrop data
        (IAirdropERC1155.AirdropContent[] memory airdropContents, uint256[] memory totalAmounts) = getAirdropData();
        uint256[] memory ids = new uint256[](totalAmounts.length);
        for (uint256 i = 0; i < totalAmounts.length; i++) {
            ids[i] = i;
        }

        vm.startPrank(CALLER);
        // Deploy MockERC1155
        mockERC1155 = new MockERC1155(ids, totalAmounts);

        // Deploy AirdropERC1155 and initialize
        airdropERC1155 = AirdropERC1155(LibClone.deployERC1967(address(new AirdropERC1155())));
        airdropERC1155.initialize(CALLER, "https://example.com", new address[](0));
        mockERC1155.setApprovalForAll(address(airdropERC1155), true);

        // Airdrop
        airdropERC1155.airdropERC1155(address(mockERC1155), CALLER, airdropContents);
        vm.stopPrank();
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
