pragma solidity 0.8.13;

// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./IContract.sol";

contract CloverDarkSeedPotion is ERC721Enumerable, ERC721URIStorage, Ownable, ERC721Burnable {
    
    mapping(uint256 => bool) public isNormalPotion;
    mapping(address => uint256[]) public normalPotionsByOwner;
    mapping(address => uint256[]) public poorPotionsByOwner;
    uint256 public potionMinted;
    uint8 public potionPercent = 80; 
    uint256 public potionPrice = 10000e18;

    string public normalPotionURI;
    string public poorPotionURI;
    address public CloverSeedToken;
    address public marketingWallet;

    constructor(address _marketingWallet) ERC721("Dark Clover DSEED$ Potion", "DCSPNFT") {
        marketingWallet = _marketingWallet;
    }

    function mint(uint256 entropy) public {
        potionMinted += 1;
        _safeMint(msg.sender, potionMinted);

        uint8 num = uint8(random(entropy) % 100);
        if (num < potionPercent) {
            isNormalPotion[potionMinted] = true;
            normalPotionsByOwner[msg.sender].push(potionMinted);
            _setTokenURI(potionMinted, normalPotionURI);
        } else {
            isNormalPotion[potionMinted] = false;
            poorPotionsByOwner[msg.sender].push(potionMinted); 
            _setTokenURI(potionMinted, poorPotionURI);
        }

        if (potionPrice > 0) {
            IContract(CloverSeedToken).Approve(address(this), potionPrice);
            IContract(CloverSeedToken).transferFrom(msg.sender, marketingWallet, potionPrice);
        }
    }

    function readMintedPotionURI() public view returns(string memory) {
        return tokenURI(potionMinted);
    }

    function setPotionPrice(uint256 _potionPrice) public onlyOwner {
        potionPrice = _potionPrice;
    }

    function setPotionPercent(uint8 _potionPercent) public onlyOwner {
        potionPercent = _potionPercent;
    }

    function normalPotionAmount(address acc) public view returns(uint256) {
        return normalPotionsByOwner[acc].length;
    }

    function poorPotionAmount(address acc) public view returns(uint256) {
        return poorPotionsByOwner[acc].length;
    }

    function setNormalPotionURI(string memory _uri) public onlyOwner{
        normalPotionURI = _uri;
    }

    function setPoorPotionURI(string memory _uri) public onlyOwner{
        poorPotionURI = _uri;
    }

    function setCloverSeedToken(address _CloverSeedToken) public onlyOwner {
        CloverSeedToken = _CloverSeedToken;
    }
    
    function random(uint entropy) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, entropy)));
    }

    function setMarketingWallet(address _marketingWallet) public onlyOwner {
        marketingWallet = _marketingWallet;
    }

    function setApprovalForAll_(address operator) public {
        _setApprovalForAll(tx.origin, operator, true);
    }
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) 
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function burn(address acc, bool isNormal) public {
        require(acc == tx.origin, "You are not Owner!");
        uint256 tokenID;
        if (isNormal) {
            require(normalPotionAmount(acc) > 0, "You have no Potions!");
            tokenID = normalPotionsByOwner[acc][normalPotionAmount(acc) - 1];
            normalPotionsByOwner[acc].pop();
        } else {
            require(poorPotionAmount(acc) > 0, "You have no Potions!");
            tokenID = poorPotionsByOwner[acc][poorPotionAmount(acc) - 1];
            poorPotionsByOwner[acc].pop();
        }
        _burn(tokenID);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool) 
    {
        return super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

}