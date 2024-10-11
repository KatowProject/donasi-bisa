import {
  loadFixture,
} from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { expect } from "chai";
import hre from "hardhat";
import BigNumber from "bignumber.js";

async function sleep(ms: any) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}
describe("Lock", function () {
  async function deployOneYearLockFixture() {

    const Galang = await hre.ethers.getContractFactory("Galang");
    const galang = await Galang.deploy();

    return { galang };
  }

  describe("Deployment", async function () {
    let address: string;
    let galang: any;

    before(async function () {
      const fixture = await loadFixture(deployOneYearLockFixture);
      galang = fixture.galang;
      const signers = await hre.ethers.getSigners();
      address = signers[0].address;
    });

    it("Should Create one Galang ID", async function () {
      await galang.createGalang(
        "my galang",
        "kisah galang",
        "1000000000000000000",
        Math.floor((Date.now()) / 1000) + 6
      )
      expect((await galang.GalangData(0)).penggalang).to.equal(
        address);
    });

    it("Should deposit 0.5 eth success", async function () {
      const toDeposit = new BigNumber("500000000000000000");
      await galang.depo(0, { value: toDeposit.toString() });
      expect((await galang.GalangData(0)).terkumpul).to.equal(toDeposit);

    });

    it("Should deposit 1 eth and refunded 0.5 success", async function () {
      const toDeposit = new BigNumber("1000000000000000000");
      await galang.depo(0, { value: toDeposit.toString() });
      expect((await galang.GalangData(0)).terkumpul).to.equal(toDeposit);

    });

    it("Should show galang data list", async function () {
      const data = await galang.getGalangData();
      expect(data.length).to.equal(1);
    });

    it("Should get donaturs in galang", async function () {
      const data = await galang.getDonatur(0);
      expect(data.length).to.greaterThan(0);
    });

    it("Should revert not time", async function () {
      await expect(galang.withdraw(0)).to.be.revertedWith("Penggalangan Dana belum selesai");
    });

    it("Should Success withdraw", async function () {
      await sleep(5500);
      await galang.withdraw(0)

      expect((await galang.GalangData(0)).status).to.equal(1);
    });

    it('Should refund if Fraud', async function () {
      await galang.createGalang(
        "my galang",
        "kisah galang",
        "1000000000000000000",
        Math.floor((Date.now()) / 1000) + 6
      )


      const toDeposit = new BigNumber("1000000000000000000");
      await galang.depo(1, { value: toDeposit.toString() });

      await sleep(6500);

      await galang.FraudDonation(1);
      expect((await galang.GalangData(1)).status).to.equal(2);
    });
  });
});
