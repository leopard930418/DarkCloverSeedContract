pragma solidity 0.8.13;

// SPDX-License-Identifier: MIT

import "./IContract.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract CloverDarkSeedController is Ownable {
    using SafeMath for uint256;

    address public CloverDarkSeedToken;
    address public CloverDarkSeedNFT;
    address public CloverDarkSeedPicker;
    address public CloverDarkSeedStake;
    address public CloverDarkSeedPotion;
    address public teamWallet;

    uint256 public totalCloverFieldMinted;
    uint256 public totalCloverYardMinted;
    uint256 public totalCloverPotMinted;

    uint256 private _totalCloverYardMinted = 1e3;
    uint256 private _totalCloverPotMinted = 11e3;

    uint256 public totalCloverFieldCanMint = 1e3;
    uint256 public totalCloverYardCanMint = 1e4;
    uint256 public totalCloverPotCanMint = 1e5;

    uint256 public maxMintAmount = 100;
    
    uint16 public nftBuyFeeForTeam = 40;
    uint16 public nftBuyFeeForMarketing = 60;
    uint16 public nftBuyFeeForLiquidity = 100;
    uint16 public nftBuyBurn = 300;

    uint256 public cloverFieldPrice = 1e20;
    uint256 public cloverYardPrice = 1e19;
    uint256 public cloverPotPrice = 1e18;

    uint8 private fieldPercentByPotion = 2;
    uint8 private yardPercentByPotion = 28;
    uint8 private potPercentByPotion = 70;

    uint256 public tokenAmountForPoorPotion = 5e17;
    bool public isContractActivated = false;

    mapping(address => bool) public isTeamAddress;
    mapping(address => uint16) public mintAmount;
    
    mapping(uint256 => bool) private isCloverFieldCarbon;
    mapping(uint256 => bool) private isCloverFieldPearl;
    mapping(uint256 => bool) private isCloverFieldRuby;
    mapping(uint256 => bool) private isCloverFieldDiamond;

    mapping(uint256 => bool) private isCloverYardCarbon;
    mapping(uint256 => bool) private isCloverYardPearl;
    mapping(uint256 => bool) private isCloverYardRuby;
    mapping(uint256 => bool) private isCloverYardDiamond;

    mapping(uint256 => bool) private isCloverPotCarbon;
    mapping(uint256 => bool) private isCloverPotPearl;
    mapping(uint256 => bool) private isCloverPotRuby;
    mapping(uint256 => bool) private isCloverPotDiamond;
    
    mapping(uint256 => address) private _owners;

    uint256 private lastMintedTokenId ;

    event RewardsTransferred(address holder, uint256 amount);

    constructor(address _teamWallet, address _CloverDarkSeedToken, address _CloverDarkSeedNFT, address _CloverDarkSeedPotion) {
        CloverDarkSeedToken = _CloverDarkSeedToken;
        CloverDarkSeedNFT = _CloverDarkSeedNFT;
        CloverDarkSeedPotion = _CloverDarkSeedPotion;
        teamWallet = _teamWallet;
        isTeamAddress[owner()] = true;
    }

    function isCloverFieldCarbon_(uint256 tokenId) public view returns (bool) {
        return isCloverFieldCarbon[tokenId];
    }

    function isCloverFieldPearl_(uint256 tokenId) public view returns (bool) {
        return isCloverFieldPearl[tokenId];
    }

    function isCloverFieldRuby_(uint256 tokenId) public view returns (bool) {
        return isCloverFieldRuby[tokenId];
    }

    function isCloverFieldDiamond_(uint256 tokenId) public view returns (bool) {
        return isCloverFieldDiamond[tokenId];
    }

    function isCloverYardCarbon_(uint256 tokenId) public view returns (bool) {
        return isCloverYardCarbon[tokenId];
    }

    function isCloverYardPearl_(uint256 tokenId) public view returns (bool) {
        return isCloverYardPearl[tokenId];
    }

    function isCloverYardRuby_(uint256 tokenId) public view returns (bool) {
        return isCloverYardRuby[tokenId];
    }

    function isCloverYardDiamond_(uint256 tokenId) public view returns (bool) {
        return isCloverYardDiamond[tokenId];
    }

    function isCloverPotCarbon_(uint256 tokenId) public view returns (bool) {
        return isCloverPotCarbon[tokenId];
    }

    function isCloverPotPearl_(uint256 tokenId) public view returns (bool) {
        return isCloverPotPearl[tokenId];
    }

    function isCloverPotRuby_(uint256 tokenId) public view returns (bool) {
        return isCloverPotRuby[tokenId];
    }

    function isCloverPotDiamond_(uint256 tokenId) public view returns (bool) {
        return isCloverPotDiamond[tokenId];
    }

    function updateNftBuyFeeFor_Team_Marketing_Liquidity(uint16 _team, uint16 _mark, uint16 _liqu, uint16 _burn) public onlyOwner {
        nftBuyFeeForTeam = _team;
        nftBuyFeeForMarketing = _mark;
        nftBuyFeeForLiquidity = _liqu;
        nftBuyBurn = _burn;
    }

    function freeMint(uint8 fieldCnt, uint8 yardCnt, uint8 potCnt, address acc) public onlyOwner {
        require(totalCloverFieldMinted + fieldCnt <= totalCloverFieldCanMint, "Controller: All Clover Field Has Minted..");
        require(totalCloverYardMinted + yardCnt <= totalCloverYardCanMint, "Controller: All Clover Yard Has Minted..");
        require(totalCloverPotMinted + potCnt <= totalCloverPotCanMint, "Controller: All Clover Pot Has Minted..");

        uint256 tokenID;
        for(uint8 i = 0; i < fieldCnt; i++) {
            IContract(CloverDarkSeedPicker).randomNumber(i);
            tokenID = totalCloverFieldMinted + 1;
            IContract(CloverDarkSeedNFT).mint(acc, tokenID);
        } 
        for(uint8 i = 0; i < yardCnt; i++) {
            IContract(CloverDarkSeedPicker).randomNumber(i + fieldCnt);
            tokenID = _totalCloverYardMinted + 1;
            IContract(CloverDarkSeedNFT).mint(acc, tokenID);
        }  
        for(uint8 i = 0; i < potCnt; i++) {
            IContract(CloverDarkSeedPicker).randomNumber(i + fieldCnt + yardCnt);
            tokenID = _totalCloverPotMinted + 1;
            IContract(CloverDarkSeedNFT).mint(acc, tokenID);
        }      
    }

    function buyCloverField(uint256 entropy) public {
        require(totalCloverFieldMinted + 1 <= totalCloverFieldCanMint, "Controller: All Clover Field Has Minted..");
        require(isContractActivated, "Controller: Contract is not activeted yet..");
        address to = msg.sender;
        uint256 tokenId = totalCloverFieldMinted + 1;
        uint256 random = IContract(CloverDarkSeedPicker).randomNumber(entropy);

        bool lucky = ((random >> 245) % 20) == 0 ;

        if (lucky) {
            address luckyWalletForCloverField = IContract(CloverDarkSeedStake).getLuckyWalletForCloverField();
            if (luckyWalletForCloverField != address(0)) {
                to = luckyWalletForCloverField;
            }
        }

        uint256 liquidityFee = cloverFieldPrice.div(1e3).mul(nftBuyFeeForLiquidity);
        uint256 marketingFee = cloverFieldPrice.div(1e3).mul(nftBuyFeeForMarketing);
        uint256 teamFee = cloverFieldPrice.div(1e3).mul(nftBuyFeeForTeam);
        uint256 burnAmt = cloverFieldPrice.div(1e3).mul(nftBuyBurn);

        if (!isTeamAddress[msg.sender]) {
            if (cloverFieldPrice > 0) {
                IContract(CloverDarkSeedToken).burnForNFT(burnAmt);
                IContract(CloverDarkSeedToken).Approve(address(this), cloverFieldPrice - burnAmt);
                IContract(CloverDarkSeedToken).transferFrom(msg.sender, CloverDarkSeedToken, cloverFieldPrice - burnAmt);
                IContract(CloverDarkSeedToken).AddFeeS(marketingFee, teamFee, liquidityFee);
            }
        }
        IContract(CloverDarkSeedNFT).mint(to, tokenId);
    }

    function buyCloverYard(uint256 entropy) public {
        require(totalCloverYardMinted + 1 <= totalCloverYardCanMint, "Controller: All Clover Yard Has Minted..");
        require(isContractActivated, "Controller: Contract is not activeted yet..");

        address to = msg.sender;
        uint256 tokenId = _totalCloverYardMinted + 1;

        uint256 random = IContract(CloverDarkSeedPicker).randomNumber(entropy);
        bool lucky = ((random >> 245) % 20) == 0 ;

        if (lucky) {
            address luckyWalletForCloverYard = IContract(CloverDarkSeedStake).getLuckyWalletForCloverYard();
            if (luckyWalletForCloverYard != address(0)) {
                to = luckyWalletForCloverYard;
            }
        }

        uint256 liquidityFee = cloverYardPrice.div(1e3).mul(nftBuyFeeForLiquidity);
        uint256 marketingFee = cloverYardPrice.div(1e3).mul(nftBuyFeeForMarketing);
        uint256 teamFee = cloverYardPrice.div(1e3).mul(nftBuyFeeForTeam);
        uint256 burnAmt = cloverYardPrice.div(1e3).mul(nftBuyBurn);
        
        if (!isTeamAddress[msg.sender]) {

            if (cloverYardPrice > 0) {
                IContract(CloverDarkSeedToken).burnForNFT(burnAmt);
                IContract(CloverDarkSeedToken).Approve(address(this), cloverYardPrice - burnAmt);
                IContract(CloverDarkSeedToken).transferFrom(msg.sender, CloverDarkSeedToken, cloverYardPrice - burnAmt);
                IContract(CloverDarkSeedToken).AddFeeS(marketingFee, teamFee, liquidityFee);
            }
        }
        
        IContract(CloverDarkSeedNFT).mint(to, tokenId);
    }

    function buyCloverPot(uint256 entropy) public {
        require(totalCloverPotMinted + 1 <= totalCloverPotCanMint, "Controller: All Clover Pot Has Minted..");
        require(isContractActivated, "Controller: Contract is not activeted yet..");

        address to = msg.sender;
        uint256 tokenId = _totalCloverPotMinted + 1;

        uint256 random = IContract(CloverDarkSeedPicker).randomNumber(entropy);
        bool lucky = ((random >> 245) % 20) == 0 ;

        if (lucky) {
            address luckyWalletForCloverPot = IContract(CloverDarkSeedStake).getLuckyWalletForCloverPot();
            if (luckyWalletForCloverPot != address(0)) {
                to = luckyWalletForCloverPot;
            }
        }

        uint256 liquidityFee = cloverPotPrice.div(1e3).mul(nftBuyFeeForLiquidity);
        uint256 marketingFee = cloverPotPrice.div(1e3).mul(nftBuyFeeForMarketing);
        uint256 teamFee = cloverPotPrice.div(1e3).mul(nftBuyFeeForTeam);
        uint256 burnAmt = cloverPotPrice.div(1e3).mul(nftBuyBurn);

        if (!isTeamAddress[msg.sender]) {
            if (cloverPotPrice > 0) {
                IContract(CloverDarkSeedToken).burnForNFT(burnAmt);
                IContract(CloverDarkSeedToken).Approve(address(this), cloverPotPrice - burnAmt);
                IContract(CloverDarkSeedToken).transferFrom(msg.sender, CloverDarkSeedToken, cloverPotPrice - burnAmt);
                IContract(CloverDarkSeedToken).AddFeeS(marketingFee, teamFee, liquidityFee);
            }
        }
        
        IContract(CloverDarkSeedNFT).mint(to, tokenId);
    }

    function setTokenForPoorPotion(uint256 amt) public onlyOwner {
        tokenAmountForPoorPotion = amt;
    }

    function setPotionPercentage(uint8 _potionField, uint8 _potionYard, uint8 _potionPot) public onlyOwner {
        fieldPercentByPotion = _potionField;
        yardPercentByPotion = _potionYard;
        potPercentByPotion = _potionPot;
    }
    function mintUsingPotion(uint256 entropy, bool isNormal) public {
        if (isNormal) {
            uint256 tokenID;
            uint8 random = uint8(IContract(CloverDarkSeedPicker).randomNumber(entropy) % 100);
            if (random < potPercentByPotion) {
                tokenID = _totalCloverPotMinted + 1;
            } else if (random < potPercentByPotion + yardPercentByPotion) {
                tokenID = _totalCloverYardMinted + 1;
            } else {
                tokenID = totalCloverFieldMinted + 1;
            }
            IContract(CloverDarkSeedNFT).mint(msg.sender, tokenID);
        } else {
            IContract(CloverDarkSeedToken).sendToken2Account(msg.sender, tokenAmountForPoorPotion);
        }
        IContract(CloverDarkSeedPotion).burn(msg.sender, isNormal);
    }

    function addMintedTokenId(uint256 tokenId) public returns (bool) {
        require(msg.sender == CloverDarkSeedNFT, "Controller: Only for Seeds NFT..");
        require(mintAmount[tx.origin] <= maxMintAmount, "You have already minted all nfts.");
        
        if (tokenId <= totalCloverFieldCanMint) {
            totalCloverFieldMinted = totalCloverFieldMinted.add(1);
        }

        if (tokenId > totalCloverFieldCanMint && tokenId <= totalCloverYardCanMint) {
            _totalCloverYardMinted = _totalCloverYardMinted.add(1);
            totalCloverYardMinted = totalCloverYardMinted.add(1);
        }

        if (tokenId > totalCloverYardCanMint && tokenId <= totalCloverPotCanMint) {
            _totalCloverPotMinted = _totalCloverPotMinted.add(1);
            totalCloverPotMinted = totalCloverPotMinted.add(1);
        }

        lastMintedTokenId = tokenId;
        mintAmount[tx.origin]++;
        return true;
    }

    function readMintedTokenURI() public view returns(string memory) {
        string memory uri = IContract(CloverDarkSeedNFT).tokenURI(lastMintedTokenId);
        return uri;
    }

    function addAsCloverFieldCarbon(uint256 tokenId) public returns (bool) {
        require(msg.sender == CloverDarkSeedPicker, "Controller: You are not CloverDarkSeedPicker..");
        isCloverFieldCarbon[tokenId] = true;
        return true;
    }

    function addAsCloverFieldPearl(uint256 tokenId) public returns (bool) {
        require(msg.sender == CloverDarkSeedPicker, "Controller: You are not CloverDarkSeedPicker..");
        isCloverFieldPearl[tokenId] = true;
        return true;
    }

    function addAsCloverFieldRuby(uint256 tokenId) public returns (bool) {
        require(msg.sender == CloverDarkSeedPicker, "Controller: You are not CloverDarkSeedPicker..");
        isCloverFieldRuby[tokenId] = true;
        return true;
    }

    function addAsCloverFieldDiamond(uint256 tokenId) public returns (bool) {
        require(msg.sender == CloverDarkSeedPicker, "Controller: You are not CloverDarkSeedPicker..");
        isCloverFieldDiamond[tokenId] = true;
        return true;
    }

    function addAsCloverYardCarbon(uint256 tokenId) public returns (bool) {
        require(msg.sender == CloverDarkSeedPicker, "Controller: You are not CloverDarkSeedPicker..");
        isCloverYardCarbon[tokenId] = true;
        return true;
    }

    function addAsCloverYardPearl(uint256 tokenId) public returns (bool) {
        require(msg.sender == CloverDarkSeedPicker, "Controller: You are not CloverDarkSeedPicker..");
        isCloverYardPearl[tokenId] = true;
        return true;
    }

    function addAsCloverYardRuby(uint256 tokenId) public returns (bool) {
        require(msg.sender == CloverDarkSeedPicker, "Controller: You are not CloverDarkSeedPicker..");
        isCloverYardRuby[tokenId] = true;
        return true;
    }

    function addAsCloverYardDiamond(uint256 tokenId) public returns (bool) {
        require(msg.sender == CloverDarkSeedPicker, "Controller: You are not CloverDarkSeedPicker..");
        isCloverYardDiamond[tokenId] = true;
        return true;
    }

    function addAsCloverPotCarbon(uint256 tokenId) public returns (bool) {
        require(msg.sender == CloverDarkSeedPicker, "Controller: You are not CloverDarkSeedPicker..");
        isCloverPotCarbon[tokenId] = true;
        return true;
    }

    function addAsCloverPotPearl(uint256 tokenId) public returns (bool) {
        require(msg.sender == CloverDarkSeedPicker, "Controller: You are not CloverDarkSeedPicker..");
        isCloverPotPearl[tokenId] = true;
        return true;
    }

    function addAsCloverPotRuby(uint256 tokenId) public returns (bool) {
        require(msg.sender == CloverDarkSeedPicker, "Controller: You are not CloverDarkSeedPicker..");
        isCloverPotRuby[tokenId] = true;
        return true;
    }

    function addAsCloverPotDiamond(uint256 tokenId) public returns (bool) {
        require(msg.sender == CloverDarkSeedPicker, "Controller: You are not CloverDarkSeedPicker..");
        isCloverPotDiamond[tokenId] = true;
        return true;
    }

    function ActiveThisContract() public onlyOwner {
        isContractActivated = true;
    }

    function setCloverDarkSeedPicker(address _CloverDarkSeedPicker) public onlyOwner {
        CloverDarkSeedPicker = _CloverDarkSeedPicker;
    }

    function setCloverDarkSeedStake(address _CloverDarkSeedStake) public onlyOwner {
        CloverDarkSeedStake = _CloverDarkSeedStake;
    }

    function setTeamAddress(address account) public onlyOwner {
        isTeamAddress[account] = true;
    }

    function set_CloverDarkSeedToken(address SeedsToken) public onlyOwner {
        CloverDarkSeedToken = SeedsToken;
    }

    function set_CloverDarkSeedNFT(address nftToken) public onlyOwner {
        CloverDarkSeedNFT = nftToken;
    }

    function setCloverFieldPrice(uint256 price) public onlyOwner {
        cloverFieldPrice = price;
    }

    function setCloverYardPrice(uint256 price) public onlyOwner {
        cloverYardPrice = price;
    }

    function setCloverPotPrice (uint256 price) public onlyOwner {
        cloverPotPrice = price;
    }

    function setCloverDarkPotion(address _CloverDarkSeedPotion) public onlyOwner {
        CloverDarkSeedPotion = _CloverDarkSeedPotion;
    }

    function setTeamWallet(address _teamWallet) public onlyOwner {
        teamWallet = _teamWallet;
    }

    // function to allow admin to transfer *any* BEP20 tokens from this contract..
    function transferAnyBEP20Tokens(address tokenAddress, address recipient, uint256 amount) public onlyOwner {
        require(amount > 0, "SEED$ Controller: amount must be greater than 0");
        require(recipient != address(0), "SEED$ Controller: recipient is the zero address");
        IContract(tokenAddress).transfer(recipient, amount);
    }
}