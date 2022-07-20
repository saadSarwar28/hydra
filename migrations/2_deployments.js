const hydra = artifacts.require("HydraToken");

module.exports = async function (deployer) {

    // for main net
    const markettingAddress = '0xA04B39F3da5aC4aF711a165ff61329D92764661b'
    const devAddress = '0x2A65AadEeAfeee6a16Cbd7254734043b938D6a77'
    const uniswapRouter = '0xE592427A0AEce92De3Edee1F18E0157C05861564'
    const positions = '0xC36442b4a4522E871399CD717aBDD847Ab11FE88'

    const purchaseTax = 5

    const purchaseTaxShareDev = 50
    const purchaseTaxShareMarketing = 50

    const sellTax = 15

    const sellTaxShareDev = 50
    const sellTaxShareMarketing = 50

    await deployer.deploy(
        hydra,
        markettingAddress,
        devAddress,
        uniswapRouter,
        purchaseTax,
        sellTax,
        purchaseTaxShareDev,
        purchaseTaxShareMarketing,
        sellTaxShareDev,
        sellTaxShareMarketing
    )

    const hydraToken = await hydra.deployed()
    hydraToken.approveTokens()
    hydraToken.mint(1000000000000000000000000, '0x5340fc6cA1315bcFBbdEc73686247DDCD0f38F98')
};

