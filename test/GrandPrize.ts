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
            const closeTime = await time.latestBlock();
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

    describe("joinActivity", function(){
        it("Should allow particant join activity", async function(){
            const {grandPrize, secondAccount} = await loadFixture(deployGrandPrize);
            const currentTimestampInSeconds = Math.round(Date.now() / 1000);
            const closeTime = currentTimestampInSeconds + 60;
            await grandPrize.connect(secondAccount).registerAsParticipant();
            await grandPrize.createActivity("This Task is to credit account with 5 Eth", 0, 5, 5000, 0, closeTime, 3);
            await expect(await grandPrize.connect(secondAccount).joinActivity(0)).to.emit(grandPrize, "JoinedActivity").withArgs(secondAccount.address, 0, 0);
        });
        it("Should not allow non participant", async function(){
            const {grandPrize, secondAccount} = await loadFixture(deployGrandPrize);
            const currentTimestampInSeconds = Math.round(Date.now() / 1000);
            const closeTime = currentTimestampInSeconds + 60;
            await grandPrize.connect(secondAccount).registerAsParticipant();
            await grandPrize.createActivity("This Task is to credit account with 5 Eth", 0, 5, 5000, 0, closeTime, 3);
            await expect(grandPrize.joinActivity(0)).to.be.revertedWithCustomError(grandPrize, "GrandPrize__NotAParticipant");
        });
        it("Should revert if index is out of bound", async function(){
            const {grandPrize, secondAccount} = await loadFixture(deployGrandPrize);
            const currentTimestampInSeconds = Math.round(Date.now() / 1000);
            const closeTime = currentTimestampInSeconds + 60;
            await grandPrize.connect(secondAccount).registerAsParticipant();
            await grandPrize.createActivity("This Task is to credit account with 5 Eth", 0, 5, 5000, 0, closeTime, 3);
            await expect(grandPrize.connect(secondAccount).joinActivity(1)).to.be.revertedWithCustomError(grandPrize, "GrandPrize__IndexOutOfBounds");
        });
        it("Should revert participant already Joined", async function(){
            const {grandPrize, secondAccount} = await loadFixture(deployGrandPrize);
            const currentTimestampInSeconds = Math.round(Date.now() / 1000);
            const closeTime = currentTimestampInSeconds + 60;
            await grandPrize.connect(secondAccount).registerAsParticipant();
            await grandPrize.createActivity("This Task is to credit account with 5 Eth", 0, 5, 5000, 0, closeTime, 3);
            await grandPrize.connect(secondAccount).joinActivity(0);
            await expect(grandPrize.connect(secondAccount).joinActivity(0)).to.be.revertedWithCustomError(grandPrize, "GrandPrize__AlreadyJoinedActivity");
        });
        it("Should revert if entryfee not met", async function(){
            const {grandPrize, secondAccount} = await loadFixture(deployGrandPrize);
            const currentTimestampInSeconds = Math.round(Date.now() / 1000);
            const closeTime = currentTimestampInSeconds + 60;
            await grandPrize.connect(secondAccount).registerAsParticipant();
            await grandPrize.createActivity("This Task is to credit account with 5 Eth", 1, 5, 5000, 0, closeTime, 3);
            await expect(grandPrize.connect(secondAccount).joinActivity(0)).to.be.revertedWithCustomError(grandPrize, "GrandPrize__InsufficientEntryFee");
        });
    });

    describe("SubmitEntry", function(){
        it("Should allow particant submit entry", async function(){
            const {grandPrize, secondAccount} = await loadFixture(deployGrandPrize);
            const currentTimestampInSeconds = Math.round(Date.now() / 1000);
            const closeTime = currentTimestampInSeconds + 60;
            await grandPrize.connect(secondAccount).registerAsParticipant();
            await grandPrize.createActivity("This Task is to credit account with 5 Eth", 0, 5, 5000, 0, closeTime, 3);
            await grandPrize.connect(secondAccount).joinActivity(0);
            await expect(await grandPrize.connect(secondAccount).submitEntry(0, "This task is easy", {value: 5000})).to.emit(grandPrize, "EntrySubmitted").withArgs(secondAccount.address, 0, 5000);
        });
        it("Should revert if index is out of bounds", async function(){
            const {grandPrize, secondAccount} = await loadFixture(deployGrandPrize);
            const currentTimestampInSeconds = Math.round(Date.now() / 1000);
            const closeTime = currentTimestampInSeconds + 60;
            await grandPrize.connect(secondAccount).registerAsParticipant();
            await grandPrize.createActivity("This Task is to credit account with 5 Eth", 0, 5, 5000, 0, closeTime, 3);
            await grandPrize.connect(secondAccount).joinActivity(0);
            await expect(grandPrize.connect(secondAccount).submitEntry(1, "This task is easy", {value: 5})).to.be.revertedWithCustomError(grandPrize, "GrandPrize__IndexOutOfBounds");
        });
        it("Should revert address is not participant", async function(){
            const {grandPrize, secondAccount} = await loadFixture(deployGrandPrize);
            const currentTimestampInSeconds = Math.round(Date.now() / 1000);
            const closeTime = currentTimestampInSeconds + 60;
            await grandPrize.connect(secondAccount).registerAsParticipant();
            await grandPrize.createActivity("This Task is to credit account with 5 Eth", 0, 5, 5000, 0, closeTime, 3);
            await grandPrize.connect(secondAccount).joinActivity(0);
            await expect(grandPrize.submitEntry(0, "This task is easy", {value: 5000})).to.be.revertedWithCustomError(grandPrize, "GrandPrize__NotJoinedActivity");
        });
        it("Should revert if task length is short", async function(){
            const {grandPrize, secondAccount} = await loadFixture(deployGrandPrize);
            const currentTimestampInSeconds = Math.round(Date.now() / 1000);
            const closeTime = currentTimestampInSeconds + 60;
            await grandPrize.connect(secondAccount).registerAsParticipant();
            await grandPrize.createActivity("This Task is to credit account with 5 Eth", 0, 0, 5000, 1, closeTime, 3);
            await grandPrize.connect(secondAccount).joinActivity(0);
            await expect(grandPrize.connect(secondAccount).submitEntry(0, "Thi", {value: 5000})).to.be.revertedWithCustomError(grandPrize, "GrandPrize__TaskLengthTooShort");
        });
        it("Should revert if gameValue is low", async function(){
            const {grandPrize, secondAccount} = await loadFixture(deployGrandPrize);
            const currentTimestampInSeconds = Math.round(Date.now() / 1000);
            const closeTime = currentTimestampInSeconds + 60;
            await grandPrize.connect(secondAccount).registerAsParticipant();
            await grandPrize.createActivity("This Task is to credit account with 5 Eth", 0, 5, 5000, 0, closeTime, 3);
            await grandPrize.connect(secondAccount).joinActivity(0);
            await expect(grandPrize.connect(secondAccount).submitEntry(0, "Thi", {value: 4})).to.be.revertedWithCustomError(grandPrize, "GrandPrize__GameValueTooLow");
        });
    });
});