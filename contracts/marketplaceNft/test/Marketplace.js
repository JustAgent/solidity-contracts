const { time, loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");

describe('Marketplace', function () {


async function deployFixture() {
    
    const NFT_TEST1 = await ethers.getContractFactory("NFT_TEST1");
    const nftTest1 = await NFT_TEST1.deploy();
    const NFT_TEST2 = await ethers.getContractFactory("NFT_TEST2");
    const nftTest2 = await NFT_TEST2.deploy();

    const TokenRecipient = await ethers.getContractFactory("TokenRecipient");
    const tokenRecipient = await TokenRecipient.deploy();
    
    const Marketplace = await ethers.getContractFactory("Marketplace");
    const market = await Marketplace.deploy(tokenRecipient.address);
    await nftTest1.start()

    return {tokenRecipient, nftTest1, nftTest2, market};
}


describe("Initial", function () {

    it('Should mint the right number of nft', async function () {
        const [ owner, addr1, addr2] = await ethers.getSigners();
        const {nftTest1} = await loadFixture(deployFixture);

        
        await expect( nftTest1.mint(addr2.address, 0)).to.be.revertedWith(
            "Mint = 0"
          );

        await nftTest1.mint(addr1.address, 5)
        await nftTest1.mint(addr1.address, 5)
        await nftTest1.mint(addr2.address, 5)

        await expect( nftTest1.connect(addr1).mint(addr1.address, 1, {value: 10000000})).to.be.revertedWith(
            "Not enough funds"
          );

        await expect( nftTest1.mint(addr2.address, 50)).to.be.revertedWith(
            "Too much"
          );

        expect(await nftTest1.balanceOf(addr1.address)).to.equal(10)
        expect(await nftTest1.balanceOf(addr2.address)).to.equal(5)
    }
    )

    it("Should transfer bunch of NFT", async function () {
        const [owner, addr1, addr2] = await ethers.getSigners();
        const {market,nftTest1} = await loadFixture(deployFixture);

        await nftTest1.connect(addr1).setApprovalForAll(market.address, true)
        expect(await nftTest1.connect(addr1).isApprovedForAll(addr1.address, market.address)).to.equal(true)

        expect(await nftTest1.connect(addr1).mint(addr1.address, 4, {value: BigInt(100000000000000000)}))
        expect(await nftTest1.connect(addr1).ownerOf(1)).to.equal(addr1.address)
        expect(await nftTest1.totalSupply()).to.equal(4)
        expect(await market.connect(addr1).transferNFTs(addr2.address, [1,2,3,4], nftTest1.address))
        expect(await nftTest1.connect(addr1).ownerOf(4)).to.equal(addr2.address)

    })

});

}
)