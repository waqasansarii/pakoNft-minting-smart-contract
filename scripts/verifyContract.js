const hre = require("hardhat");
require("@nomiclabs/hardhat-etherscan");
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

  await hre.run("verify:verify", {
    address: "0x226a1c8dFfD5772160619A942F5C087B2D7e48ac",
    constructorArguments: [uri, root, proxyAddressRinkyby],
  });
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
// 0x226a1c8dFfD5772160619A942F5C087B2D7e48ac
