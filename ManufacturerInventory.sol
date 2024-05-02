// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

contract ManufacturerInventory {
    struct Product {
        bytes sku;
        bytes name;
        bytes batchNumber;
        uint256 quantity;
        bytes expirationDate;
        bytes origin;
        bytes certificationDocumentHash;
        address supplierAddress;
        bool inStock;
    }

    mapping(address => Product[]) public inventory;
    //"121","Paracetamol","1",121,"2026-01-01","test origin","asdas",0xb7E8C6236d5dBE4EF7254D709123C848DC46f985,1
    function addInventory(
        string memory _sku,
        string memory _name,
        string memory _batchNumber,
        uint256 _quantity,
        string memory _expirationDate,
        string memory _origin,
        string memory _certificationDocumentHash,
        address _supplierAddress,
        bool _inStock
    ) public {
        Product memory newProduct = Product({
            sku: bytes(_sku),
            name: bytes(_name),
            batchNumber: bytes(_batchNumber),
            quantity: _quantity,
            expirationDate: bytes(_expirationDate),
            origin: bytes(_origin),
            certificationDocumentHash: bytes(_certificationDocumentHash),
            supplierAddress: _supplierAddress,
            inStock: _inStock
        });

        inventory[msg.sender].push(newProduct);
    }

    function getInventory(address _manufacturerAddress) public view returns (Product[] memory) {
        return inventory[_manufacturerAddress];
    }
}

contract Manufacturer is ManufacturerInventory {

    struct ManufacturingDetail {
        bytes batchNumber;
        bytes productionDate;
        bytes equipmentUsed;
        bytes[] personnelInvolved; // person involved in the process
        uint256[] rawMaterialIndexes; // Indexes of raw materials in rawMaterials array
    }

    struct RawMaterial {
        bytes sku;
        uint256 quantity; // Quantity of the raw material used
    }

    mapping(address => ManufacturingDetail[]) public manufacturingDetails;
    RawMaterial[] public rawMaterials;

    // ["121","122"],["2","3"],"1","2024-04-05","Machine1, machine2",["Deepak1","Manoj"],0xb7E8C6236d5dBE4EF7254D709123C848DC46f985

    function addManufacturingDetails(
        string[] memory _skus, 
        uint256[] memory _quantities,
        string memory _batchNumber,
        string memory _productionDate,
        string memory _equipmentUsed,
        string[] memory _personnelInvolved,
        address manufacturer_address
    ) public {
        uint256[] memory _rawMaterialIndexes;
        _rawMaterialIndexes = addRawMaterials(_skus, _quantities);
        // Validate raw material indexes
        for (uint256 i = 0; i < _rawMaterialIndexes.length; i++) {
            bool isInStock = checkInventory(_rawMaterialIndexes[i], msg.sender, false);
            require(isInStock, "Raw material is not in stock");
        }
        // Create ManufacturingDetail
        ManufacturingDetail memory details = ManufacturingDetail({
            batchNumber: bytes(_batchNumber),
            productionDate: bytes(_productionDate),
            equipmentUsed: bytes(_equipmentUsed),
            personnelInvolved: convertToBytesArray(_personnelInvolved),
            rawMaterialIndexes: _rawMaterialIndexes // Store raw material indexes
        });

        // Push the ManufacturingDetail to the manufacturer's list of manufacturing details
        manufacturingDetails[manufacturer_address].push(details);
    }

    // Add function to retrieve raw material details
    function getRawMaterial(uint256 index) internal view returns (bytes memory, uint256) {
        require(index < rawMaterials.length, "Invalid raw material index");
        return (rawMaterials[index].sku, rawMaterials[index].quantity);
    }

    // Add checkInventory function
    function checkInventory(uint256  rIndex, address _sender, bool updateInventory) internal returns (bool) {
        if (rIndex < rawMaterials.length) {
            bytes memory rSku = rawMaterials[rIndex].sku;
            uint256  rQty= rawMaterials[rIndex].quantity;
            for(uint256 i=0; i< inventory[_sender].length; i++){
                if ((keccak256(bytes(inventory[_sender][i].sku)) == keccak256(bytes(rSku))) ) {
                    require(inventory[_sender][i].quantity > rQty, " The product sku doesnt have enough qty");
                    if(updateInventory) {
                        inventory[_sender][i].quantity -= rQty;
                    }
                    return true;
                }
            }
        }
        return true;
    }

   function convertToBytesArray(string[] memory _personnelInvolved) internal pure returns (bytes[] memory) {
        bytes[] memory pInfo;
        for(uint256 i=0; i< _personnelInvolved.length;i++){
            pInfo[i] = bytes(_personnelInvolved[i]);
        }
        return pInfo;
    }

   function addRawMaterials(string[] memory _skus, uint256[] memory _quantities) public returns(uint256[] memory) {
        require(_skus.length == _quantities.length, "Arrays must have the same length");
        uint256[] memory rawMaterialsIndexes = new uint256[](_skus.length);

        for(uint256 i = 0; i < _skus.length; i++) {
            RawMaterial memory newRawMaterial = RawMaterial({
                sku: bytes(_skus[i]),
                quantity: _quantities[i]
            });
            // Push the newRawMaterial to the rawMaterials array
            rawMaterials.push(newRawMaterial);
            rawMaterialsIndexes[i] = rawMaterials.length - 1;
        }
        return rawMaterialsIndexes;
    }

    function getBatchNumber(string memory _batchNumber, address _manufacturer) public view returns(bool){
         ManufacturingDetail[] memory details = manufacturingDetails[_manufacturer];
        uint256 length = details.length;
        for (uint256 i = 0; i < length; i++) {
            if (keccak256(bytes(details[i].batchNumber)) == keccak256(bytes(_batchNumber))) {
                return true;
            }
        }
        return false;
    }

function getManufactingDetail(string memory _batchNumber, address _manufacturerAddress) external view returns (Manufacturer.ManufacturingDetail[] memory) {
        ManufacturingDetail[] memory batchDetails;
        uint256 cnt=0;
        for (uint256 i = 0; i < manufacturingDetails[_manufacturerAddress].length; i++) {
            if (keccak256(abi.encodePacked(manufacturingDetails[_manufacturerAddress][i].batchNumber)) == keccak256(abi.encodePacked(_batchNumber))) {
                batchDetails[cnt] = manufacturingDetails[_manufacturerAddress][i];
                cnt++;
            }
        }
        return batchDetails;
    }

}

