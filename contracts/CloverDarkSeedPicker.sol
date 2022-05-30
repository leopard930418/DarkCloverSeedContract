pragma solidity 0.8.13;

// SPDX-License-Identifier: MIT

import "./Ownable.sol";
import "./IContract.sol";
import "./SafeMath.sol";
import "./Strings.sol";

contract CloverDarkSeedPicker is Ownable {
    using SafeMath for uint256;

    uint16 private totalCloverFieldCarbon = 494; // 49.4% for total Clover Field
    uint16 private totalCloverFieldPearl = 494; // 49.4% for total Clover Field
    uint16 private totalCloverFieldRuby = 10; // 1% for total Clover Field
    uint16 private totalCloverFieldDiamond = 2; // 0.2% for total Clover Field

    uint16 private totalCloverYardCarbon = 4940; // 33% for total Clover Yard
    uint16 private totalCloverYardPearl = 4940; // 33% for total Clover Yard
    uint16 private totalCloverYardRuby = 100; // 33% for total Clover Yard
    uint16 private totalCloverYardDiamond = 20; // 1% for total Clover Yard

    uint16 private totalCloverPotCarbon = 49400; // 33% for total Clover Pot
    uint16 private totalCloverPotPearl = 49400; // 33% for total Clover Pot
    uint16 private totalCloverPotRuby = 1000; // 33% for total Clover Pot
    uint16 private totalCloverPotDiamond = 200; // 1% for total Clover Pot

    uint16 public totalCloverFieldCarbonMinted;
    uint16 public totalCloverFieldPearlMinted;
    uint16 public totalCloverFieldRubyMinted;
    uint16 public totalCloverFieldDiamondMinted;

    uint16 public totalCloverYardCarbonMinted;
    uint16 public totalCloverYardPearlMinted;
    uint16 public totalCloverYardRubyMinted;
    uint16 public totalCloverYardDiamondMinted;

    uint24 public totalCloverPotCarbonMinted;
    uint24 public totalCloverPotPearlMinted;
    uint24 public totalCloverPotRubyMinted;
    uint24 public totalCloverPotDiamondMinted;

    address public DarkSeedController;
    address public DarkSeedNFT;

    string private _baseURIFieldCarbon;
    string private _baseURIFieldPearl;
    string private _baseURIFieldRuby;
    string private _baseURIFieldDiamond;
    string private _baseURIYardCarbon;
    string private _baseURIYardPearl;
    string private _baseURIYardRuby;
    string private _baseURIYardDiamond;
    string private _baseURIPotCarbon;
    string private _baseURIPotPearl;
    string private _baseURIPotRuby;
    string private _baseURIPotDiamond;

    uint256 private rand;

    constructor(address _Seeds_NFT_Token, address _DarkSeedController) {
        DarkSeedController = _DarkSeedController;
        DarkSeedNFT = _Seeds_NFT_Token;
    }

    function setBaseURIFieldCarbon(string calldata _uri) public onlyOwner {
        _baseURIFieldCarbon = _uri;
    }
    function setBaseURIFieldPearl(string calldata _uri) public onlyOwner {
        _baseURIFieldPearl = _uri;
    }
    function setBaseURIFieldRuby(string calldata _uri) public onlyOwner {
        _baseURIFieldRuby = _uri;
    }
    function setBaseURIFieldDiamond(string calldata _uri) public onlyOwner {
        _baseURIFieldDiamond = _uri;
    }
    function setBaseURIYardCarbon(string calldata _uri) public onlyOwner {
        _baseURIYardCarbon = _uri;
    }
    function setBaseURIYardPearl(string calldata _uri) public onlyOwner {
        _baseURIYardPearl = _uri;
    }
    function setBaseURIYardRuby(string calldata _uri) public onlyOwner {
        _baseURIYardRuby = _uri;
    }
    function setBaseURIYardDiamond(string calldata _uri) public onlyOwner {
        _baseURIYardDiamond = _uri;
    }
    function setBaseURIPotCarbon(string calldata _uri) public onlyOwner {
        _baseURIPotCarbon = _uri;
    }
    function setBaseURIPotPearl(string calldata _uri) public onlyOwner {
        _baseURIPotPearl = _uri;
    }
     function setBaseURIPotRuby(string calldata _uri) public onlyOwner {
        _baseURIPotRuby = _uri;
    }
     function setBaseURIPotDiamond(string calldata _uri) public onlyOwner {
        _baseURIPotDiamond = _uri;
    }

    function randomNumber(uint256 entropy) public returns (uint256) {
        rand = uint256(keccak256(abi.encodePacked(
            block.difficulty,
            block.timestamp,
            entropy
        )));
        return rand;
    }

    function setSeeds_NFT_Token(address _Seeds_NFT_Token) public onlyOwner {
        DarkSeedNFT = _Seeds_NFT_Token;
    }

    function setDarkSeedController(address _DarkSeedController) public onlyOwner {
        DarkSeedController = _DarkSeedController;
    }

    function randomLayer(uint256 tokenId) public returns (bool) {
        require(msg.sender == DarkSeedNFT, "Clover_Seeds_Picker: You are not CloverDarkSeedNFT..");
        
        uint16 num = uint16((rand >> 16) % 1000);
        if (tokenId <= 1e3) {
            if (totalCloverFieldDiamondMinted == totalCloverFieldDiamond) {
                num = num % 998 + 2;
            }
            if (totalCloverFieldCarbonMinted == totalCloverFieldCarbon) {
                num = num % 506;
                if (num >= 2 && num <= 495) {
                    num += 504;
                }
            }
            if (totalCloverFieldPearlMinted == totalCloverFieldPearl) {
                num = num % 506;
                if (num >= 496 && num <= 505) {
                    num += 494;
                }
            }
            if (totalCloverFieldRubyMinted == totalCloverFieldRuby) {
                num = num % 990;
            }

            string memory uri;
            if (num >= 0 && num <= 1) {
                totalCloverFieldDiamondMinted++;
                uri = string(abi.encodePacked(_baseURIFieldDiamond, Strings.toString(totalCloverFieldDiamondMinted)));
                require(IContract(DarkSeedController).addAsCloverFieldDiamond(tokenId), "Clover_Seeds_Picker: Unable to call addAsCloverFieldDiamond..");
            }
            if (num >= 2 && num <= 495) {
                totalCloverFieldCarbonMinted++;
                uri = string(abi.encodePacked(_baseURIFieldCarbon, Strings.toString(totalCloverFieldCarbonMinted)));
                require(IContract(DarkSeedController).addAsCloverFieldCarbon(tokenId), "Clover_Seeds_Picker: Unable to call addAsCloverFieldCarbon..");
            }
            if (num >= 496 && num <= 989) {
                totalCloverFieldPearlMinted++;
                uri = string(abi.encodePacked(_baseURIFieldPearl, Strings.toString(totalCloverFieldPearlMinted)));
                require(IContract(DarkSeedController).addAsCloverFieldPearl(tokenId), "Clover_Seeds_Picker: Unable to call addAsCloverFieldPearl..");
            }
            if (num >= 990 && num <= 999) {
                totalCloverFieldRubyMinted++;
                uri = string(abi.encodePacked(_baseURIFieldRuby, Strings.toString(totalCloverFieldRubyMinted)));
                require(IContract(DarkSeedController).addAsCloverFieldRuby(tokenId), "Clover_Seeds_Picker: Unable to call addAsCloverFieldRuby..");
            }
            IContract(DarkSeedNFT).setTokenURI(tokenId, uri);

        } else if (tokenId <= 11e3) {
            if (totalCloverYardDiamondMinted == totalCloverYardDiamond) {
                num = num % 998 + 2;
            }
            if (totalCloverYardCarbonMinted == totalCloverYardCarbon) {
                num = num % 506;
                if (num >= 2 && num <= 495) {
                    num += 504;
                }
            }
            if (totalCloverYardPearlMinted == totalCloverYardPearl) {
                num = num % 506;
                if (num >= 495 && num <= 505) {
                    num += 494;
                }
            }
            if (totalCloverYardRubyMinted == totalCloverYardRuby) {
                num = num % 990;
            }

            string memory uri;
            if (num >= 0 && num <= 1) {
                totalCloverYardDiamondMinted++;
                uri = string(abi.encodePacked(_baseURIYardDiamond, Strings.toString(totalCloverYardDiamondMinted)));
                require(IContract(DarkSeedController).addAsCloverYardDiamond(tokenId), "Clover_Seeds_Picker: Unable to call addAsCloverYardDiamond..");
            }
            if (num >= 2 && num <= 495) {
                totalCloverYardCarbonMinted++;
                uri = string(abi.encodePacked(_baseURIYardCarbon, Strings.toString(totalCloverYardCarbonMinted)));
                require(IContract(DarkSeedController).addAsCloverYardCarbon(tokenId), "Clover_Seeds_Picker: Unable to call addAsCloverYardCarbon..");
            }
            if (num >= 496 && num <= 989) {
                totalCloverYardPearlMinted++;
                uri = string(abi.encodePacked(_baseURIYardPearl, Strings.toString(totalCloverYardPearlMinted)));
                require(IContract(DarkSeedController).addAsCloverYardPearl(tokenId), "Clover_Seeds_Picker: Unable to call addAsCloverYardPearl..");
            }
            if (num >= 990 && num <= 999) {
                totalCloverYardRubyMinted++;
                uri = string(abi.encodePacked(_baseURIYardRuby, Strings.toString(totalCloverYardRubyMinted)));
                require(IContract(DarkSeedController).addAsCloverYardRuby(tokenId), "Clover_Seeds_Picker: Unable to call addAsCloverYardRuby..");
            }

            IContract(DarkSeedNFT).setTokenURI(tokenId, uri);

        } else {
            if (totalCloverPotDiamondMinted == totalCloverPotDiamond) {
                num = num % 998 + 2;
            }
            if (totalCloverPotCarbonMinted == totalCloverPotCarbon) {
                num = num % 506;
                if (num >= 2 && num <= 495) {
                    num += 504;
                }
            }
            if (totalCloverPotPearlMinted == totalCloverPotPearl) {
                num = num % 506;
                if (num >= 496 && num <= 505) {
                    num += 494;
                }
            }
            if (totalCloverPotRubyMinted == totalCloverPotRuby) {
                num = num % 990;
            }

            string memory uri;
            if (num >= 0 && num <= 1) {
                totalCloverPotDiamondMinted++;
                uri = string(abi.encodePacked(_baseURIPotDiamond, Strings.toString(totalCloverPotDiamondMinted)));
                require(IContract(DarkSeedController).addAsCloverPotDiamond(tokenId), "Clover_Seeds_Picker: Unable to call addAsCloverPotDiamond..");
            }
            if (num >= 2 && num <= 495) {
                totalCloverPotCarbonMinted++;
                uri = string(abi.encodePacked(_baseURIPotCarbon, Strings.toString(totalCloverPotCarbonMinted)));
                require(IContract(DarkSeedController).addAsCloverPotCarbon(tokenId), "Clover_Seeds_Picker: Unable to call addAsCloverPotCarbon..");
            }
            if (num >= 496 && num <= 989) {
                totalCloverPotPearlMinted++;
                uri = string(abi.encodePacked(_baseURIPotPearl, Strings.toString(totalCloverPotPearlMinted)));
                require(IContract(DarkSeedController).addAsCloverPotPearl(tokenId), "Clover_Seeds_Picker: Unable to call addAsCloverPotPearl..");
            }
            if (num >= 990 && num <= 999) {
                totalCloverPotRubyMinted++;
                uri = string(abi.encodePacked(_baseURIPotRuby, Strings.toString(totalCloverPotRubyMinted)));
                require(IContract(DarkSeedController).addAsCloverPotRuby(tokenId), "Clover_Seeds_Picker: Unable to call addAsCloverPotRuby..");
            }
            IContract(DarkSeedNFT).setTokenURI(tokenId, uri);
        }
        return true;
    }
    
    // function to allow admin to transfer *any* BEP20 tokens from this contract..
    function transferAnyBEP20Tokens(address tokenAddress, address recipient, uint256 amount) public onlyOwner {
        require(amount > 0, "SEED$ Picker: amount must be greater than 0");
        require(recipient != address(0), "SEED$ Picker: recipient is the zero address");
        IContract(tokenAddress).transfer(recipient, amount);
    }
}