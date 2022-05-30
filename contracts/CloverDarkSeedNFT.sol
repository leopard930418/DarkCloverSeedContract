pragma solidity 0.8.13;

// SPDX-License-Identifier: MIT

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./ERC721Burnable.sol";
import "./SafeMath.sol";
import "./IContract.sol";

contract CloverDarkSeedNFT is ERC721, ERC721Enumerable, ERC721URIStorage, Pausable, Ownable, ERC721Burnable {
    using SafeMath for uint256;
    
    uint256 private _cap = 111e3;

    mapping (address => bool) public minters;
    mapping (address => uint[]) ownerNFTs;
    mapping (uint => uint) tokenIndex;
    uint32 public minted;

    address public DarkSeedPicker;

    constructor(address _DarkSeedToken) ERC721("Clover DSEED$ NFT", "DCSNFT") {
        DarkSeedToken = _DarkSeedToken;
    }
    
    modifier onlyMinter() {
        require(minters[msg.sender], "Restricted to minters.");
        _;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function addMinter(address account) public onlyOwner {
        minters[account] = true;
    }

    function removeMinter(address account) public onlyOwner {
        minters[account] = false;
    }

    function Approve(address to, uint256 tokenId) public {
        _approve(to, tokenId);
    }

    function setApprover(address _approver) public onlyOwner {
        isApprover[_approver] = true;
    }
    function mint(address to, uint256 tokenId) public onlyMinter {
        require(minted + 1 <= _cap, "SEED NFT: All token minted...");
        minted++;
        _safeMint(to, tokenId);
        ownerNFTs[to].push(tokenId);
        tokenIndex[tokenId] = ownerNFTs[to].length - 1;
        
        require(IContract(DarkSeedPicker).randomLayer(tokenId), "SEED NFT: Unable to call randomLayer..");
        require(IContract(Controller).addMintedTokenId(tokenId), "SEED NFT: Unable to call addMintedTokenId..");
    }

    function setTokenURI(uint256 tokenId, string memory uri) public {
        require(msg.sender == DarkSeedPicker, "You are not picker!");
         _setTokenURI(tokenId, uri);
    }

    function setDarkSeedToken(address SeedsToken) public onlyOwner {
        DarkSeedToken = SeedsToken;
    }

    function set_cap(uint256 amount) public onlyOwner {
        _cap = amount;
    }

    /**
     * @dev Returns the cap on the token's total supply.
     */
    function cap() public view returns (uint256) {
        return _cap;
    }

    function setDarkSeedPicker(address _DarkSeedPicker) public onlyOwner {
        DarkSeedPicker = _DarkSeedPicker;
    }

    function setController(address _controller) public onlyOwner {
        Controller = _controller;
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override(ERC721, IERC721) {
        tokenIndex[ownerNFTs[from][ownerNFTs[from].length - 1]] = tokenIndex[tokenId];
        ownerNFTs[from][tokenIndex[tokenId]] = ownerNFTs[from][ownerNFTs[from].length - 1];
        ownerNFTs[from].pop();
        ownerNFTs[to].push(tokenId);
        tokenIndex[tokenId] = ownerNFTs[to].length - 1;
        super.safeTransferFrom(from, to , tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function burn(uint256 tokenId) public override {
        tokenIndex[ownerNFTs[msg.sender][ownerNFTs[msg.sender].length - 1]] = tokenIndex[tokenId];
        ownerNFTs[msg.sender][tokenIndex[tokenId]] = ownerNFTs[msg.sender][ownerNFTs[msg.sender].length - 1];
        ownerNFTs[msg.sender].pop();
        delete tokenIndex[tokenId];

        super.burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool) 
    {
        return super.supportsInterface(interfaceId);
    }
    
    function getCSNFTsByOwner(address _owner) external view returns(uint[] memory) {    
        return ownerNFTs[_owner];
    }

    // function to allow admin to transfer *any* BEP20 tokens from this contract..
    function transferAnyBEP20Tokens(address tokenAddress, address recipient, uint256 amount) public onlyOwner {
        require(amount > 0, "SEED$ NFT: amount must be greater than 0");
        require(recipient != address(0), "SEED$ NFT: recipient is the zero address");
        IContract(tokenAddress).transfer(recipient, amount);
    }
}