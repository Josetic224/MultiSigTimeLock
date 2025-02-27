import "@nomiclabs/hardhat-ethers";
import { ethers } from "hardhat";

async function main() {
  const Base64NFT = await ethers.getContractFactory("MultiSig");
  const nft = await Base64NFT.deploy();
  await nft.waitForDeployment();

  const nftAddress = await nft.getAddress(); // Await the promise
  console.log("Base64NFT deployed to:", nftAddress);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
