const { ethers, upgrades } = require('hardhat');

async function main () {
  const StarterNFT = await ethers.getContractFactory('StarterUpgradeable');
  console.log('Deploying StarterUpgradeable...');
  
  const salePrice = 0.001 * 10 ** 18;
  const baseURI = "https://bafybeif76n3fsq55yzn5aewdwolaszl2w6azipfybkmf6m6r5ucqommmfm.ipfs.nftstorage.link/";
  const contractURI = "";

  const initArgs = {
    name: 'Ninja Starter', 
    symbol: 'NINJA', 
    mintingPhase: 1,
    maxSupply: 1000,
    salePrice, 
    maxPerWallet: 20,
    crossmintWallet: "0x13253aa4Abe1861124d4c286Ee4374cD054D3eb9",
    withdrawWallet: "0x6C3b3225759Cbda68F96378A9F0277B4374f9F06",
    baseURI, 
    contractURI,
    numberedMetadata: false,
  };
  const starter = await upgrades.deployProxy(StarterNFT, [initArgs]);
  await starter.deployed();
  console.log('starter contract deployed to:', starter.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
