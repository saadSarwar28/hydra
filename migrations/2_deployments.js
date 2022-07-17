const brokerDefiPartner = artifacts.require("BrokerDefiPartner");
const brokerDefiPro = artifacts.require("BrokerDefiPro");

module.exports = async function (deployer) {

    const maxNfts = 2500
    const treasury = '0xA97F7EB14da5568153Ea06b2656ccF7c338d942f' // saad's address
    // const publicSalePrice = '15000000000000000'  // 0.015 ether for testing
    const publicSalePrice = '1250000000000000000'  // 1.25 ether
    const maxPerTrx = 5
    const allocatedForTeam = 250
    const partnerCommission = 10
    const partnerDiscount = 10

    await deployer.deploy(
        brokerDefiPartner,
        maxNfts,
        treasury,
        publicSalePrice,
        maxPerTrx,
        allocatedForTeam,
        partnerCommission,
        partnerDiscount
    )
    const BrokerDefiPartner = await brokerDefiPartner.deployed()

    const publicSalePricePro = '15000000000000000'  // 0.015 ether
    const allocatedForTeamPro = 250
    const partnerAddress = BrokerDefiPartner.address
    // const partnerAddress = '0x6962fD2b754cbAee1d2FE6F54ed59c1D91A534C6'
    const proCommission = 10
    const proDiscount = 10
    const partnerCommissionForPro = 10
    const partnerDiscountForPro = 10

    await deployer.deploy(
        brokerDefiPro,
        treasury,
        publicSalePricePro,
        allocatedForTeamPro,
        partnerAddress,
        partnerCommissionForPro,
        proCommission,
        partnerDiscountForPro,
        proDiscount
    )
    const BrokerDefiPro = await brokerDefiPro.deployed()

};

