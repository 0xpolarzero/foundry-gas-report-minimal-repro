import { loadFixture } from '@nomicfoundation/hardhat-toolbox-viem/network-helpers';
import { viem } from 'hardhat';
import { Address, maxUint256 } from 'viem';

const { deployContract, getPublicClient } = viem;

// Airdrop data
const airdropData = [
  {
    tokenId: BigInt(0),
    airdropAmounts: [
      {
        amount: BigInt(100000),
        recipients: ['0x4b4cb50369ABBb16212D50A79e1f1e06eF21cf6F' as Address],
      },
    ],
  },
];
const IDS = [BigInt(0)];

describe('GasliteDrop1155', function () {
  // Deploy a mock ERC1155, airdrop contracts, and prepare airdrop function
  const deployMockAndContractFixture = async () => {
    /* --------------------------------- PREPARE -------------------------------- */
    const publicClient = await getPublicClient();

    // Deploy contracts
    const mockERC1155 = await deployContract('MockERC1155', [
      // Mint the max amount for each id
      IDS,
      Array.from({ length: IDS.length }, () => maxUint256),
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
        airdropData,
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
      console.log(gasUsed);
    });
  });
});
