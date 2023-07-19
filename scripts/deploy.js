const { ethers, upgrades } = require('hardhat');

async function main () {
  const StarterNFT = await ethers.getContractFactory('StarterUpgradeable');
  console.log('Deploying StarterUpgradeable...');
  
  const salePrice = 0.001 * 10 ** 18;
  const baseURI = "https://bafkreicxq6qhnjuprktza3wkamb2usj23u3qwoxinad7ksr3kwebczfhiy.ipfs.nftstorage.link/";
  const contractURI = "https://bafkreiahdril4un5iyp3jsme5w7huhhsfckudozfeou3m7sltkv6cgo7w4.ipfs.nftstorage.link/";

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
