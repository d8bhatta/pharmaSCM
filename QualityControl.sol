// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ManufacturerInventory.sol";

contract QualityControl {

    
    
    struct QualityControlCheck {
        bytes qualitycheckid;
        bytes batchNumber;         
        bytes[] checkName;   // Name or description of the quality control check
        bool passed;          // Indicates whether the quality control check passed or failed
        bytes result;        // Result or details of the quality control check
        uint256 timestamp;     // Timestamp of when the quality control check was performed
    }

    Manufacturer manufacturerContract; // Instance of the Manufacturer contract
    
   // mapping(address => mapping(string => QualityControlCheck[])) public qualityChecks;

   //address is owner's address, second mapping bytes is batchnumber, and uint256 lastone is the index of the QC. There could be multiple QC.
    mapping(address => mapping(bytes => mapping ( uint256 =>QualityControlCheck))) public qualityChecks;
    mapping(address => mapping(bytes => uint256)) public indexTracker;


    constructor(address _manufacturerAddress) {
        manufacturerContract = Manufacturer(_manufacturerAddress); // Initialize the instance with the address of the Manufacturer contract
    }

    // Function to verify if a batch number exists
    function verifyBatchNumber(string memory _batchNumber) public view returns (bool) {
        bool batchNumber = manufacturerContract.getBatchNumber(_batchNumber, msg.sender);
        return batchNumber;
    }

    function addQualityCheck(
        string memory _qualityCheckId, 
        string memory _batchNumber, 
        string[] memory _checkName, 
        bool _checkPassed, 
        string memory _result
    ) 
    external returns (bool) {
        try this.verifyBatchNumber(_batchNumber) returns (bool batchExists) {
            require(batchExists, "Invalid batch number");

        bytes[] memory qInfo;
        for(uint256 i=0; i< _checkName.length;i++){
            qInfo[i] = bytes(_checkName[i]);
        }
       

            QualityControlCheck memory newQC = QualityControlCheck({
                qualitycheckid: bytes(_qualityCheckId),
                batchNumber: bytes(_batchNumber),
                checkName: qInfo,
                passed: _checkPassed,
                result: bytes(_result),
                timestamp:block.timestamp
            });

            uint256 currentIndex = indexTracker[msg.sender][bytes(_batchNumber)];
            qualityChecks[msg.sender][bytes(_batchNumber)][currentIndex] = newQC;
            indexTracker[msg.sender][bytes(_batchNumber)]++;
            return true;
        } catch Error(string memory errorMessage) {
            revert(errorMessage);
        } catch (bytes memory) {
            revert("An error occurred during quality check processing");
        }
    }

    function getQCReportByBatchNumber(string memory _batchNumber, address _manufacturer_address) public view returns (QualityControlCheck[] memory) {
        bytes memory batchNumber = bytes(_batchNumber);
        uint256 currentIndex = indexTracker[msg.sender][batchNumber];

        QualityControlCheck[] memory newQualityChecks = new QualityControlCheck[](currentIndex); // Initialize with a fixed size
        for (uint256 i = 0; i < currentIndex; i++) {
            newQualityChecks[i] = qualityChecks[_manufacturer_address][batchNumber][i];
        }
        return newQualityChecks;
    }

}
