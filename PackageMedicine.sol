// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ManufacturerInventory.sol";
import "./QualityControl.sol";

contract PackageMedicine {

   struct PackageHistory {
        Package[] packages;
        Manufacturer.ManufacturingDetail[] manufacturingDetails; // Corrected struct path
        QualityControl.QualityControlCheck[] qualityControlChecks;
    }

    struct Package {
        bytes packageid;
        bytes batchNumber;
        bytes sku;
        bytes packagingType;
        uint256 quantity;
        uint256 timestamp;
    }

    Manufacturer manufacturerContract; // Instance of the ManufacturerInventory contract
    QualityControl qualityControlContract; // Instance of QualityControl contract
    
    //address of owner, package id
    mapping(address => mapping(bytes => Package[])) public packages;

    constructor(address _manufacturerAddress) {
        manufacturerContract = Manufacturer(_manufacturerAddress); // Corrected contract type
        qualityControlContract = QualityControl(_manufacturerAddress);
    }

    function createPackage(
        string memory _packageid,
        string memory _batchNumber,
        string memory _sku,
        string memory _packagingType,
        uint256 _qty
    ) external returns (bool) {
        require(_qty > 0, "Quantity must be greater than zero");
        require(bytes(_packageid).length > 0, "Package ID cannot be empty");
        require(bytes(_batchNumber).length > 0, "Batch Number cannot be empty");
        require(bytes(_sku).length > 0, "SKU cannot be empty");
        require(bytes(_packagingType).length > 0, "Packaging Type cannot be empty");

        Package memory newPackage = Package({
            packageid: bytes(_packageid),
            batchNumber: bytes(_batchNumber),
            sku: bytes(_sku),
            packagingType: bytes(_packagingType),
            quantity: _qty,
            timestamp: block.timestamp
        });

        packages[msg.sender][bytes(_packageid)].push(newPackage);
        return true;
    }

    function getPackageHistory(string memory _packageId, address _manfacturerAddress ) public view returns (PackageHistory memory) {
        (Package[] memory _packages, string memory _batchNumber) = getBatchIdByPkgId(_packageId, _manfacturerAddress);
        PackageHistory memory newPkgHistory = PackageHistory({
            packages: _packages,
            manufacturingDetails: manufacturerContract.getManufactingDetail(_batchNumber,_manfacturerAddress),
            qualityControlChecks: qualityControlContract.getQCReportByBatchNumber(_batchNumber, _manfacturerAddress)
        });
        return newPkgHistory;
    }

    function getBatchIdByPkgId(string memory _packageId, address _manfacturerAddress) internal view returns(Package[] memory, string memory _batchNumber){
        bytes memory packageId = bytes(_packageId);
        Package[] memory NewPackage = new Package[](packages[_manfacturerAddress][packageId].length);
        for(uint256 i=0;i<packages[_manfacturerAddress][packageId].length;i++){
            NewPackage[i] = packages[_manfacturerAddress][packageId][i];
            _batchNumber = string(abi.encodePacked(packages[_manfacturerAddress][packageId][i].batchNumber));
        }
        return(NewPackage, _batchNumber);
        
    }
}
