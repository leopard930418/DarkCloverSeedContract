const team_address = "0x24be59F617ff5B93528F1471b80c1592eFfdF423";
const marketing_address = "0x6B630A52F5Ec882A78B504065AED16a8C704c609";

async function main() {

  const iterableLib = await ethers.getContractFactory("IterableMapping");
  const iterableLibContract = await iterableLib.deploy();
  console.log("IterableMapping deployed to:", iterableLibContract.address);
  // const seedFT = await ethers.getContractFactory("Clover_Seeds_Token");
  // const seedFTContract = await seedFT.deploy(team_address, marketing_address);
  // console.log("Clover_Seeds_Token deployed to:", seedFTContract.address);

  // const seedStake= await ethers.getContractFactory("Clover_Seeds_Stake" ,{
  //     libraries: {
  //     IterableMapping: "0xdfE52d83395cdB4276E7118cdd90d4f915888Cb6",
  //   }
  // });
  // const seedStakeContract = await seedStake.deploy(marketing_address
  //   , "0xe98D562A0366a789E5a1bb3EC788a778F17ef922"
  //   , "0xE49eEE34F7816F274a32426A98E2F2cAd0C020ea"
  //   , "0xE69191B4CBc9e64F00A5192960cD6a40b8E99263"
  //   , "0x203E89ACfD139933a0C1675A2A38371877a7d6d0"
  // );
  // console.log("Clover_Seeds_Stake deployed to:", seedStakeContract.address);
}

main()
.then(() => process.exit(0))
.catch((error) => {
  console.error(error);
  process.exit(1);
});