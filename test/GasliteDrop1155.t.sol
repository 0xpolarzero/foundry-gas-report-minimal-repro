// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test, console2 as console} from "forge-std/Test.sol";
import {GasliteDrop1155} from "src/GasliteDrop1155.sol";
import {MockERC1155} from "src/Mock.ERC1155.sol";

contract GasliteDrop1155Test is Test {
    GasliteDrop1155 gasliteDrop;
    MockERC1155 mockERC1155;

    address CALLER = address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);

    function setUp() public {
        // Deploy mock
        uint256[] memory ids = new uint256[](1);
        uint256[] memory amounts = new uint256[](1);
        ids[0] = uint256(0);
        amounts[0] = uint256(100000);
        vm.startPrank(CALLER);
        mockERC1155 = new MockERC1155(ids, amounts);

        // Deploy GasliteDrop1155
        gasliteDrop = new GasliteDrop1155();
        mockERC1155.setApprovalForAll(address(gasliteDrop), true);
        vm.stopPrank();
    }

    // Caller: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
    // GasliteDrop1155: 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
    // MockERC1155: 0x5FbDB2315678afecb367f032d93F642f64180aa3
    function test_airdropERC1155() public {
        GasliteDrop1155.AirdropToken[] memory airdropTokens = new GasliteDrop1155.AirdropToken[](1);
        airdropTokens[0].tokenId = 0;
        airdropTokens[0].airdropAmounts = new GasliteDrop1155.AirdropTokenAmount[](1);
        airdropTokens[0].airdropAmounts[0] =
            GasliteDrop1155.AirdropTokenAmount({amount: 100000, recipients: new address[](1)});
        airdropTokens[0].airdropAmounts[0].recipients[0] = 0x4b4cb50369ABBb16212D50A79e1f1e06eF21cf6F;

        vm.prank(CALLER);
        gasliteDrop.airdropERC1155(address(mockERC1155), airdropTokens);
    }
}
