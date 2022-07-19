const hydra = artifacts.require("HydraToken");

module.exports = async function (deployer) {

    // for main net
    const markettingAddress = '0xA04B39F3da5aC4aF711a165ff61329D92764661b'
    const devAddress = '0x2A65AadEeAfeee6a16Cbd7254734043b938D6a77'
    const uniswapRouter = '0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45'

    const purchaseTax = 5

    const purchaseTaxShareDev = 50
    const purchaseTaxShareMarketing = 50

    const sellTax = 15

    const sellTaxShareDev = 50
    const sellTaxShareMarketing = 50

    const poolFee = 3000

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
        sellTaxShareMarketing,
        poolFee
    )
};

