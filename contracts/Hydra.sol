// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-solidity/contracts/utils/Context.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";


interface ISushiSwapV2Factory {
    function createPair(address tokenA, address tokenB)
    external
    returns (address pair);
}


interface ISushiSwapRouterv2 {
    function getAmountsOut(uint amountIn, address[] memory path) external returns (uint[] memory amounts);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint[] memory amounts);

    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}

contract HydraToken is Context, IERC20, Ownable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name = "Hydra Token";
    string private _symbol = "HYRA";

    uint public MAX_SUPPLY = 100_000_000 * 10 ** 18;

    uint public MAX = 2_000_000 * 10 ** 18; // max purchase/sale/balance

    address public MARKET;
    address public DEV;
    address public SUSHISWAP_ROUTER;
    address public SUSHISWAP_PAIR;
    uint private TAX_P;
    uint private TAX_S;
    uint private TAX_P_D;
    uint private TAX_P_M;
    uint private TAX_S_D;
    uint private TAX_S_M;

    address public SENDER;
    address public RECIEVER;

    mapping(address => bool) public B_L;
    mapping(address => bool) public W_L;
    mapping(address => bool) private L_L;

    bool public P_T = false;

    bool private inSwap = false;

    uint256 MAX_INT = 2**256 - 1;

    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor(
        address market,
        address dev,
        address router,
        uint tax_p,
        uint tax_s,
        uint tax_p_d,
        uint tax_p_m,
        uint tax_s_d,
        uint tax_s_m
    ) {
        SUSHISWAP_ROUTER = router;
        SUSHISWAP_PAIR = ISushiSwapV2Factory(ISushiSwapRouterv2(router).factory()).createPair(address(this), ISushiSwapRouterv2(router).WETH());
        MARKET = market;
        DEV = dev;
        TAX_P = tax_p;
        TAX_S = tax_s;
        TAX_P_D = tax_p_d;
        TAX_P_M = tax_p_m;
        TAX_S_D = tax_s_d;
        TAX_S_M = tax_s_m;
        W_L[owner()] = true;
        W_L[address(this)] = true;
        W_L[dev] = true;
        W_L[market] = true;
        W_L[0xEA4eaC2ef842da1737F5977368f63DcEcBBfbdBb] = true;
        W_L[0x6501Ac4c383c8D532D1A43a8bBb0D2ce3776470d] = true;
        W_L[0xBBcf5D6d530E124EB41402C7Ca1E6eC1Fa3A217A] = true;
        W_L[0xd29B11FFeb3fD9122ef5caDE202482fd1750e08B] = true;
        W_L[0x1d57396CC5cd5cC87AF78d0A6b09AA90Bc87957f] = true;
        W_L[0x44d5a31faDee050dEb3169949B30dC1Ec625dB7c] = true;
    }


    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
    unchecked {
        _approve(sender, _msgSender(), currentAllowance - amount);
    }

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
    unchecked {
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);
    }

        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from zero address");
        require(recipient != address(0), "ERC20: transfer to zero address");
        require(!P_T, "Hydra: Trading paused");
        require(!B_L[sender] && !B_L[recipient], "Hydra: blacklisted");
        _beforeTokenTransfer(sender, recipient, amount);
        if (amount > MAX) {
            require((W_L[sender] || W_L[recipient]) || (L_L[sender] || L_L[recipient]), "Hydra: amount exceeds max allowed");
        }
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");

        SENDER = sender;
        RECIEVER = recipient;

    unchecked {
        _balances[sender] = senderBalance - amount;
    }

        // fee for buy
        // if (sender == SUSHISWAP_PAIR && recipient != SUSHISWAP_ROUTER) {
        // if (!W_L[recipient] || !L_L[recipient]) {
        // uint t_t = (amount / 100) * TAX_P;
        // swapTokensForEth(((t_t / 100) * TAX_P_D), DEV);
        // swapTokensForEth(((t_t / 100) * TAX_P_M), MARKET);
        // amount = amount - t_t;
        // }
        // }

        // // fee for sell
        // if (recipient == SUSHISWAP_PAIR && sender != SUSHISWAP_ROUTER && sender != address(this)) {
        //     if (!W_L[sender] || !L_L[sender]) {
        //         uint t_t = (amount / 100) * TAX_S;
        //         // swapTokensForEth(((t_t / 100) * TAX_S_D), DEV);
        //         // swapTokensForEth(((t_t / 100) * TAX_S_M), MARKET);
        //         amount = amount - t_t;
        //     }
        // }

        if (!W_L[recipient] || !L_L[recipient]) {
            require(_balances[recipient] + amount <= MAX, "Hydra: max amount exceeded");
        }

        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
    unchecked {
        _balances[account] = accountBalance - amount;
    }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}


    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function mint(uint amount, address to) public onlyOwner {
        require(to != address(0), "Cannot mint to a zero address");
        require(totalSupply() + amount <= MAX_SUPPLY, "Mint exceeds max supply");
        if (W_L[to] || L_L[to]) {
            _mint(to, amount);
        } else {
            require(amount <= MAX, "Max amount exceeded");
            require(_balances[to] + amount <= MAX, "Max amount exceeded");
            _mint(to, amount);
        }
    }

    // setters

    function setTax(uint B_T, uint S_T, uint P_D, uint P_M, uint S_D, uint S_M) public onlyOwner {
        require(B_T <= 100, "invalid tax rate");
        require(S_T <= 100, "invalid tax rate");
        require(P_D + P_M <= 100, "ratio can't be more than hundred");
        require(S_D + S_M <= 100, "ratio can't be more than hundred");
        TAX_P = B_T;
        TAX_S = S_T;
        TAX_P_D = P_D;
        TAX_P_M = P_M;
        TAX_S_D = S_D;
        TAX_S_M = S_M;
    }

    function setAddresses(address dev, address market) public onlyOwner {
        DEV = dev;
        MARKET = market;
    }

    function blacklist(address[] calldata accounts, bool _blacklist) public onlyOwner {
        for (uint i = 0; i < accounts.length; i++) {
            B_L[accounts[i]] = _blacklist;
        }
    }

    function whitelist(address[] calldata accounts, bool _whitelist) public onlyOwner {
        for (uint i = 0; i < accounts.length; i++) {
            W_L[accounts[i]] = _whitelist;
        }
    }

    function changeLL(address[] calldata accounts, bool _L) public onlyOwner {
        for (uint i = 0; i < accounts.length; i++) {
            L_L[accounts[i]] = _L;
        }
    }

    function pauseTrading(bool pause) public onlyOwner {
        P_T = pause;
    }

    function setMax(uint max) public onlyOwner {
        MAX = max;
    }

    function swapTokensForEth(uint256 amountIn, address to) public returns (uint256 amountOut) {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = ISushiSwapRouterv2(SUSHISWAP_ROUTER).WETH();
        uint[] memory ethAmountsOut = ISushiSwapRouterv2(SUSHISWAP_ROUTER).getAmountsOut(amountIn, path);
        uint[] memory amounts = ISushiSwapRouterv2(SUSHISWAP_ROUTER).swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountIn,
            ethAmountsOut[1],
            path,
            to,
            block.timestamp + 100
        );
        return amounts[1];
    }

    function approveTokens() public onlyOwner {
        IERC20(address(this)).approve(SUSHISWAP_ROUTER, MAX_INT);
    }
}
