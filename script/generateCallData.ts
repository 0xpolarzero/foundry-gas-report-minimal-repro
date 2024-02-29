import { writeFileSync } from 'fs';
import { Address } from 'viem';
import { generatePrivateKey, privateKeyToAddress } from 'viem/accounts';

/* -------------------------------------------------------------------------- */
/*                                  CONSTANTS                                 */
/* -------------------------------------------------------------------------- */

// How many recipients to airdrop to
const NUM_RECIPIENTS = 500;
// The ids to airdrop [0, NUM_IDS - 1]
const NUM_IDS = 10;
// The min/max amount to airdrop
const MIN_AMOUNT = BigInt(1e10);
// don't go too high as Number() would lose precision, but it's the easiest way
// to parse it in the test contract
const MAX_AMOUNT = BigInt(1e14);

const OUTPUT_FILES = {
  airdropTokens: 'constants/airdropTokens.json',
  totalAmounts: 'constants/totalAmounts.json',
};

/* -------------------------------------------------------------------------- */
/*                                    TYPES                                   */
/* -------------------------------------------------------------------------- */

// Raw airdrop data
type AirdropData = {
  recipients: Address[];
  ids: bigint[];
  amounts: bigint[];
};

// Formatted airdrop data
type AirdropToken = {
  tokenId: number;
  airdropAmounts: {
    amount: number;
    recipients: Address[];
  }[];
};

// Format airdrop data function
type FormatAirdropData = (airdropData: AirdropData) => {
  airdropTokens: AirdropToken[];
  totalAmounts: number[];
};

/* -------------------------------------------------------------------------- */
/*                                    UTILS                                   */
/* -------------------------------------------------------------------------- */

// Generate random airdrop data for the given entropy
const generateRandomAirdropData = (entropy: number): AirdropData => {
  // Get random addresses
  const recipients = Array.from({ length: NUM_RECIPIENTS }, () =>
    privateKeyToAddress(generatePrivateKey())
  );

  // Get random ids
  const ids = Array.from({ length: NUM_RECIPIENTS }, () =>
    BigInt(Math.floor(Math.random() * NUM_IDS))
  );

  // 1. Generate temporary random amounts for each recipient
  let preliminaryAmounts = Array.from({ length: NUM_RECIPIENTS }, () =>
    randomAmount()
  );

  // 2. Modify amounts based on the entropy
  const amounts = preliminaryAmounts.map((amount, index) => {
    // <entropy>% of the time, try to reuse an amount already used for that id
    const reuse = Math.random() < entropy / 100;
    if (reuse) {
      // Find another amount used for the same id, if available
      const sameIdIndex = ids.findIndex(
        (id, i) => id === ids[index] && i !== index
      );
      return sameIdIndex !== -1 ? preliminaryAmounts[sameIdIndex] : amount;
    }
    return amount;
  });

  return { recipients, ids, amounts };
};

// Format airdrop data for Gaslite AirdropERC1155
// [address _tokenAddress, AirdropToken[] calldata airdropTokens]
// with AirdropToken = {uint256 tokenId, AirdropTokenAmount[] airdropAmounts}
// with AirdropTokenAmount = {uint256 amount, address[] recipients}
const formatAirdropData: FormatAirdropData = ({ recipients, ids, amounts }) => {
  // Group amounts and recipients by id
  const airdropTokens: AirdropToken[] = Array.from(
    { length: NUM_IDS },
    (_, i) => i
  ).map((id) => {
    const airdropAmounts: AirdropToken['airdropAmounts'] = [];
    // For each recipient, add their amount to the corresponding id
    recipients.forEach((recipient, i) => {
      if (Number(ids[i]) === id) {
        const amount = amounts[i];
        // Find the airdropAmounts for this amount
        let airdropAmount = airdropAmounts.find(
          (a) => a.amount === Number(amount)
        ) as AirdropToken['airdropAmounts'][0];
        // If it doesn't exist, create it
        if (!airdropAmount) {
          airdropAmount = { amount: Number(amount), recipients: [] };
          airdropAmounts.push(airdropAmount);
        }
        // Add the recipient to the airdropAmount
        airdropAmount.recipients.push(recipient);
      }
    });
    return { tokenId: id, airdropAmounts };
  });

  // Find the total amount for each id
  const totalAmounts = airdropTokens.map((token) =>
    token.airdropAmounts.reduce(
      (acc, airdropAmount) =>
        acc + Number(airdropAmount.amount) * airdropAmount.recipients.length,
      0
    )
  );

  return { airdropTokens, totalAmounts };
};

const randomAmount = () =>
  MIN_AMOUNT +
  BigInt(Math.floor(Math.random() * (Number(MAX_AMOUNT) - Number(MIN_AMOUNT))));

/* -------------------------------------------------------------------------- */
/*                                 GENERATION                                 */
/* -------------------------------------------------------------------------- */

// Generate formatted airdrop data for the amount of recipients
const generateAirdropData = () => {
  const airdropData = generateRandomAirdropData(15);
  const formattedAirdropData = formatAirdropData(airdropData);
  return formattedAirdropData;
};

const main = () => {
  const { airdropTokens, totalAmounts } = generateAirdropData();
  writeFileSync(
    OUTPUT_FILES.airdropTokens,
    JSON.stringify(airdropTokens, null, 2)
  );
  writeFileSync(
    OUTPUT_FILES.totalAmounts,
    JSON.stringify(totalAmounts, null, 2)
  );
};

main();
