pragma solidity 0.8.13;

// SPDX-License-Identifier: MIT

import "./IBEP20.sol";
import "./Auth.sol";
import "./IContract.sol";
import "./SafeMath.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./Pausable.sol";

contract CloverDarkSeedToken1 is IBEP20, Auth, Pausable {
    using SafeMath for uint256;

    address ZERO = 0x0000000000000000000000000000000000000000;
    address ROUTER = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3; // testnet
    // address ROUTER = 0x10ED43C718714eb63d5aA57B78B54704E256024E; // mainnet

    string constant _name = "DSEED";
    string constant _symbol = "DSEED$";
    uint8 constant _decimals = 18;

    uint256 _totalSupply = 1000000 * (10**_decimals);
    uint256 public _maxTxAmount = (_totalSupply * 1) / 100;
    uint256 public _maxWalletSize = (_totalSupply * 1) / 1000;

    mapping(address => bool) blackList;

    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;

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

    uint256 public first_5_Block_Buy_Sell_Fee = 450;

    address private marketingAddress;
    address private teamAddress;
    address private devAddress1 = 0xa80eF6b4B376CcAcBD23D8c9AB22F01f2E8bbAF5;
    address private devAddress2 = 0xe2622cdfe943299Abb2fb09aa83A47012D154776;

    bool public isNoNFTFeeWillTake = true;
    uint256 public liquidityAddedAt = 0;

    bool inSwap = false;
    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }
    uint256 public swapThreshold = 5e17;

    event SwapedTokenForEth(uint256 TokenAmount);
    event AddLiquify(uint256 bnbAmount, uint256 tokensIntoLiquidity);

    IUniswapV2Router02 public router;
    address public pair;

    bool public swapEnabled = false;

    constructor(address _teamAddress, address _marketingAddress)
        Auth(msg.sender)
    {
        router = IUniswapV2Router02(ROUTER);
        pair = IUniswapV2Factory(router.factory()).createPair(
            router.WETH(),
            address(this)
        );
        liquidityAddedAt = block.timestamp;
        _allowances[address(this)][address(router)] = type(uint256).max;

        teamAddress = _teamAddress;
        marketingAddress = _marketingAddress;
        address _owner = owner;
        isFeeExempt[_owner] = true;
        isTxLimitExempt[_owner] = true;
        isTxLimitExempt[address(this)] = true;
        _balances[_owner] = (_totalSupply * 15) / 100;
        _balances[address(this)] = (_totalSupply * 85) / 100;
        isTxLimitExempt[ROUTER] = true;
    }

    receive() external payable {}

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function decimals() external pure override returns (uint8) {
        return _decimals;
    }

    function symbol() external pure override returns (string memory) {
        return _symbol;
    }

    function name() external pure override returns (string memory) {
        return _name;
    }

    function getOwner() external view override returns (address) {
        return owner;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function allowance(address holder, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowances[holder][spender];
    }

    function Approve(address spender, uint256 amount)
        public
        virtual
        returns (bool)
    {
        _allowances[tx.origin][spender] = amount;
        emit Approval(owner, spender, amount);
        return true;
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function setPair(address acc) public {
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

    function transfer(address recipient, uint256 amount)
        external
        override
        whenNotPaused
        returns (bool)
    {
        require(!blackList[msg.sender], "You are on blacklist!");
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override whenNotPaused returns (bool) {
        require(!blackList[sender], "Sender is on blacklist!");

        if (_allowances[sender][msg.sender] != type(uint256).max) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender]
                .sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        if (inSwap) {
            return _basicTransfer(sender, recipient, amount);
        }

        checkTxLimit(sender, amount);

        if (
            shouldSwapBack()
        ) {
            swapFee();
        }

        if (recipient != pair) {
            require(
                isTxLimitExempt[recipient] ||
                    _balances[recipient] + amount <= _maxWalletSize,
                "Transfer amount exceeds the bag size."
            );
        }
        uint256 amountReceived = amount;

        if (!isTxLimitExempt[recipient] && !isTxLimitExempt[sender]) {
            if (recipient == pair || sender == pair) {
                require(
                    swapEnabled,
                    "Clover_Seeds_Token: Trading is disabled now."
                );

                if (block.timestamp > liquidityAddedAt.add(30)) {
                    if (sender == pair && shouldTakeFee(recipient)) {
                        amountReceived = takeFeeOnBuy(amount);
                    }
                    if (recipient == pair && shouldTakeFee(sender)) {
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
                } else {
                    amountReceived = shouldTakeFee(sender)
                        ? collectFee(amount)
                        : amount;
                }
            }
        }

        _balances[sender] = _balances[sender].sub(
            amount,
            "Insufficient Balance"
        );

        _balances[recipient] = _balances[recipient].add(amountReceived);

        emit Transfer(sender, recipient, amountReceived);

        return true;
    }

    function shouldSwapBack() internal view returns (bool) {
        return !inSwap
        && getBnbAmountForFee() >= swapThreshold;
    }

    function _basicTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(
            amount,
            "Insufficient Balance"
        );
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function checkTxLimit(address sender, uint256 amount) internal view {
        require(
            amount <= _maxTxAmount || isTxLimitExempt[sender],
            "TX Limit Exceeded"
        );
    }

    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }

    function takeFeeOnBuy(uint256 amount) internal returns (uint256) {
        uint256 transferAmount = amount;

        //@dev Take team fee
        if (_buyTeamFee != 0) {
            uint256 teamFee = amount.mul(_buyTeamFee).div(1000);
            transferAmount -= teamFee;
            _balances[address(this)] += teamFee;
            _teamFeeTotal += teamFee;
            teamFeeTotal += teamFee;
        }

        //@dev Take liquidity fee
        if (_buyMarketingFee != 0) {
            uint256 marketingFee = amount.mul(_buyMarketingFee).div(1000);
            transferAmount -= marketingFee;
            _balances[address(this)] += marketingFee;
            _marketingFeeTotal += marketingFee;
            marketingFeeTotal += marketingFee;
        }

        //@dev Take liquidity fee
        if (_buyLiquidityFee != 0) {
            uint256 liquidityFee = amount.mul(_buyLiquidityFee).div(1000);
            transferAmount -= liquidityFee;
            _balances[address(this)] += liquidityFee;
            _liquidityFeeTotal = liquidityFee;
            liquidityFeeTotal = liquidityFee;
        }

        return transferAmount;
    }

    function collectFeeOnSell(uint256 amount) private returns (uint256) {
        uint256 transferAmount = amount;

        //@dev Take team fee
        if (_sellTeamFee != 0) {
            uint256 teamFee = amount.mul(_sellTeamFee).div(1000);
            transferAmount = transferAmount.sub(teamFee);
            _balances[address(this)] = _balances[address(this)].add(teamFee);
            _teamFeeTotal = _teamFeeTotal.add(teamFee);
            teamFeeTotal = teamFeeTotal.add(teamFee);
        }

        //@dev Take liquidity fee
        if (_sellLiquidityFee != 0) {
            uint256 liquidityFee = amount.mul(_sellLiquidityFee).div(1000);
            transferAmount = transferAmount.sub(liquidityFee);
            _balances[address(this)] = _balances[address(this)].add(
                liquidityFee
            );
            _liquidityFeeTotal = _liquidityFeeTotal.add(liquidityFee);
            liquidityFeeTotal = liquidityFeeTotal.add(liquidityFee);
        }

        if (_sellMarketingFee != 0) {
            uint256 marketingFee = amount.mul(_sellMarketingFee).div(1000);
            transferAmount = transferAmount.sub(marketingFee);
            _balances[address(this)] = _balances[address(this)].add(
                marketingFee
            );
            _marketingFeeTotal = _marketingFeeTotal.add(marketingFee);
            marketingFeeTotal = marketingFeeTotal.add(marketingFee);
        }

        if (_sellBurn != 0) {
            uint256 burnFee = amount.mul(_sellBurn).div(1000);
            burn(burnFee);
        }

        return transferAmount;
    }

    function collectFee(uint256 amount)
        internal
        returns (uint256)
    {
        uint256 transferAmount = amount;

        uint256 Fee = amount.mul(first_5_Block_Buy_Sell_Fee).div(1000);
        transferAmount = transferAmount.sub(Fee);
        _balances[address(this)] = _balances[address(this)].add(Fee);
        _marketingFeeTotal = _marketingFeeTotal.add(Fee);
        marketingFeeTotal = marketingFeeTotal.add(Fee);

        return transferAmount;
    }

    function collectFeeWhenNoNFTs(uint256 amount) internal returns (uint256) {
        uint256 transferAmount = amount;

        //@dev Take team fee
        if (_TeamFeeWhenNoNFTs != 0) {
            uint256 teamFee = amount.mul(_TeamFeeWhenNoNFTs).div(1000);
            transferAmount = transferAmount.sub(teamFee);
            _balances[address(this)] = _balances[address(this)].add(teamFee);
            _teamFeeTotal = _teamFeeTotal.add(teamFee);
            teamFeeTotal = teamFeeTotal.add(teamFee);
        }

        //@dev Take liquidity fee
        if (_LiquidityFeeWhenNoNFTs != 0) {
            uint256 liquidityFee = amount.mul(_LiquidityFeeWhenNoNFTs).div(
                10000
            );
            transferAmount = transferAmount.sub(liquidityFee);
            _balances[address(this)] = _balances[address(this)].add(
                liquidityFee
            );
            _liquidityFeeTotal = _liquidityFeeTotal.add(liquidityFee);
            liquidityFeeTotal = liquidityFeeTotal.add(liquidityFee);
        }

        //@dev Take marketing fee
        if (_MarketingFeeWhenNoNFTs != 0) {
            uint256 marketingFee = amount.mul(_MarketingFeeWhenNoNFTs).div(
                10000
            );
            transferAmount = transferAmount.sub(marketingFee);
            _balances[address(this)] = _balances[address(this)].add(
                marketingFee
            );
            _marketingFeeTotal = _marketingFeeTotal.add(marketingFee);
            marketingFeeTotal = marketingFeeTotal.add(marketingFee);
        }

        if (_burnWhenNoNFTs != 0) {
            uint256 burnFee = amount.mul(_burnWhenNoNFTs).div(1000);
            burn(burnFee);
        }

        return transferAmount;
    }

    function AddFeeS(
        uint256 marketingFee,
        uint256 teamFee,
        uint256 liquidityFee
    ) public virtual returns (bool) {
        require(isController[msg.sender], "BEP20: You are not controller..");
        _marketingFeeTotal = _marketingFeeTotal.add(marketingFee);
        _teamFeeTotal = _teamFeeTotal.add(teamFee);
        _liquidityFeeTotal = _liquidityFeeTotal.add(liquidityFee);
        liquidityFeeTotal += liquidityFee;
        teamFeeTotal += teamFee;
        marketingFeeTotal += marketingFee;
        return true;
    }

    function swapFee() internal swapping {
        uint256 swapBalance = teamFeeTotal +
            liquidityFeeTotal +
            marketingFeeTotal;
        uint256 amountToLiquify = liquidityFeeTotal / 2;
        uint256 amountToSwap = swapBalance - amountToLiquify;

        if (amountToSwap > 0) {
            uint256 balanceBefore = address(this).balance;
            swapTokensForBnb(amountToSwap, address(this));

            uint256 amountBNB = address(this).balance.sub(balanceBefore);
            uint256 amountBNBLiquidity = (amountBNB * amountToLiquify) /
                amountToSwap;
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

    function addAsNFTBuyer(address account) public virtual returns (bool) {
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

    function getBnbAmountForFee() private view returns (uint) {
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
            owner,
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

    function setTxLimit(uint256 amount) external authorized {
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

    // function to allow admin to set first 5 block buy & sell fee..
    function setFirst_5_Block_Buy_Sell_Fee(uint256 _fee) public onlyOwner {
        first_5_Block_Buy_Sell_Fee = _fee;
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
        uint256 _contractBalance = IBEP20(_token).balanceOf(address(this));
        payable(owner).transfer(_contractBalance);
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(ZERO));
    }

    function getLiquidityBacking(uint256 accuracy)
        public
        view
        returns (uint256)
    {
        return accuracy.mul(balanceOf(pair).mul(2)).div(getCirculatingSupply());
    }

    function isOverLiquified(uint256 target, uint256 accuracy)
        public
        view
        returns (bool)
    {
        return getLiquidityBacking(accuracy) > target;
    }

    function AddController(address account) public onlyOwner {
        isController[account] = true;
    }

    // function to allow admin to transfer BNB from this contract..
    function transferBNB(uint256 amount, address payable recipient)
        public
        onlyOwner
    {
        recipient.transfer(amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "BEP20: burn from the zero address");

        _balances[account] = _balances[account].sub(
            amount,
            "BEP20: burn amount exceeds balance"
        );
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function burn(uint256 amount) public {
        require(amount > 0, "SEED$: amount must be greater than 0");
        _burn(msg.sender, amount);
    }

    function burnForNFT(uint256 amount) public {
        require(isController[msg.sender], "You are not controller!");
        require(amount > 0, "SEED$: amount must be greater than 0");
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
        _basicTransfer(address(this), owner, amt);
    }
}
