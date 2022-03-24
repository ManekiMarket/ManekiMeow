// SPDX-License-Identifier: MIT
// DEPLOYMENT CODE : CRC22MAR2022
// edited 22 MAR 22

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./Collectibles.sol";


/**
 * public - all can access
 * external - Cannot be accessed internally, only externally
 * internal - only this contract and contracts deriving from it can access
 * private - can be accessed only from this contract
*/

/**
 * @title TokenReceiver
 * @dev Very simple example of a contract receiving ERC20 tokens.
 */
 
 /**
  * 1. This contract : Add new ERC20 A-Token to this contract 
  * 2. A-Token Contract : Go to A-Token contract to Approve AND Allowance X amount
  * 3. This Contact : payWithERC20 with A-Token Address
  * 4. OPTIONAL : A-Token Contract Check This Contract Balance
  */
  
contract Payment {
    
    constructor(address _collectiblesContract) public {
        CLevel memory newCLevel = CLevel({
            CLevelAddress : msg.sender,
            Role : 1,
            Status : true
        });
        CLevels.push(newCLevel);
        
        collectiblesContract = _collectiblesContract;
        
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
    
    address collectiblesContract;
    

/**
 * @tokenStatus 1 is active to use, 0 is pause
 */
    struct ERC20Token {
        IERC20 tokenAddress;
        string tokenSymbol;
        uint   tokenQuantity;
        bool   tokenStatus;
    }
    
    
    struct CLevel {
        address CLevelAddress;
        uint256 Role;
        bool Status;
    }
    
    ERC20Token [] public ERC20Tokens;
    CLevel[] public CLevels;
    



    function addNewCEO (address _newAddress) external onlyCEO{
        CLevel memory newCLevel = CLevel({
            CLevelAddress : _newAddress,
            Role : 1,
            Status : true
        });
        CLevels.push(newCLevel);
        emit ROLES (_newAddress,1,true);
    }

    function addNewCLevel (address _newAddress) external onlyCEO{
        CLevel memory newCLevel = CLevel({
            CLevelAddress : _newAddress,
            Role : 2,
            Status : true
        });
        CLevels.push(newCLevel);
        emit ROLES (_newAddress,2,true);
    }

    function deactiveCLevel (address _deactiveAddress) external onlyCEO{
        for(uint i=0; i<CLevels.length; i++){
            if(CLevels[i].CLevelAddress== _deactiveAddress){
                CLevels[i].Status = false;
                emit ROLES (_deactiveAddress,CLevels[i].Role,false);
            }
        }
    }



    event ROLES (address user, uint256 role, bool status);
    event PAYMENT (address indexed payee, uint256 indexed _nftID, IERC20 indexed token, uint256 amount);
    event ADDPAYMENTTOKEN (IERC20 indexed _tokenAddress, string indexed _tokenSymbol, uint256 _tokenQuantity);
    event UPDATETOKENRATE (IERC20 indexed _tokenAddress, uint256 _tokenAmount);
    
    event WITHDRAWALCOIN  (address indexed _walletAddress, uint256 _amount, uint256 _balance);
    event WITHDRAWALTOKEN (IERC20 indexed _tokenAddress, address indexed _walletAddress,  uint256 _amount, uint256 _balance);
    
    
    
    // Set collectible Contract Address
    function setCollectibleContract (address _contractAddress) external onlyCLevel() {
        collectiblesContract = _contractAddress;
    }
    
    function totalTokens () external view returns (uint){
        return ERC20Tokens.length;
    }
    
    
    function addERC20Token (IERC20 _tokenAddress, string memory _tokenSymbol, uint _tokenQuantity) public onlyCLevel() returns (bool){

        // verify no duplicated ERC20 Token to add
        bool duplicated = false;

        for(uint i=0;i<ERC20Tokens.length;i++){
            if(ERC20Tokens[i].tokenAddress == _tokenAddress){
                duplicated = true;
            }
        }

        if (duplicated==false){
            ERC20Token memory newERC20Token = ERC20Token({
                tokenAddress    : _tokenAddress,
                tokenSymbol     : _tokenSymbol,
                tokenQuantity   : _tokenQuantity,
                tokenStatus     : true
            });
    
            ERC20Tokens.push(newERC20Token);  
            
            emit ADDPAYMENTTOKEN (_tokenAddress, _tokenSymbol, _tokenQuantity);
            return true;
            
        } else {
            return false;
        }
        
    }
    
    function setTokenQuantity (IERC20 _tokenAddress, uint _tokenQuantity) external onlyCLevel() returns (uint256){
        for(uint i=0;i<ERC20Tokens.length;i++){
            if(ERC20Tokens[i].tokenAddress == _tokenAddress){
                ERC20Tokens[i].tokenQuantity = _tokenQuantity;
                emit UPDATETOKENRATE (_tokenAddress,_tokenQuantity);
            }
        }
        return _tokenQuantity;
    }

    
    function setTokenStatus (IERC20 _tokenAddress, bool _tokenStatus) external onlyCLevel() returns (bool){
        for(uint i=0;i<ERC20Tokens.length;i++){
            if(ERC20Tokens[i].tokenAddress == _tokenAddress){
                ERC20Tokens[i].tokenStatus = _tokenStatus;
            }
        }
        return _tokenStatus;
    }
    
  
    
/** Payment to this contract
 * @ _tokenAddress Which is ERC20 Token use as payment
 */
    
    function paymentByToken (IERC20 _tokenAddress, uint256 _machine, uint256 _refNekoId) public {
        address from = msg.sender;
        uint256 newNekoId;
        
        ManekiCollectibles Contract = ManekiCollectibles(collectiblesContract);
        
        // identify which ERC20 token use as Payment
        for(uint i=0;i<ERC20Tokens.length;i++){
            if(ERC20Tokens[i].tokenAddress == _tokenAddress){
                _tokenAddress.transferFrom(from, address(this), ERC20Tokens[i].tokenQuantity);
                newNekoId = Contract.mintCollectible(from, _machine, _refNekoId);
                emit PAYMENT(from, newNekoId, _tokenAddress, ERC20Tokens[i].tokenQuantity);
            }
        }
    }
    
    function paymentByCoin (uint256 _machine, uint256 _refNekoId) external payable {
        require(msg.value ==  currentPrice());
        address from = msg.sender;
        uint256 newNekoId;
        ManekiCollectibles Contract = ManekiCollectibles(collectiblesContract);
        newNekoId = Contract.mintCollectible(from, _machine, _refNekoId);
        
        emit PAYMENT(from, newNekoId, IERC20(0x0000000000000000000000000000000000000001), currentPrice());
    }
    
    
/** Withdrawal from this contract
 */
    function withdrawalToken (IERC20 _tokenAddress, address _recipient, uint256 _amount) external onlyCLevel() returns (address, uint256){
        
        address recipient = _recipient;
        
        _tokenAddress.approve(address(this), _amount);
        _tokenAddress.transferFrom(address(this), recipient, _amount);
        
        emit WITHDRAWALTOKEN (_tokenAddress, recipient, _amount,address(this).balance);
        return (recipient, _amount);
    }

    function withdrawalCoin (address payable _recipient, uint256 _amount) external onlyCLevel {
        require(_recipient != address(0) && _recipient != address(this));
        require(_amount > 0 && _amount <= address(this).balance);
        _recipient.transfer(_amount);
        
        emit WITHDRAWALCOIN (_recipient, _amount, address(this).balance);
    }    

/** check ERC20 Token Balance in this contact
 */
    function checkERC20Balance (IERC20 _tokenAddress) external onlyCLevel() view returns  (uint){
        return _tokenAddress.balanceOf(address(this));
    }
/** check current amount of CFX for minting */

    function currentPrice () public view returns (uint256) {
        uint256 totalMints;
        uint256 amount;

        ManekiCollectibles Contract = ManekiCollectibles(collectiblesContract);
        totalMints = Contract.totalSupply();


        for(uint i=0;i<10;i++){
            if(totalMints >= i * 100000 && totalMints < (i+1) * 100000 ){
                amount = 10 ** (i+13);
            }
        }

        return amount;
            
    }

}