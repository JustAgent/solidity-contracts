// const { time, loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
// const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
// const { expect } = require("chai");

// describe('Marketplace', function () {

//     async function deployOneYearLockFixture() {
       
//         const [owner, otherAccount] = await ethers.getSigners();

//         const Marketplace = await ethers.getContractFactory("Marketplace");
//         const market = await Marketplace.deploy(owner.address);

//         return { market, owner, otherAccount }
//     }

//     describe('SMT', function () {
//         it("10 test", async function () {
//             const { market} = await loadFixture(deployOneYearLockFixture);
      
//             expect(await market.getTotalOrders()).to.equal(0);
//           });
//     })

// })