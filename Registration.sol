// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Registration {
    struct Participant {
        bytes name;
        bytes uniqueIdentifier;
        bytes contactDetails;
        bytes email;
        bytes phone;
        bytes certificates;
        bytes organization;
        address walletAddress; 
    }
    
    
    enum ParticipantType { Supplier, Manufacturer, Distributor, Regulator }
    
    mapping(address => Participant) public participants;
    mapping(address => ParticipantType) public participantTypes;

    // "Deepak Bhatta","23123","dadas",1,"d8bhatta@ada.com","2423423","dasdas","asdas",0x218b63453e222aA126b36F8F7ba665bFf6C92434
    // Register a participant
    function registerParticipant(
        string memory _name, 
        string memory _uniqueIdentifier, 
        string memory _contactDetails, 
        ParticipantType _type, 
        string memory _email, 
        string memory _phone, 
        string memory _certificates, 
        string memory _organization, 
        address _walletAddress
    ) public {
        require(participantTypes[msg.sender] == ParticipantType(0), "Participant already registered");
        
        Participant memory newParticipant = Participant(
            bytes(_name),
            bytes(_uniqueIdentifier), 
            bytes(_contactDetails),
            bytes(_email), 
            bytes(_phone), 
            bytes(_certificates), 
            bytes(_organization), 
            _walletAddress);
        
        participants[_walletAddress] = newParticipant;
        participantTypes[_walletAddress] = _type;
    }
    
    // Check if a participant has already been registered
    function isParticipantRegistered(address _participantAddress) public view returns (bool) {
        return participants[_participantAddress].walletAddress != address(0);
    }
   
    // Get participant details
    function getParticipantDetails(address _participantAddress) public view returns (Participant memory) {
        require(isParticipantRegistered(_participantAddress), "Participant not registered");
        return participants[_participantAddress];
    }
}
