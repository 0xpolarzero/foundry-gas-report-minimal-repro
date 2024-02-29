import { loadFixture } from '@nomicfoundation/hardhat-toolbox-viem/network-helpers';
import { viem } from 'hardhat';
import { Address, maxUint256 } from 'viem';

const { deployContract, getPublicClient } = viem;

// Airdrop data
import airdropTokens from '../constants/airdropTokens.json';
import totalAmounts from '../constants/totalAmounts.json';

describe('GasliteDrop1155', function () {
  // Deploy a mock ERC1155, airdrop contracts, and prepare airdrop function
  const deployMockAndContractFixture = async () => {
    /* --------------------------------- PREPARE -------------------------------- */
    const publicClient = await getPublicClient();

    // Deploy contracts
    const mockERC1155 = await deployContract('MockERC1155', [
      // ids
      Array.from({ length: totalAmounts.length }, (_, i) => BigInt(i)),
      // amounts to batch mint
      totalAmounts.map((amount) => BigInt(amount)),
    ]);

    const gasliteDrop1155 = await deployContract('GasliteDrop1155');

    /* -------------------------------- FUNCTIONS ------------------------------- */
    // Create a function to airdrop with both contracts and return the gas used
    const airdropAndReturnGasUsed = async (): Promise<bigint> => {
      // Approve
      await mockERC1155.write.setApprovalForAll([
        gasliteDrop1155.address,
        true,
      ]);
      // Airdrop
      const txHash = await gasliteDrop1155.write.airdropERC1155([
        mockERC1155.address,
        // Format types
        airdropTokens.map((token) => ({
          tokenId: BigInt(token.tokenId),
          airdropAmounts: token.airdropAmounts.map((amount) => ({
            amount: BigInt(amount.amount),
            recipients: amount.recipients.map(
              (recipient) => recipient as Address
            ),
          })),
        })),
      ]);
      const txReceipt = await publicClient.waitForTransactionReceipt({
        hash: txHash,
      });

      // Get gas used
      return txReceipt.gasUsed;
    };

    return { airdropAndReturnGasUsed };
  };

  describe('airdropERC1155', function () {
    // Caller: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
    // GasliteDrop1155: 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
    // MockERC1155: 0x5FbDB2315678afecb367f032d93F642f64180aa3
    it('gas used', async function () {
      const { airdropAndReturnGasUsed } = await loadFixture(
        deployMockAndContractFixture
      );
      const gasUsed = await airdropAndReturnGasUsed();
      console.log(gasUsed.toString());
    });
  });
});
