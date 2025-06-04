// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

contract KYCRegistry is Initializable, OwnableUpgradeable, UUPSUpgradeable, ReentrancyGuardUpgradeable {
    enum KYCType { Individual, Company }

    struct CompanyKYC {
        string ruc;
        uint256 leadId;
        string empresaInfoJsonUrl;
        string pdtAnualAwsUrl;
        string pdt6MesesAwsUrl;
        string reporteTercerosAwsUrl;
        string fichaRucAwsUrl;
        string copiaLiteralAwsUrl;
        string vigenciaPoderAwsUrl;
        string otrosAwsUrl;
        uint256 timestamp;
    }

    struct IndividualKYC {
        string userId;
        uint256 leadId;
        string personalInfoJsonUrl;
        string pdtAnualAwsUrl;
        uint256 timestamp;
    }

    mapping(string => CompanyKYC) private rucToCompanyKYC;
    mapping(string => IndividualKYC) private userIdToIndividualKYC;

    mapping(uint256 => KYCType) private leadIdToType;
    mapping(uint256 => string) private leadIdToKey;

    event CompanyKYCUpdated(string ruc, uint256 leadId, uint256 timestamp);
    event IndividualKYCUpdated(string userId, uint256 leadId, uint256 timestamp);

    

    function initialize(address initialOwner) public initializer {
        __Ownable_init(initialOwner); 
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function upsertCompanyKYC(
        string memory _ruc,
        uint256 _leadId,
        string memory _empresaInfoJsonUrl,
        string memory _pdtAnualAwsUrl,
        string memory _pdt6MesesAwsUrl,
        string memory _reporteTercerosAwsUrl,
        string memory _fichaRucAwsUrl,
        string memory _copiaLiteralAwsUrl,
        string memory _vigenciaPoderAwsUrl,
        string memory _otrosAwsUrl
    ) public onlyOwner nonReentrant {
        rucToCompanyKYC[_ruc] = CompanyKYC({
            ruc: _ruc,
            leadId: _leadId,
            empresaInfoJsonUrl: _empresaInfoJsonUrl,
            pdtAnualAwsUrl: _pdtAnualAwsUrl,
            pdt6MesesAwsUrl: _pdt6MesesAwsUrl,
            reporteTercerosAwsUrl: _reporteTercerosAwsUrl,
            fichaRucAwsUrl: _fichaRucAwsUrl,
            copiaLiteralAwsUrl: _copiaLiteralAwsUrl,
            vigenciaPoderAwsUrl: _vigenciaPoderAwsUrl,
            otrosAwsUrl: _otrosAwsUrl,
            timestamp: block.timestamp
        });

        leadIdToType[_leadId] = KYCType.Company;
        leadIdToKey[_leadId] = _ruc;

        emit CompanyKYCUpdated(_ruc, _leadId, block.timestamp);
    }

    function upsertIndividualKYC(
        string memory _userId,
        uint256 _leadId,
        string memory _personalInfoJsonUrl,
        string memory _pdtAnualAwsUrl
    ) public onlyOwner nonReentrant {
        userIdToIndividualKYC[_userId] = IndividualKYC({
            userId: _userId,
            leadId: _leadId,
            personalInfoJsonUrl: _personalInfoJsonUrl,
            pdtAnualAwsUrl: _pdtAnualAwsUrl,
            timestamp: block.timestamp
        });

        leadIdToType[_leadId] = KYCType.Individual;
        leadIdToKey[_leadId] = _userId;

        emit IndividualKYCUpdated(_userId, _leadId, block.timestamp);
    }

    function getCompanyKYCByRUC(string memory _ruc) public view returns (CompanyKYC memory) {
        require(bytes(rucToCompanyKYC[_ruc].ruc).length != 0, "Company KYC not found");
        return rucToCompanyKYC[_ruc];
    }

    function getIndividualKYCByUserID(string memory _userId) public view returns (IndividualKYC memory) {
        require(bytes(userIdToIndividualKYC[_userId].userId).length != 0, "Individual KYC not found");
        return userIdToIndividualKYC[_userId];
    }

    function getKYCByLeadId(uint256 _leadId) public view returns (
        KYCType kycType,
        string memory key,
        bytes memory kycData
    ) {
        kycType = leadIdToType[_leadId];
        key = leadIdToKey[_leadId];
        if (kycType == KYCType.Company) {
            kycData = abi.encode(rucToCompanyKYC[key]);
        } else if (kycType == KYCType.Individual) {
            kycData = abi.encode(userIdToIndividualKYC[key]);
        } else {
            revert("Invalid lead ID");
        }
    }
}
