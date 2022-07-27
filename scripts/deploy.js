
const hre = require("hardhat");
const keccak256 = require("keccak256");
const { default: MerkleTree } = require("merkletreejs");


let proxyAddressRinkyby = "0xf57b2c51ded3a29e6891aba85459d600256cf317";
// ipfs base uri 
let uri = "ipfs://QmNyMTujkRwmxAb5xviYh6YrkUELH5DtjjzvWiKyTHxm8Z/";
// whitelist addresses 
const listAddresses = [
  "0x383ec8EFb4EAA1f62DF1A39B83CD2854D2ad2244",
  "0x94FC1035713F7a2DAae589EA3F7a4494650240f7",
];

async function main() {
  let leaves = listAddresses.map((addr) => keccak256(addr));
  let tree = new MerkleTree(leaves, keccak256, { sortPairs: true });
  let root = tree.getRoot();

  const pakoNft = await ethers.getContractFactory("PakoNFT");
  const pako = await pakoNft.deploy(uri, root,proxyAddressRinkyby);

  await pako.deployed();

  console.log("Lock with 1 ETH deployed to:", pako.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.log(error);
    process.exit(1);
  });

  // contract address 
  // 0xC85Ada7E69174E9474e154A3fB684e41A22c9749
