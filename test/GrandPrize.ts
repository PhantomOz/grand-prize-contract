import {
  time,
  loadFixture,
} from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers } from "hardhat";

describe("GrandPrize", function(){
    async function deployGrandPrize() {
        const[owner, secondAccount] = await ethers.getSigners();
        const GrandPrize = await ethers.getContractFactory("GrandPrize");
        const grandPrize = await GrandPrize.deploy();

        return {grandPrize, owner, secondAccount}
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

    describe("createActivity", function(){
        it("Should create Activity", async function() {
            const {grandPrize, owner} = await loadFixture(deployGrandPrize);
            const currentTimestampInSeconds = Math.round(Date.now() / 1000);
            const closeTime = currentTimestampInSeconds + 60;
            await expect(await grandPrize.createActivity("This Task is to credit account with 5 Eth", 0, 5, 5000, 0, closeTime, 3)).to
                .emit(grandPrize, "NewActivity").withArgs(owner, 5000, 3, 0, closeTime);
            await expect((await grandPrize.s_activities(0))._author).to.be.eqls(owner.address);
        });
        it("Should revert with task length too short", async function() {
            const {grandPrize} = await loadFixture(deployGrandPrize);
            const currentTimestampInSeconds = Math.round(Date.now() / 1000);
            const closeTime = currentTimestampInSeconds + 60;
            await expect(grandPrize.createActivity("5Eth", 0, 5, 5000, 0, closeTime, 3)).to
                .be.revertedWithCustomError(grandPrize, "GrandPrize__TaskLengthTooShort");
        });
        it("Should revert with Prize pool too low", async function() {
            const {grandPrize} = await loadFixture(deployGrandPrize);
            const currentTimestampInSeconds = Math.round(Date.now() / 1000);
            const closeTime = currentTimestampInSeconds + 60;
            await expect(grandPrize.createActivity("This Task is to credit account with 5Eth", 0, 5, 0, 0, closeTime, 3)).to
                .be.revertedWithCustomError(grandPrize, "GrandPrize__PrizePoolTooLow");
        });
        it("Should revert with Game Value for Game", async function() {
            const {grandPrize} = await loadFixture(deployGrandPrize);
            const currentTimestampInSeconds = Math.round(Date.now() / 1000);
            const closeTime = currentTimestampInSeconds + 60;
            await expect(grandPrize.createActivity("This Task is to credit account with 5Eth", 0, 5, 5000, 1, closeTime, 3)).to
                .be.revertedWithCustomError(grandPrize, "GrandPrize__GameValueOnlyForGameType");
        });
        it("Should revert with TimeTooClose", async function() {
            const {grandPrize} = await loadFixture(deployGrandPrize);
            const closeTime = Math.round(Date.now() / 1000);
            await expect(grandPrize.createActivity("This Task is to credit account with 5Eth", 0, 5, 5000, 0, closeTime, 3)).to
                .be.revertedWithCustomError(grandPrize, "GrandPrize__TimeTooClose");
        });
        it("Should revert with Game Value for Game", async function() {
            const {grandPrize} = await loadFixture(deployGrandPrize);
            const currentTimestampInSeconds = Math.round(Date.now() / 1000);
            const closeTime = currentTimestampInSeconds + 60;
            await expect(grandPrize.createActivity("This Task is to credit account with 5Eth", 0, 5, 5000, 0, closeTime, 0)).to
                .be.revertedWithCustomError(grandPrize, "GrandPrize__WinnersMustBeGreaterThanOne");
        });
    });
});