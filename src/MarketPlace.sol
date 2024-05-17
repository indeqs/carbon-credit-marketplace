// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {FunctionsConsumer} from "./FunctionsConsumer.sol";

contract CarbonCreditMarketplace {
    address payable public governmentAddress;
    uint256 public initialAmountOfCarbonCredits = 10;
    uint256 public initialAmountOfCarbonEmission = 0;

    bytes public responseFromChainlink = FunctionsConsumer.s_lastResponse;

    /**
     * name                    : The name of the company
     * amountOfcarbonCredits   : The amount of carbon credits given to the company by the governmemt
     * totalCarbonEmission     : The total amount of carbon dioxide emitted to the environment by the company
     * isRegistered            : A boolean value indicating whether the company is viable to receive carbon credits or not
                                 from the government. Regulatory compliance and checks can be done before approving the company
     */

    struct Company {
        address companyAddress;
        uint256 amountOfCarbonCredits;
        uint256 totalCarbonEmission;
        bool isRegistered;
    }

    // Mapping of addresses to Company struct
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
        uint256 numberOfCarbonCreditIssued
    );

    constructor() {
        governmentAddress = payable(msg.sender);
    }

    /**
     * @dev A function that allows companies to register themselves
     * @param _companyAddress Company address
     */

    function registerCompany(address _companyAddress) external {
        require(
            companies[msg.sender].isRegistered == false,
            "Company is already registered"
        );

        companies[msg.sender] = Company(
            _companyAddress,
            initialAmountOfCarbonCredits,
            initialAmountOfCarbonEmission,
            true
        );

        emit CompanyRegistered(msg.sender);
    }

    /**
     * @dev A function for the government to issue carbon credits to registered companies
     * @param company The address of the company receiving the carbon credits
     * @param _amountOfCarbonCredits The amount of carbon credits given to the company by the government
     */
    function issueCarbonCredits(
        address company,
        uint256 _amountOfCarbonCredits
    ) external onlyGovernment {
        require(
            companies[company].isRegistered == true,
            "Company is not registered"
        );

        companies[company].amountOfCarbonCredits += _amountOfCarbonCredits;
        emit CarbonCreditsIssued(company, _amountOfCarbonCredits);
    }

    /**
     * @dev A function that allows one company to trade its surplus carbon credits with another company after it has been established
     * that `from` has a surplus credit as read from carbon sensors
     * @param from from which company?
     * @param to to which company?
     * @param amount how much carbon credit are you selling
     */
    function tradeCarbonCredit(
        address from,
        address to,
        uint256 amount
    ) public onlyRegisteredCompany {}

    /*
    function fine() external {
        if (carbonProducedAsGottenFromChainlink > carbonCreditGivenByGovt){
            uint256 gasDueToExtraEmissions = carbonProducedAsGottenFromChainlink - carbonCreditGivenByGovt;
            uint256 fineToBePaid = gasDueToExtraEmissions * feeChargedPerExtraTonneOfEmission;
        }
    }

    */
}
