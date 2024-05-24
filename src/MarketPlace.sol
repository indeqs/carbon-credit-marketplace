// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {FunctionsConsumer} from "./FunctionsConsumer.sol";

contract CarbonCreditMarketplace is ReentrancyGuard {
    address payable public governmentAddress;
    uint16 public emissionFinePerTonne = 100 wei;
    uint16 public pricePerCarbonCredit = 1_000 wei;
    uint256 public initialCarbonCredits = 10;
    uint256 public initialCarbonEmissions = 0;

    FunctionsConsumer public functionsConsumerContractInstance;
    uint256 public totalCarbonEmissionsFromChainlink;

    struct Company {
        address companyAddress;
        uint256 carbonCredits;
        uint256 carbonEmissions;
        bool isRegistered;
    }

    mapping(address => Company) public companies;

    modifier onlyRegisteredCompany() {
        require(
            companies[msg.sender].isRegistered == true,
            "Company is not registered by the government"
        );
        _;
    }

    modifier onlyGovernment() {
        require(
            msg.sender == governmentAddress,
            "Only the government can call this function"
        );
        _;
    }

    event CompanyRegistered(address indexed company);
    event CarbonCreditsIssued(
        address indexed company,
        uint256 carbonCreditsIssued
    );
    event NoEmissionFine(string message);

    constructor(address _functionsConsumerAddress) {
        governmentAddress = payable(msg.sender);
        functionsConsumerContractInstance = FunctionsConsumer(
            _functionsConsumerAddress
        );
        totalCarbonEmissionsFromChainlink = functionsConsumerContractInstance
            .s_totalCarbonGas();
    }

    /**
     * @dev Registers a company by the government
     * @param _companyAddress The address of the company to be registered
     */
    function registerCompany(address _companyAddress) external onlyGovernment {
        require(
            companies[_companyAddress].isRegistered == false,
            "Company is already registered by the government"
        );

        companies[_companyAddress] = Company(
            _companyAddress,
            initialCarbonCredits,
            initialCarbonEmissions,
            true
        );

        emit CompanyRegistered(_companyAddress);
    }

    /**
     * @dev Issues carbon credits to a registered company
     * @param company The address of the company receiving the carbon credits
     * @param _carbonCredits The amount of carbon credits to be issued
     */
    function issueCarbonCredits(
        address company,
        uint256 _carbonCredits
    ) external onlyGovernment {
        require(
            companies[company].isRegistered == true,
            "Company is not registered"
        );

        companies[company].carbonCredits += _carbonCredits;
        emit CarbonCreditsIssued(company, _carbonCredits);
    }

    /**
     * @dev Allows a company to buy carbon credits from another company. The buyer is the one to call this function.
     * @param seller The seller of the carbon credits
     * @param numberOfCarbonCredits The number of carbon credits to buy
     */
    function buyCarbonCredits(
        address seller,
        uint256 numberOfCarbonCredits
    ) public onlyRegisteredCompany nonReentrant {
        uint256 sellerCarbonCredits = companies[seller].carbonCredits;
        require(
            sellerCarbonCredits > totalCarbonEmissionsFromChainlink,
            "Seller has fewer carbon credits than their emissions"
        );
        require(
            numberOfCarbonCredits <= sellerCarbonCredits,
            "Seller does not have enough carbon credits"
        );

        companies[msg.sender].carbonCredits += numberOfCarbonCredits;
        companies[seller].carbonCredits -= numberOfCarbonCredits;

        uint256 totalCost = numberOfCarbonCredits * pricePerCarbonCredit;
        (bool sent, ) = seller.call{value: totalCost}("");
        require(sent, "Failed to pay the seller for carbon credits");
    }

    /**
     * @dev Sets the price per extra carbon credit purchased
     * @param _price The new price in wei
     */
    function setPricePerCarbonCredit(uint16 _price) external onlyGovernment {
        pricePerCarbonCredit = _price;
    }

    /**
     * @dev Sets the fine per extra tonne of emissions
     * @param _fine The new fine in wei
     */
    function setEmissionFinePerTonne(uint16 _fine) external onlyGovernment {
        emissionFinePerTonne = _fine;
    }

    /**
     * @dev Allows a company to pay a fine for extra emissions. The company to be fined is the one to call this function
     * @param company The address of the company to be fined
     */
    function payEmissionFine(
        address company
    ) external onlyRegisteredCompany nonReentrant {
        uint256 companyCarbonCredits = companies[company].carbonCredits;
        if (totalCarbonEmissionsFromChainlink > companyCarbonCredits) {
            uint256 extraEmissions = totalCarbonEmissionsFromChainlink -
                companyCarbonCredits;
            uint256 fineAmount = extraEmissions * emissionFinePerTonne;
            (bool sent, ) = governmentAddress.call{value: fineAmount}("");
            require(sent, "Failed to send fine to the government");
        } else {
            emit NoEmissionFine(
                "Your carbon emissions are less than your carbon credits, good job!"
            );
        }
    }

    /**
     * @dev Returns the extra carbon emissions for a company
     * @param _company The address of the company
     * @return extraCarbonEmissions The amount of extra carbon emissions
     */
    function getExtraCarbonEmissions(
        address _company
    ) public view returns (uint256) {
        uint256 companyCarbonCredits = companies[_company].carbonCredits;
        if (totalCarbonEmissionsFromChainlink > companyCarbonCredits) {
            return totalCarbonEmissionsFromChainlink - companyCarbonCredits;
        } else if (totalCarbonEmissionsFromChainlink == companyCarbonCredits) {
            return totalCarbonEmissionsFromChainlink;
        } else {
            return 0;
        }
    }
}
