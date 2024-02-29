// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test, console2 as console} from "forge-std/Test.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {LibString} from "@solady/utils/LibString.sol";

import {GasliteDrop1155} from "src/GasliteDrop1155.sol";
import {MockERC1155} from "src/Mock.ERC1155.sol";

/// @dev Run with `forge test --mt test_airdropERC1155_lowLevelCall --gas-report`

contract GasliteDrop1155TestLowLevelCall is Test {
    GasliteDrop1155 gasliteDrop;
    MockERC1155 mockERC1155;

    address CALLER = address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);

    bytes airdropCallData;

    function setUp() public {
        // Retrieve airdrop data
        (GasliteDrop1155.AirdropToken[] memory airdropTokens, uint256[] memory totalAmounts) = getAirdropData();
        uint256[] memory ids = new uint256[](totalAmounts.length);
        for (uint256 i = 0; i < totalAmounts.length; i++) {
            ids[i] = i;
        }

        vm.startPrank(CALLER);
        // Deploy MockERC1155
        mockERC1155 = new MockERC1155(ids, totalAmounts);

        // Deploy GasliteDrop1155
        gasliteDrop = new GasliteDrop1155();
        mockERC1155.setApprovalForAll(address(gasliteDrop), true);
        vm.stopPrank();

        // Encode airdrop data (easier this way due to writing memory array to storage, etc)
        airdropCallData = abi.encode(address(mockERC1155), airdropTokens);
    }

    // Caller: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
    // GasliteDrop1155: 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
    // MockERC1155: 0x5FbDB2315678afecb367f032d93F642f64180aa3
    function test_airdropERC1155_lowLevelCall() public {
        // Airdrop
        vm.prank(CALLER);
        address(gasliteDrop).call(airdropCallData);
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
