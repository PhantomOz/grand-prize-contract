import {
  time,
  loadFixture,
} from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers } from "hardhat";

describe("GrandPrize", function(){
    async function deployGrandPrize() {
        const GrandPrize = await ethers.getContractFactory("GrandPrize");
        const grandPrize = await GrandPrize.deploy();

        return {grandPrize}
    }

    describe("registerAsParticipant", function(){
        it("Should register User successfully", async function() {
            const {grandPrize} = await loadFixture(deployGrandPrize);
            await grandPrize.registerAsParticipant();
            await expect(await grandPrize.s_totalParticipants()).to.eq(1);
        });
        it("Should revert when duplicate user", async function() {
            const {grandPrize} = await loadFixture(deployGrandPrize);
            await grandPrize.registerAsParticipant();
            await expect(grandPrize.registerAsParticipant()).to.be.revertedWithCustomError(grandPrize, "GrandPrize__AlreadyAParticipant");
        });
    });
});