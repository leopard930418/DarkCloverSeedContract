async function main() {
  const team_address = "0x24be59F617ff5B93528F1471b80c1592eFfdF423";
  const marketing_address = "0x6B630A52F5Ec882A78B504065AED16a8C704c609";
  const seedFT_address = "0xd382C8B6817536513aa3990252c18B52A0828eE9"
  const seedPotion_address = "0x98Cc9036e2e5fE7EEeD212298E57D62C806fd959"
  // const seedNFT_address = "0x9F46Aeb26b37921574b9C614Ce869D1d481cCE9c"
  // const seedController_address = "0xC1FA1087f8b5e1242028Dce7d257d48579e807b1"
  // const seedPicker_address = "0xc5199467A5e1cBC19ecfd0Bb6CFEfFaE9a1349f8"


  // const seedFT = await ethers.getContractFactory("CloverDarkSeedToken");
  const seedNFT = await ethers.getContractFactory("CloverDarkSeedNFT");
  const seedController = await ethers.getContractFactory("CloverDarkSeedController");
  const seedPicker= await ethers.getContractFactory("CloverDarkSeedPicker");
  const seedStake= await ethers.getContractFactory("CloverDarkSeedStake" ,{
    libraries: {
      IterableMapping: "0xdfE52d83395cdB4276E7118cdd90d4f915888Cb6",
    }
  });
  const seedPotion= await ethers.getContractFactory("CloverDarkSeedPotion");

  // const seedFTContract = await seedFT.deploy(team_address, marketing_address);
  // console.log("CloverDarkSeedToken deployed to:", seedFTContract.address);
  // const seedFT_address = seedFTContract.address;

  // const seedPotionContract = await seedPotion.deploy(marketing_address);
  // console.log("CloverDarkSeedPotion deployed to:", seedPotionContract.address);
  // const seedPotion_address = seedPotionContract.address;

  const seedNFTContract = await seedNFT.deploy(seedFT_address);
  console.log("CloverDarkSeedNFT deployed to:", seedNFTContract.address);
  const seedNFT_address = seedNFTContract.address;

  const seedControllerContract = await seedController.deploy(team_address, seedFT_address, seedNFT_address, seedPotion_address) ;
  console.log("CloverDarkSeedController deployed to:", seedControllerContract.address);
  const seedController_address = seedControllerContract.address;

  const seedPickerContract = await seedPicker.deploy(seedNFT_address, seedController_address) ;
  console.log("CloverDarkSeedPicker deployed to:", seedPickerContract.address);
  const seedPicker_address = seedPickerContract.address;

  const seedStakeContract = await seedStake.deploy(marketing_address, seedFT_address, seedNFT_address, seedController_address, seedPicker_address);
  console.log("CloverDarkSeedStake deployed to:", seedStakeContract.address);

}

main()
.then(() => process.exit(0))
.catch((error) => {
  console.error(error);
  process.exit(1);
});