// SPDX-License-Identifier: MIT
// ↑これは割と大事らしい

pragma solidity ^0.8.0;

// https://www.youtube.com/watch?v=GDq7r1n9zIU&t=934s　左の解説動画にerc20の作成方法が載っている。
// 下記のcodeはこの解説動画で使用されているものをベースにしてある。なお、ベースのコードは^0.5.0である。

// contract ERC20Interfaceではなく、interface ERC20Interfaceにしたらうまくいった。
// ちなみにinterface内でpublicは使えないため、externalに直す必要があった。
// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// ----------------------------------------------------------------------------
interface ERC20Interface {
    function totalSupply() external view returns (uint);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function transfer(address to, uint tokens) external returns (bool success);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

// ----------------------------------------------------------------------------
// Safe Math Library
// ----------------------------------------------------------------------------
contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a); c = a - b; } function safeMul(uint a, uint b) public pure returns (uint c) { c = a * b; require(a == 0 || c / a == b); } function safeDiv(uint a, uint b) public pure returns (uint c) { require(b > 0);
        c = a / b;
    }
}

// ----------------------------------------------------------------------------
// デプロイにあたっては、JavaScriptVMではなく、Injected Web3を選択する必要がある。
// しかしながら、ダウンロードしたRemix IDEではなぜかmetamaskに接続できない。
// そこで、ブラウザ版(Crome)のRemixからデプロイするとうまくいく。
// そのとき、ブラウザ版のRemixが[http]ではなく、[https]から始まっていることを確認する必要がある。
// httpsじゃないとうまく動かない時があるらしい。

// 下記のコントラクトがトークン発行のために重要である。
// コンパイルをクリアしたとしても、デプロイの段階で下記のコントラクトを選択する必要がある。
// ちなみにコントラクトの選択は[deploy]ボタンの真上にある。

// これはよくわからないが、デプロイするときに、[VALUE]の欄をいじるとエラーが生じる。
// gas stationより高い数字を入れたくなる気持ちはわかるが、[VALUE]の欄は0 weiのままにしておこう。
// ----------------------------------------------------------------------------

contract OTOKITOKEN is ERC20Interface, SafeMath {
    string public name;
    string public symbol;
    uint8 public decimals; // 18 decimals is the strongly suggested default, avoid changing it

    uint256 public _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor() {
        name = "CodeWithJoe";
        symbol = "OTK";
        decimals = 18;
        _totalSupply = 1000000000000000000000000000;

        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function totalSupply() public view virtual override returns (uint) {
        return _totalSupply  - balances[address(0)];
    }

    function balanceOf(address tokenOwner) public view virtual override returns (uint balance) {
        return balances[tokenOwner];
    }

    function allowance(address tokenOwner, address spender) public view virtual override returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    function approve(address spender, uint tokens) public virtual override returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transfer(address to, uint tokens) public virtual override returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public virtual override returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
}
