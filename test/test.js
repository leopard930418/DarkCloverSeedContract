const { expect } = require("chai");
const { ethers } = require("hardhat");

let team_address = "0x24be59F617ff5B93528F1471b80c1592eFfdF423";
let marketing_address = "0x6B630A52F5Ec882A78B504065AED16a8C704c609";

describe("My Test!", function() {
  it("Mint function test", async function() {
    const [owner, owner1, owner2] = await ethers.getSigners();
    team_address = owner1.address;
    marketing_address = owner2.address;

    const IterableMapping = await ethers.getContractFactory("IterableMapping");
    const IterableMappingContract = await IterableMapping.deploy();

    const seedFT = await ethers.getContractFactory("CloverDarkSeedToken");
    const seedPotion = await ethers.getContractFactory("CloverDarkSeedPotion");
    const seedNFT = await ethers.getContractFactory("CloverDarkSeedNFT");
    const seedController = await ethers.getContractFactory("CloverDarkSeedController");
    const seedPicker= await ethers.getContractFactory("CloverDarkSeedPicker");

    const seedStake= await ethers.getContractFactory("CloverDarkSeedStake" ,{
      libraries: {
        IterableMapping: IterableMappingContract.address,
      }
    });

    const seedFTContract = await seedFT.deploy(team_address, marketing_address);
    console.log("CloverDarkSeedToken deployed to:", seedFTContract.address);
    await seedFTContract.deployed();

    const seedPotionContract = await seedPotion.deploy(marketing_address);
    console.log("CloverDarkSeedPotion deployed to:", seedPotionContract.address);
    await seedPotionContract.deployed();

    const seedNFTContract = await seedNFT.deploy(seedFTContract.address);
    console.log("CloverDarkSeedNFT deployed to:", seedNFTContract.address);
    await seedNFTContract.deployed();

    const seedControllerContract = await seedController.deploy(team_address, seedFTContract.address, seedNFTContract.address,  seedPotionContract.address) ;
    console.log("CloverDarkSeedController deployed to:", seedControllerContract.address);
    await seedControllerContract.deployed();

    const seedPickerContract = await seedPicker.deploy(seedNFTContract.address, seedControllerContract.address) ;
    console.log("CloverDarkSeedPicker deployed to:", seedPickerContract.address);
    await seedPickerContract.deployed();

    const seedStakeContract = await seedStake.deploy(marketing_address, seedFTContract.address, seedNFTContract.address, seedControllerContract.address, seedPickerContract.address);
    console.log("CloverDarkSeedStake deployed to:", seedStakeContract.address);
    await seedStakeContract.deployed();

    await seedFTContract.AddController(seedNFTContract.address);
    await seedFTContract.AddController(seedControllerContract.address);
    await seedFTContract.AddController(seedStakeContract.address);
    await seedFTContract.setTrading(true);

    await seedNFTContract.addMinter(seedControllerContract.address);
    await seedNFTContract.setDarkSeedPicker(seedPickerContract.address);
    await seedNFTContract.setController(seedControllerContract.address);
    await seedNFTContract.setApprover(seedStakeContract.address);

    await seedControllerContract.setCloverDarkSeedPicker(seedPickerContract.address);
    await seedControllerContract.setCloverDarkSeedStake(seedStakeContract.address);
    await seedControllerContract.ActiveThisContract();

    await seedStakeContract.enableStaking();
    await seedStakeContract.enableClaimFunction();

    await seedPickerContract.setBaseURIFieldCarbon("https://ipfs.io/ipfs/QmZZFVLnwmJ5SBev4v337giMVSYxQuEBV5dzyAyzwSDESc/");
    await seedPickerContract.setBaseURIFieldDiamond("https://ipfs.io/ipfs/QmefEjS8ohnTR4VoBtCHFBGpv2PGMLeBHXHEkgUGs2ZeRw/");
    await seedPickerContract.setBaseURIFieldPearl("https://ipfs.io/ipfs/QmWy3rbUwmVtQQzZ3HGxivvqzz2EGsGDtWqLdcjxUdJxAo/");
    await seedPickerContract.setBaseURIFieldRuby("https://ipfs.io/ipfs/QmWKMynTu3jVsCFheNajEBv8ahM2X9Tqt2jhLtzsarGNvw/");

    await seedPickerContract.setBaseURIYardCarbon("https://ipfs.io/ipfs/QmZZFVLnwmJ5SBev4v337giMVSYxQuEBV5dzyAyzwSDESc/");
    await seedPickerContract.setBaseURIYardDiamond("https://ipfs.io/ipfs/QmefEjS8ohnTR4VoBtCHFBGpv2PGMLeBHXHEkgUGs2ZeRw/");
    await seedPickerContract.setBaseURIYardPearl("https://ipfs.io/ipfs/QmWy3rbUwmVtQQzZ3HGxivvqzz2EGsGDtWqLdcjxUdJxAo/");
    await seedPickerContract.setBaseURIYardRuby("https://ipfs.io/ipfs/QmWKMynTu3jVsCFheNajEBv8ahM2X9Tqt2jhLtzsarGNvw/");

    await seedPickerContract.setBaseURIPotCarbon("https://ipfs.io/ipfs/QmZZFVLnwmJ5SBev4v337giMVSYxQuEBV5dzyAyzwSDESc/");
    await seedPickerContract.setBaseURIPotDiamond("https://ipfs.io/ipfs/QmefEjS8ohnTR4VoBtCHFBGpv2PGMLeBHXHEkgUGs2ZeRw/");
    await seedPickerContract.setBaseURIPotPearl("https://ipfs.io/ipfs/QmWy3rbUwmVtQQzZ3HGxivvqzz2EGsGDtWqLdcjxUdJxAo/");
    await seedPickerContract.setBaseURIPotRuby("https://ipfs.io/ipfs/QmWKMynTu3jVsCFheNajEBv8ahM2X9Tqt2jhLtzsarGNvw/");

    console.log("expected rate : carbon --- 49 : pearl --- 49");

    for(let i = 0; i < 100; i ++) {
      const entropy = Math.floor(Math.random() * 1000000);
      await seedControllerContract.buyCloverField(entropy);
    }
    let cloverCarbon = await seedPickerContract.totalCloverFieldCarbonMinted();
    let cloverDiamond = await seedPickerContract.totalCloverFieldDiamondMinted();
    let cloverPearl = await seedPickerContract.totalCloverFieldPearlMinted();
    let cloverRuby = await seedPickerContract.totalCloverFieldRubyMinted();
    console.log(`result rate : carbon --- ${cloverCarbon} : diamond --- ${cloverDiamond} : pearl --- ${cloverPearl} : ruby --- ${cloverRuby}`);

    console.log("expected rate : carbon --- 49 : pearl --- 49");

    for(let i = 0; i < 100; i ++) {
      const entropy = Math.floor(Math.random() * 1000000);
      await seedControllerContract.buyCloverYard(entropy);
    }
    cloverCarbon = await seedPickerContract.totalCloverYardCarbonMinted();
    cloverDiamond = await seedPickerContract.totalCloverYardDiamondMinted();
    cloverPearl = await seedPickerContract.totalCloverYardPearlMinted();
    cloverRuby = await seedPickerContract.totalCloverYardRubyMinted();
    console.log(`result rate : carbon --- ${cloverCarbon} : diamond --- ${cloverDiamond} : pearl --- ${cloverPearl} : ruby --- ${cloverRuby}`);

    console.log("expected rate : carbon --- 49 : pearl --- 49");

    for(let i = 0; i < 100; i ++) {
      const entropy = Math.floor(Math.random() * 1000000);
      await seedControllerContract.buyCloverPot(entropy);
    }
    cloverCarbon = await seedPickerContract.totalCloverPotCarbonMinted();
    cloverDiamond = await seedPickerContract.totalCloverPotDiamondMinted();
    cloverPearl = await seedPickerContract.totalCloverPotPearlMinted();
    cloverRuby = await seedPickerContract.totalCloverPotRubyMinted();
    console.log(`result rate : carbon --- ${cloverCarbon} : diamond --- ${cloverDiamond} : pearl --- ${cloverPearl} : ruby --- ${cloverRuby}`);
  });
});