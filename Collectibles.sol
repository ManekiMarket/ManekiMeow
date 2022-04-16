// SPDX-License-Identifier: MIT
// DEPLOYMENT CODE : CRC22MAR2022
// edited 22 MAR 22


pragma solidity 0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Clubhouse.sol";


contract ManekiCollectibles is ERC721 {
    using SafeMath for uint256;
    /**
     * Struct Clevel for authorize person to execute some restricted functions
     * Role : 1 as CEO, 2 as Management Team OR Premitted Contract 
     * Status : 1 as Active , 0 as inactive
     *
     * Struct Neko for NFT Token
     * Power : Maneki power for invite lucky coins
     * refCount : every neko eligible to refer up to 2 times
     *
     *
     */

    struct CLevel {
        address CLevelAddress;
        uint256 Role;
        bool Status;
    }

    struct Neko {
        uint256 power;
        uint256 DNA;
        uint256 refCount;
        uint256 gammaNekoID;
        uint256 piggyBank;
        uint256 lastPrice;
    }


    
    /**
     * List of existing CLevel
     * List of exisiting Neko
     * 
     */

    CLevel[] public CLevels;
    Neko  [] public Nekos;
    //string public baseURI = 'http://metadata.neko.exchange/';
    
    
    using Strings for uint256;
        
    // Optional mapping for token URIs
    mapping (uint256 => string) private _tokenURIs;
    
    
    // Base URI
    string private _baseURIextended;
    
    IERC20  manekiTokenAddress;
        
    address artistAddr;
    address developerAddr;
    
    uint256 manekiPoolSize;
    
    uint256 royaltyAmount;
    uint256 incentiveAmount;
    uint256 bonusAmount;
    uint256 artistAmount;
    uint256 developerAmount;
    
    address clubhouseContract;
    


    /**
     * Initializing an ERC-721 Token named 'Maneki-Meow' with a symbol 'Meow'
     *
     */

    constructor(IERC20 _nekoContractAddr, address _clubhouseContract, uint256 _manekiPoolSize, address _artistAddr, address _developerAddr) ERC721("Maneki-Meow", "MEOW") public {
        require(_artistAddr != address(0), "ERC20: transfer to the zero address");
        require(_developerAddr != address(0), "ERC20: transfer to the zero address");

        CLevel memory newCLevel = CLevel({
            CLevelAddress : msg.sender,
            Role : 1,
            Status : true
        });
        CLevels.push(newCLevel);
        
        clubhouseContract  = _clubhouseContract;
        
        manekiTokenAddress = _nekoContractAddr;
        manekiPoolSize     = _manekiPoolSize;
        
        royaltyAmount      = _manekiPoolSize*6/10;
        incentiveAmount    = _manekiPoolSize*1/10;
        bonusAmount        = _manekiPoolSize*1/10;
        artistAmount       = _manekiPoolSize*1/10;
        developerAmount    = _manekiPoolSize*1/10;
        
        artistAddr         = _artistAddr;
        developerAddr      = _developerAddr;
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




    /**
     * BIRTH - a new Neko is created
     * WITHDRAWAL - a withdraw is made
     * LUCKY_COINS - a lucky coin is invited
     * INCENTIVE - incentive sent to premium collector
     * ROLES - a new user is add or updated
     * ROYALTY - 1. Premium collector , 2. Artist ,  3 Developer 
     */
     
    event BIRTH (address owner, uint256 NekoId, uint256 power, uint256 DNA);
    event WITHDRAWAL (address indexed payee, uint256 amount, uint256 balance);
    event LUCKY_COINS (address indexed luckyWallet, uint256 indexed luckyNeko, uint256 amount, uint256 timestamp);
    
    event INCENTIVE (address indexed payee, uint256 amount,uint256 timestamp);
    event ARTIST (address indexed payee, uint256 amount,uint256 timestamp);
    event DEVELOPER (address indexed payee,  uint256 amount,uint256 timestamp);
    
    event BONUS (address indexed payee, uint256 gammaNekoID, uint256 amount, uint256 timestamp);
    
    event GIFT (address indexed sender, address indexed receiver,  uint256 NekoId);


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
    
    /**
     * mintRootNeko  - onlyCLevel able to mint
     * 1st Generation as alpha and 2nd Generation as beta
     * default refCount = 5
     * 3rd Generation as gamma, 4th Generation as Delta and 5th Generation as Epsilon
     * default refCount = 0
     * 0.0 ETH
     *
     * mintLuckyNeko - everyone able to mint
     * start from 6th Generation
     * 0.1 ETH
     *
     * mintFreeNeko - only use credit to mint
     * start from 6th Generation
     * 0.1 ETH
     *
     * kickstart Neko #0 will be generated by onwer
     *
     * mintRootNeko
     * Alpha , Bata NOT able to be referral
     * Gamma and above able to have 5 referral
     *
     */

    function mintRootNeko(uint256 _machine, uint256 _generation) external onlyCLevel() {
        require ( _generation <=6  && totalSupply() <= 1000000);

        uint256 DNA;
        uint256 manekiPower;
        (manekiPower,DNA)  = nekoDNA(_machine, _generation, 499999);

        createNeko(msg.sender, manekiPower, DNA, 0, 0);

    }


    
    /**
     * For call to Mint with ERC20 Token 
     * 
     * _refNekoId = 0 mean is direct from Dapp
     * _refNekoId > 0 mean is by referral
     *
     * verify refCount of the referral neko
     * Qualified : (refCount not more then 5 times refering)
     * New Neko Generation = refNeko's generation + 1
     * verify referral is a premiumCollectorIncentive
     *
     * Default generation 6, if without referral
     *
     */
     
    function mintCollectible (address _buyer, uint256 _machine, uint256 _refNekoId) external onlyCLevel() returns (uint256){
        
        require ( totalSupply() <= 1e6, "Minting Ended");
        require ( _buyer == ownerOf(_refNekoId), "You do not owned this meow");
        require ( _refNekoId > 0, "Must have a ref id");
        
        uint256 DNA;
        uint256 manekiPower;
        uint256 generation;
        uint256 _newGammaNekoID;
        uint256 refPower;
        uint256 newNekoId;

        Neko storage NEKO = Nekos[_refNekoId];

        // Each guardian have 2 blessing 
        require ( NEKO.refCount < 2 , "Out of blessing power");

        generation = NEKO.DNA.div(10**28).mod(1e6);

        if(generation==3 && generation >=3){
            _newGammaNekoID = _refNekoId;
        } else {
            _newGammaNekoID = NEKO.gammaNekoID;
        }

        generation += 1;
        NEKO.refCount += 1;
        Nekos[_refNekoId].refCount = NEKO.refCount;
        refPower = Nekos[_refNekoId].power;

        // genearate Neko DNA
        (manekiPower,DNA)  = nekoDNA(_machine, generation, refPower);
        
        // Mint Neko 
        newNekoId = createNeko(_buyer, manekiPower, DNA, 0, _newGammaNekoID);
        
        
        // Maneki Coins 
        luckyCoin();

        // Bonus for GammaNeko
        if (_newGammaNekoID != 0){
            gammaCollectorBonus(_newGammaNekoID);
        }   
        
        // Incenttive for Referrer 
        // >>  check the clublchouse
        Clubhouse Contract = Clubhouse(clubhouseContract);

        if (Contract.getReferrer(_buyer) != address(0x0)) {
            premiumCollectorIncentive(_buyer);
        }
        
        // Income for Artsits and Developers
        manekiPayout (address(this), payable(artistAddr), artistAmount);
        manekiPayout (address(this), payable(developerAddr), developerAmount);
        emit ARTIST (artistAddr,artistAmount, block.timestamp);
        emit DEVELOPER (developerAddr,developerAmount, block.timestamp);
        return newNekoId;
    }



    function createNeko(address _owner, uint256 _power, uint256 _DNA, uint256 _refCount, uint256 _gammaNekoID) private returns (uint){

        require(_owner != address(0));

        Neko memory newNeko = Neko({
            power       : _power,
            DNA         : _DNA,
            refCount    : _refCount,
            gammaNekoID : _gammaNekoID,
            piggyBank   : 0,
            lastPrice   : 0
        });

        Nekos.push(newNeko);
        uint256 newNekoId = Nekos.length-1;
        super._mint(_owner, newNekoId);

        emit BIRTH (_owner,newNekoId, newNeko.power, newNeko.DNA);
        return newNekoId;
    }

    function nekoDNA(uint256 _machine, uint256 _generation, uint256 _refPower) private view returns ( uint256, uint256){

       uint256 DNA;
       uint256 manekiPower;
       uint256 basePower;
       uint256[] memory generateDNA = new uint256[](5);

       uint256 energies = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty.add(_machine)))).mod(10**26);
 
       if( energies <=  10**25){
           energies += 10**25;
        }

        generateDNA[0] = energies.div(10**20).mod(100000);
        generateDNA[1] = energies.div(10**15).mod(100000);
        generateDNA[2] = energies.div(10**10).mod(100000);
        generateDNA[3] = energies.div(10**5).mod(100000);
        generateDNA[4] = energies.mod(10**5);

        basePower   = generateDNA[0] + generateDNA[1] + generateDNA[2] + generateDNA[3] + generateDNA[4];
        manekiPower = (_refPower/2) + basePower;

        DNA = energies;
        
        DNA = DNA.mul(10**6).add(manekiPower);
        DNA = DNA.mul(10**6).add(_generation);
        DNA = DNA.mul(10**22).add(_machine);
        DNA = DNA.mul(10**6).add(basePower);

        return (manekiPower,DNA);
   }

    /**
     * Lucky coins splited to 10 portions accordingly to Maneki Power
     * Higher Maneki Power will receive more lucky coins
     *
     */

    function luckyCoin() private returns(bool){
        address payable luckyWallet;
        address payable ownerWallet;
        
 
        uint256[] memory _nekoId = new uint256[](10);
        uint256[] memory _nekoPower = new uint256[](10);
        uint256 _sumPower = 0;

        uint256 _amount;
    

        uint256 random = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty)));
        uint256 factor = 1;

        for (uint i = 0; i < 10; i++) {
            
          // shift by factor and trim the Random number
          // Modular the trimed random number with total Neko Supply
          factor = factor.mul(10);
          _nekoId[i] = random.div(factor).mod(Nekos.length);

          Neko storage NEKO = Nekos[_nekoId[i]];
          _nekoPower[i] = NEKO.power;

          _sumPower = _sumPower.add(NEKO.power);

        }

        for (uint j = 0; j < 10; j++) {

          

          ownerWallet = payable(ownerOf(_nekoId[j]));
          luckyWallet = ownerWallet;

          _nekoPower[j] = _nekoPower[j].mul(royaltyAmount);

          _amount = _nekoPower[j].div(_sumPower);
          //_amount = _amount.mul(royaltyAmount);
          
          // Tranfers Maneki Coins to the lucky neko's owner
          manekiPayout (address(this), luckyWallet, _amount);

          // Update piggyBank
          depositPiggyBank (_nekoId[j] , _amount);
          
        
          emit LUCKY_COINS (luckyWallet, _nekoId[j], _amount, block.timestamp);
        }

        return  true;
    }

    /**
     * Premium Collector - Minimun Owned 10 NFT
     *
     */

    function premiumCollectorIncentive(address _participentAddr) internal {
        uint256 _amount ;
        
        Clubhouse Contract = Clubhouse(clubhouseContract);
        
        if (balanceOf(Contract.getReferrer(_participentAddr)) > 9){    
            
            //check referer
            if (balanceOf(Contract.getReferrer(_participentAddr)) > 99){
                // Premium Diamond Collector full
                _amount = incentiveAmount;
            } else {
                // Premium Gold Collector half
                _amount = incentiveAmount/2;
            }
            
            address payable _payee;
            _payee = payable(Contract.getReferrer(_participentAddr));
                
            // Tranfers ERC20 Token to Premium Collector 
            manekiPayout (address(this), _payee, _amount);
            emit INCENTIVE (_payee, _amount, block.timestamp);
     
            
        }
    }
    
    
    /** 
     * send as gitf to a friend (walletAddress)
     */
    function sendAsGift (address receiverAddrs , uint256 tokenId) public {
        transferFrom(msg.sender, receiverAddrs, tokenId);
        emit GIFT (msg.sender, receiverAddrs,  tokenId);
        
        Clubhouse Contract = Clubhouse(clubhouseContract);
        
        // if this Receiver not yet tie with a referrer , add this receiver 
        if (Contract.getReferrer(receiverAddrs) == address(0x0)) {
            Contract.addMember(receiverAddrs,msg.sender);
        }    
    }
    
    /**
     * if the referred from a Gamma Neko
     * Gamma collector eligible to get 0.01 ETH Bonus for each referral
     *
     */
    function gammaCollectorBonus(uint256 _GammaNekoID) private{
            address payable _payee;
            uint256 _amount = bonusAmount;
            _payee = payable(ownerOf(_GammaNekoID));
            
            // Tranfers ERC20 Token to Premium Collector 
            manekiPayout (address(this), _payee, _amount);

            // update piggyBank
            depositPiggyBank (_GammaNekoID , _amount);

            emit BONUS (_payee, _GammaNekoID, _amount, block.timestamp);

    }

 
    function manekiPayout(address _contractAdds, address payable _payee, uint256 _amount) internal{
        
            manekiTokenAddress.approve(_contractAdds,_amount);
            manekiTokenAddress.allowance(_contractAdds,_payee);
            manekiTokenAddress.transferFrom(_contractAdds, _payee, _amount);
    }

    /**
     * retrieve a specific Neko's details.
     * NekoId ID of the Neko who's details will be retrieved
     *
     */

    function getNekoDetails(uint256 NekoId) external view returns (uint256, uint256, uint256, uint256) {
        Neko storage NEKO = Nekos[NekoId];
        return (NekoId, NEKO.power, NEKO.DNA, NEKO.refCount);
    }

    /**
     * get a list of owned Nekos' IDs
     *
     */
    function ownedNekos() external view returns(uint256[] memory) {
        uint256 NekoCount = balanceOf(msg.sender);
        if (NekoCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](NekoCount);
            uint256 totalNekos = Nekos.length;
            uint256 resultIndex = 0;
            uint256 NekoId = 0;
            while (NekoId < totalNekos) {
                if (ownerOf(NekoId) == msg.sender) {
                    result[resultIndex] = NekoId;
                    resultIndex = resultIndex.add(1);
                }
                NekoId = NekoId.add(1);
            }
            return result;
        }
    }


    // update last bid price
    function updateLastBidPrice(uint256 _tokenId, uint256 price) external{
        Nekos[_tokenId].lastPrice = price;
    }
    
    /**
    * send / withdraw _amount to _payee onlyCLevel
    *
    */

    function withdrawal(address payable _payee, uint256 _amount) external onlyClevel() {
        require(_payee != address(0) && _payee != address(this));
        require(_amount > 0 && _amount <= address(this).balance);
        _payee.transfer(_amount);
        emit WITHDRAWAL (_payee, _amount, address(this).balance);
    }
    
    function deposit (uint256 _amount) external payable {
        require(msg.value ==  _amount);
        address from = msg.sender;
    }

    function totalSupply() public view returns (uint){
        return Nekos.length;
    }

    
    function setBaseURI(string memory baseURI_) external onlyCLevel() {
        _baseURIextended = baseURI_;
    }
        
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token"); 
        _tokenURIs[tokenId] = _tokenURI;
    }
        
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }    
    

    function getManekiPool () external view returns (uint256, uint256){
        return (manekiPoolSize, royaltyAmount);
    }

    function getPiggyBank ( uint256 _nekoID ) external view returns (uint256){
        return Nekos[_nekoID].piggyBank;
    }

    function depositPiggyBank ( uint256 _nekoID , uint256 _amount) internal returns (uint256){
        Nekos[_nekoID].piggyBank += _amount;
        return Nekos[_nekoID].piggyBank;
    }
     
}
