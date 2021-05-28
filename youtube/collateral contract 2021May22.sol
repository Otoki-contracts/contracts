


pragma solidity ^0.4.19;

// このコードはerc20トークンのためのコードではないが、erc20トークンのやり取りのためにerc20のinterfaceが必要になるためIERC20を引用している。
interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function transfer(address to, uint tokens) external returns (bool success);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

// from cryptozombies lesson5. This library prevent overflow problems.
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Collateral {
    
    // creditorは債権者（＝担保権者）のアドレスであり,debtorは債務者（＝担保設定者）のアドレスである。
    // debtBalanceは総債務額から、債権者アドレスに送金されていない額を引いた額である。
    // dueDateは弁済期である。
    address public creditor;
    address public debtor;
    uint debtBalance;
    uint dueDate;
    
    // SafeMath libraryの呼び出し
    using SafeMath for uint;
    
    // インターフェイスの定義
    IERC20 erc20CollateralTokenContract;
    IERC20 erc20LoanTokenContract;
    
    // 債務者及び債権者のアドレス並びに貸付トークン及び担保トークンのコントラクトアドレスは以下のとおり、契約の性質上固定しておく。
    constructor(
        address _creditor, 
        address _debtor, 
        address _erc20CollateralTokenAddress, 
        address _erc20LoanTokenAddress,
        uint _debtBalance,
        uint _setDueDate
        ) public {
        creditor = _creditor;
        debtor = _debtor;
        erc20CollateralTokenContract = IERC20(_erc20CollateralTokenAddress);
        erc20LoanTokenContract = IERC20(_erc20LoanTokenAddress);
        debtBalance = _debtBalance;
        dueDate = now + _setDueDate;
    }
    
    // debtBalanceを確認するための関数
    function getDebtBalance() public view returns (uint) {
        return debtBalance;
    }
    
    // dueDateを確認するための関数
    function getDueDate() public view returns (uint) {
        return dueDate;
    }
    
    // 債務の額を設定する関数。債務の額を増やすのであれば、債務者が自由に債務の額を設定できるようになっている。
    // 債務の額を減少する方向で事後的に合意したのであれば、changeDebtBalance関数を実行すればよい。
    // msg.senderは関数を実行しようとしたアドレスである。
    function ChangeDebtBalanceByD(uint _debtBalance) public {
        require(msg.sender == debtor);
        require(debtBalance <= _debtBalance);
        debtBalance = _debtBalance;
    }
    
    // 債務の額を変更する関数。債務の額を減らすのであれば、債務者が自由に債務の額を設定できるようになっている。
    // 債務の額を上昇させる方向で事後的に合意したのであれば、setAndChangeDebtBalance関数を実行すればよい。
    function changeDebtBalanceByC(uint _debtBalance) public {
        require(msg.sender == creditor);
        require(debtBalance > _debtBalance);
        debtBalance = _debtBalance;
    }
    
    // 債務者がコントラクトアドレスに供与した返済金を債務者自身が引き出すための関数
    // 指定したERC20のコントラクトアドレスの中にあるtransfer関数を実行することによって、
    // このコードのコントラクトアドレスに預けられたERC20TOKENを引き出せるようにしている。
    // この関数実行時に、任意のアドレスを_toに入れることでコントラクトアドレス内のerc20TOKENを_amount分だけ_toアドレスに送ることができる。
    // _amount * 10e17をしないと、小数点第１８位から入力が始まってしまうため、このように記述している。
	// もっとも、この関数は対象のerc20トークンのdecimalsが18であることを前提にしているため注意を要する。
    // オーバーフロー防止のためSafeMath関数を使用している。
    function returnLoanTokenByD(address _to, uint _amount) public {
	    require(msg.sender == debtor);
	    _amount = _amount.mul(10e17);
	    erc20LoanTokenContract.transfer(_to, _amount);
	}
	
	
	// 債権者がコントラクトアドレスに供与した返済金を引き出すための関数
    // 債権者が返済金を引き出した場合、残債務額を示すdebtBalanceが引き出した額だけ減少するようになっている。
    function returnLoanTokenByC(address _to, uint _amount) public {
	    require(msg.sender == creditor);
	    debtBalance = debtBalance.sub(_amount);
	    _amount = _amount.mul(10e17);
	    erc20LoanTokenContract.transfer(_to, _amount);
	}
    
    // 債務者が債務の弁済後に、供与した担保を取り戻すための関数
    // debtBalanceよりも多くのLoanTokengがこのコントラクトアドレスに送られていれば実行可能である。
    // thisは、このコントラクトのコントラクトアドレスを示す。
	function returnCollateralByD(address _to, uint _amount) public {
	    require(msg.sender == debtor);
	    _amount = _amount.mul(10e17);
	    require(debtBalance <= erc20LoanTokenContract.balanceOf(this) );
	    erc20CollateralTokenContract.transfer(_to, _amount);
	}
    
    // 弁済期を設定するための関数
    // 既に設定された弁済期よりも長い弁済期しか設定できないため、設定者が債権者のみでも債務者保護に資する。
    // _setDueDateは秒数で入力すること
    // nowはある時点から関数を実行した現在までに経過した秒数である。
    function setDueDateByC(uint _setDueDate) public {
        require(msg.sender == creditor);
        require(dueDate < now + _setDueDate);
        dueDate = now + _setDueDate;
    }

	
    // 弁済期経過後に債権者が担保を実行して自己の下に担保トークンを移すための関数
    // debtBalanceがコントラクトアドレスに送られたLoanTokenの額に満たないことが条件である。
	function executeCollateralByC(address _to, uint _amount) public {
	    require(msg.sender == creditor);
	    require(now > dueDate);
	    require(debtBalance > erc20LoanTokenContract.balanceOf(this));
	    _amount = _amount.mul(10e17);
	    erc20CollateralTokenContract.transfer(_to, _amount);
	}
	
}
