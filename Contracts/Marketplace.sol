// SPDX-License-Identifier: MIT
// DEPLOYMENT CODE : CRC22MAR2022
// edited 22 MAR 22

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./Collectibles.sol";

contract Marketplace {

  struct Auction {
      uint64 id;
      address seller;
      uint256 tokenId;
      IERC20 paymentToken; // CFX or ERC20
      uint128 startingPrice; // wei
      uint128 endingPrice; // wei
      uint64 duration; // seconds
      uint64 startedAt; // time
      bool   status;
  }
  struct CLevel {
      address CLevelAddress;
      uint256 Role;
      bool Status;
  }
/**
 * @tokenStatus 1 is active to use, 0 is pause
 */
  struct ERC20Token {
      IERC20 tokenAddress;
      string tokenSymbol;
      bool   tokenStatus;
  }
    

  IERC721 public NFTContract;
  uint64 public fee;
  CLevel[] public CLevels;
  ERC20Token [] public ERC20Tokens;

  Auction[] public auctions;
  address public collectiblesContract;

  uint256 public activeAuctionsCount;

  uint64 public auctionId; // max is 18446744073709551615

  mapping (uint256 => Auction) internal tokenIdToAuction;
  mapping (uint64 => Auction) internal auctionIdToAuction;

  //mapping(address => uint64) internal ownerAuctions;
  //mapping(bool => uint64[]) internal activeAuctions;
  // require to delete when bidded


  // TODO: are arrays of structs even possible?
  //       use this for making auctions discoverable
  mapping (address => Auction[]) internal ownerToAuction;
  //mapping(uint256 => uint256) internal auctionIdToOwnerIndex;


  event ROLES (address user, uint256 role, bool status);
  event AuctionCreated(uint64 auctionId, uint256 tokenId, IERC20 paymentToken,
                      uint256 startingPrice, uint256 endingPrice, uint256 startAt, uint256 duration);
  event AuctionCancelled(uint64 auctionId, uint256 tokenId);
  event AuctionSuccessful(uint64 auctionId, uint256 tokenId, string indexed _tokenSymbol, uint256 totalPrice, address winner);
  event WITHDRAWALCOIN  (address indexed _walletAddress, uint256 _amount);    
  event WITHDRAWALTOKEN (IERC20 indexed _tokenAddress, address indexed _walletAddress, uint256 _balance);
  event ADDPAYMENTTOKEN (IERC20 indexed _tokenAddress, string indexed _tokenSymbol);

  constructor(address _NFTAddress, uint64 _fee) public {
      NFTContract = IERC721(_NFTAddress);

      collectiblesContract = _NFTAddress;

      fee = _fee; // 3.500 as 3500

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




  

   function createAuction(
      uint256 _tokenId, IERC20 _paymentToken, uint256 _startingPrice,
      uint256 _endingPrice, uint256 _duration) public {
      // check storage requirements
      require(_startingPrice < 340282366920938463463374607431768211455); // 128 bits
      require(_endingPrice < 340282366920938463463374607431768211455); // 128 bits
      require(_duration <= 18446744073709551615); // 64 bits

      require(_duration >= 1 minutes);
      require(NFTContract.ownerOf(_tokenId) == msg.sender, "NFT not belong to owner");

      uint256 _startAt = block.timestamp;

      Auction memory auction = Auction(
          uint64(auctionId),
          msg.sender,
          uint256(_tokenId),
          IERC20(_paymentToken),
          uint128(_startingPrice),
          uint128(_endingPrice),
          uint64(_duration),
          uint64(_startAt),
          bool (true)
      );

      auctions.push(auction);
      tokenIdToAuction[_tokenId] = auction;
      auctionIdToAuction[auctionId] = auction;

      activeAuctionsCount++;


      // deposit NFT for escrow 
      _escrow (_tokenId);

      emit AuctionCreated(
          uint64(auctionId),
          uint256(_tokenId),
          IERC20(_paymentToken),
          uint256(auction.startingPrice),
          uint256(auction.endingPrice),
          uint256(auction.duration),
          uint256(_startAt)
      );

      auctionId++;
  }

    function _escrow (uint256 _tokenID) internal {
        NFTContract.transferFrom(msg.sender,address(this),_tokenID);
    }
    
    function _unescrow (uint256 _tokenID) internal {
   
        NFTContract.approve(msg.sender, _tokenID);
        
        // @thisContract, @toSelller, @NFTid
        NFTContract.transferFrom(address(this),msg.sender,_tokenID);
    }

    
  function getAuctionByAuctionId(uint64 _auctionId) public view returns (
      uint64 id,
      address seller,
      uint256 tokenId,
      IERC20  paymentToken,
      uint256 startingPrice,
      uint256 endingPrice,
      uint256 duration,
      uint256 startedAt,
      bool    status
  ) {
      Auction storage auction = auctionIdToAuction[_auctionId];
      require(auction.startedAt > 0);
      return (
          auction.id,
          auction.seller,
          auction.tokenId,
          auction.paymentToken,
          auction.startingPrice,
          auction.endingPrice,
          auction.duration,
          auction.startedAt,
          auction.status
      );
  }

  function getAuctionByTokenId(uint256 _tokenId) public view returns (
      uint64 id,
      address seller,
      uint256 tokenId,
      IERC20  paymentToken,
      uint256 startingPrice,
      uint256 endingPrice,
      uint256 duration,
      uint256 startedAt,
      bool status
  ) {
      Auction storage auction = tokenIdToAuction[_tokenId];
      require(auction.startedAt > 0);
      return (
          auction.id,
          auction.seller,
          auction.tokenId,
          auction.paymentToken,
          auction.startingPrice,
          auction.endingPrice,
          auction.duration,
          auction.startedAt,
          auction.status
      );
  }
  function cancelAuctionByAuctionId(uint64 _auctionId) public {
      Auction storage auction = auctionIdToAuction[_auctionId];

      require(auction.startedAt > 0);
      require(msg.sender == auction.seller);


      auctions[auction.id].status = false;
      delete auctionIdToAuction[auction.id];
      delete tokenIdToAuction[auction.tokenId];

      _unescrow(auction.tokenId);
      emit AuctionCancelled(_auctionId, auction.tokenId);
  }

  function cancelAuctionByTokenId(uint256 _tokenId) public {
      Auction storage auction = tokenIdToAuction[_tokenId];

      require(auction.startedAt > 0);
      require(msg.sender == auction.seller);

      auctions[auction.id].status = false;
      delete auctionIdToAuction[auction.id];
      delete tokenIdToAuction[auction.tokenId];

      _unescrow(_tokenId);
      emit AuctionCancelled(auction.id, auction.tokenId);
  }

  function bid(uint256 _tokenId) public payable {
      Auction storage auction = tokenIdToAuction[_tokenId];

      require(auction.startedAt > 0);

      uint256 price = getCurrentPrice(auction);
      require(msg.value >= price);


      address payable seller = payable(auction.seller);

      auctions[auction.id].status = false;

      delete auctionIdToAuction[auction.id];
      delete tokenIdToAuction[auction.tokenId];
      
      
      activeAuctionsCount--;

      if (price > 0) {
          uint256 sellerProceeds = msg.value - (msg.value*fee/100000);
          seller.transfer(sellerProceeds);
      }

      NFTContract.approve(msg.sender, _tokenId);
      NFTContract.transferFrom(address(this), msg.sender, _tokenId);


      //update last bid price into Collectible contract

      ManekiCollectibles Contract = ManekiCollectibles(collectiblesContract);

      Contract.updateLastBidPrice( _tokenId, msg.value);

      emit AuctionSuccessful(auction.id, _tokenId,"CFX", msg.value, msg.sender);
  } 


  function bidByERC20 (uint256 _tokenId, IERC20 _paymentToken, uint256 _amount) public {
      Auction storage auction = tokenIdToAuction[_tokenId];
      uint256 price = getCurrentPrice(auction);
      string memory tokenSymbol;
      
      require(auction.startedAt > 0);
      require(_amount >= price , "bid is lower than current offer price");

      bool isValidPaymentToken = false;

      // identify which ERC20 token use as Payment
      // require ERC20 token approve to transfer for this contract
      for(uint i=0;i<ERC20Tokens.length;i++){
          if(ERC20Tokens[i].tokenAddress == _paymentToken){
              _paymentToken.transferFrom(msg.sender, address(this), _amount);
              
              tokenSymbol = ERC20Tokens[i].tokenSymbol;
              isValidPaymentToken = true;
            }
        }

      // valid ERC20 Token use as payment
      require(isValidPaymentToken == true, "invalid payment token");

      address payable seller = payable(auction.seller);

      //auction.isActive = false;

      if (price > 0) {
          uint256 sellerProceeds = _amount - (_amount*fee/100000);
          _paymentToken.transfer(seller,sellerProceeds);
      }

      NFTContract.approve(msg.sender, _tokenId);
      NFTContract.transferFrom(address(this), msg.sender, _tokenId);

      emit AuctionSuccessful(auction.id, _tokenId, tokenSymbol, price, msg.sender);
  } 


  function getActiveAuctions() public view returns(uint64 [] memory) {

    uint64[] memory activeAuctions = new uint64[](activeAuctionsCount);
    uint64 counter = 0; 

    for(uint64 i = 0; i < auctionId; i++){

        if(auctions[i].status == true){
            activeAuctions[counter] = auctions[i].id;
            counter++;
        }

    }
    return activeAuctions;
  }
  

  function getActiveAuctionCount() public view returns(uint256) {
    return activeAuctionsCount;
  }


  function getCurrentPriceByAuctionId(uint64 _auctionId) public view returns (uint256) {
      Auction storage auction = auctionIdToAuction[_auctionId];
      return getCurrentPrice(auction);
  }

  function getCurrentPriceByTokenId(uint256 _tokenId) public view returns (uint256) {
      Auction storage auction = tokenIdToAuction[_tokenId];
      return getCurrentPrice(auction);
  }

  function getCurrentPrice(Auction storage _auction) internal view returns (uint256) {
      require(_auction.startedAt > 0);
      uint256 secondsPassed = 0;

      secondsPassed = block.timestamp - _auction.startedAt;

      if (secondsPassed >= _auction.duration) {
          return _auction.endingPrice;
      } else {
          int256 totalPriceChange = int256(_auction.endingPrice) - int256(_auction.startingPrice);

          int256 currentPriceChange = totalPriceChange * int256(secondsPassed) / int256(_auction.duration);

          int256 currentPrice = int256(_auction.startingPrice) + currentPriceChange;

          return uint256(currentPrice);
      }
  }


    function withdrawalCoin (address payable _recipient) external onlyCLevel {
        require(_recipient != address(0) && _recipient != address(this));
        _recipient.transfer(address(this).balance);
        
        emit WITHDRAWALCOIN (_recipient, address(this).balance);
    }    

    function withdrawalToken (IERC20 _tokenAddress, address _recipient) external onlyCLevel() returns (address, uint256){
        
        address recipient = _recipient;
        
        _tokenAddress.approve(address(this), address(this).balance);
        _tokenAddress.transferFrom(address(this), recipient, address(this).balance);
        
        emit WITHDRAWALTOKEN (_tokenAddress, recipient,address(this).balance);
        return (recipient, address(this).balance);
    }

/** check ERC20 Token Balance in this contact
 */
    function checkERC20Balance (IERC20 _tokenAddress) external onlyCLevel() view returns  (uint){
        return _tokenAddress.balanceOf(address(this));
    }

    function totalTokens () external view returns (uint){
        return ERC20Tokens.length;
    }

    function addERC20Token (IERC20 _tokenAddress, string memory _tokenSymbol) public onlyCLevel() returns (bool){

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
                tokenStatus     : true
            });
    
            ERC20Tokens.push(newERC20Token);  
            
            emit ADDPAYMENTTOKEN (_tokenAddress, _tokenSymbol);
            return true;
            
        } else {
            return false;
        }
        
    }

    function setTokenStatus (IERC20 _tokenAddress, bool _tokenStatus) external onlyCLevel() returns (bool){
        for(uint i=0;i<ERC20Tokens.length;i++){
            if(ERC20Tokens[i].tokenAddress == _tokenAddress){
                ERC20Tokens[i].tokenStatus = _tokenStatus;
            }
        }
        return _tokenStatus;
    }

    /**
     * activeAuction()
     * auctionByWallet()
     */
  

}