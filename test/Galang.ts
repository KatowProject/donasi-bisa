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

  describe("Deployment", function () {
    it("Should Create one Galang ID", async function () {
      const { galang } = await loadFixture(deployOneYearLockFixture);
      const me = await hre.ethers.getSigners();
      this.address = me[0].address;

      await galang.createGalang(
        this.address,
        "my galang",
        "kisah galang",
        "1000000000000000000",
        Math.floor((Date.now()) / 1000) + 6
      )
      this.galang = galang;
      expect((await galang.GalangData(0)).penggalang).to.equal(
        this.address);
    });

    it("Should deposit 0.5 eth success", async function () {
      const toDeposit = new BigNumber("500000000000000000");
      await this.galang.depo(0, { value: toDeposit.toString() });
      expect((await this.galang.GalangData(0)).terkumpul).to.equal(toDeposit);

    });

    it("Should deposit 1 eth and refunded 0.5 success", async function () {
      const toDeposit = new BigNumber("1000000000000000000");
      await this.galang.depo(0, { value: toDeposit.toString() });
      expect((await this.galang.GalangData(0)).terkumpul).to.equal(toDeposit);

    });

    it("Should revert not time", async function () {
      await expect(this.galang.withdraw(0)).to.be.revertedWith("Penggalangan Dana belum selesai");

    });

    it("Should Success withdraw", async function () {
      await sleep(5500);
      await this.galang.withdraw(0)
      
      expect((await this.galang.GalangData(0)).status).to.equal(1);

    });

  });
});
