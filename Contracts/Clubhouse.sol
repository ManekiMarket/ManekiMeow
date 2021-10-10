// SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;

contract Clubhouse {
    /**
     * Clubhouse
     */

    constructor() public {
        CLevel memory newCLevel = CLevel({
            CLevelAddress : msg.sender,
            Role : 1,
            Status : true
        });
        CLevels.push(newCLevel);
    }    
         
    
    modifier onlyCEO {
        address authorized;

        for(uint i=0; i<CLevels.length; i++){
            if(CLevels[i].CLevelAddress== msg.sender && CLevels[i].Role==1 && CLevels[i].Status == true){
                authorized = CLevels[i].CLevelAddress;
            }
        }
        require(msg.sender == authorized);
        _;
    }

    modifier onlyCLevel {
        address authorized;

        for(uint i=0; i<CLevels.length; i++){
            if(CLevels[i].CLevelAddress== msg.sender){
                authorized = CLevels[i].CLevelAddress;
            }
        }
        require(msg.sender == authorized);
        _;
    }
    

    struct CLevel {
        address CLevelAddress;
        uint256 Role;
        bool Status;
    }
    
    CLevel[] public CLevels;    
     
     

    struct Member {
        address Referrer;
    }
    
    mapping (address => Member) public members;
    
    address[] public Members;
    
    
    


    function addNewCEO (address _newAddress) external onlyCEO{
        CLevel memory newCLevel = CLevel({
            CLevelAddress : _newAddress,
            Role : 1,
            Status : true
        });
        CLevels.push(newCLevel);
    }

    function addNewCLevel (address _newAddress) external onlyCEO{
        CLevel memory newCLevel = CLevel({
            CLevelAddress : _newAddress,
            Role : 2,
            Status : true
        });
        CLevels.push(newCLevel);
    }

    function deactiveCLevel (address _deactiveAddress) external onlyCEO{
        for(uint i=0; i<CLevels.length; i++){
            if(CLevels[i].CLevelAddress== _deactiveAddress){
                CLevels[i].Status = false;
            }
        }
    }    
    
    
   function addMember (address _member, address _referrer)  public onlyCLevel{
        require (getReferrer(_member)== address(0x0) && _member!=_referrer);
        members[_member].Referrer = _referrer;
        Members.push(_member);
    }
    
    
    function getMembers () public view returns (address [] memory, uint256) {
        address[] memory _members = new address[](Members.length);
        uint count = 0;
        
        for (uint i=0; i< Members.length ; i++){
            if(getReferrer(Members[i]) == msg.sender) {
                _members[count] = Members[i];
                count ++;
            }
        }
        return (_members, count);
    }
    
    
    function getAllMembers () public view returns (address [] memory){
        return (Members);
    }
    
    
    function countMembers () public view returns (uint256){
        return Members.length ;
    }
    
    function getReferrer (address _member) public view returns (address) {
        return members[_member].Referrer;
    }

}