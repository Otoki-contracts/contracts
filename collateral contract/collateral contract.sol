pragma solidity ^0.4.19;

import "./IERC20.sol";

contract Collateral is IERC20 {
    
    // 上から順にmetamask4,metamask1のアドレスを挿入した。
    // debtFulfillmentは債務の履行が完了したことを示すもので、dueDateは弁済期を示す。
    address public creditor;
    address public debtor;
    uint debtBalance;
    uint repayedBalance;
    uint debtFulfillment;
    uint dueDate;
    
    constructor() public {
        creditor = 0xC960804664D3fAdDcD037240BFD55A2e1F197503;
        debtor = 0xC12392Ae41E31Ea352acB2E5Fd88B1eFF0325c1f;
    }
    
    // インターフェイスの挿入
    IERC20 erc20CollateralTokenContract;
    IERC20 erc20LoanTokenContract;
    
    // やりとりしたいerc20担保トークンのコントラクトアドレスを代入するための関数
    function setErc20CollateralTokenContractAddress(address _erc20ContractAddress) public {
        erc20CollateralTokenContract = IERC20(_erc20ContractAddress);
    }
    
    // やりとりしたいerc20貸付金トークン(USDTなど）のコントラクトアドレスを代入するための関数
    function setErc20LoanTokenContractAddress(address _erc20ContractAddress) public {
        erc20LoanTokenContract = IERC20(_erc20ContractAddress);
    }
    
    // 債務の額を設定する関数。債務の額を増やすのであれば、債務者が自由に債務の額を設定できるようになっている。
    // 債務の額を減少する方向で事後的に合意したのであれば、コードを再デプロイするべし。
    function setAndChangeDebtBalance(uint _debtBalance) public {
        require(msg.sender == debtor);
        require(debtBalance <= _debtBalance);
        debtBalance = _debtBalance;
    }
    
    // 債務の額を変更する関数。債務の額を減らすのであれば、債務者が自由に債務の額を設定できるようになっている。
    // 債務の額を減少する方向で事後的に合意したのであれば、コードを再デプロイするべし。
    function ChangeDebtBalance(uint _debtBalance) public {
        require(msg.sender == creditor);
        require(debtBalance > _debtBalance);
        debtBalance = _debtBalance;
    }
    
    // 債務者がコントラクトアドレスに供与した返済金を債務者自身が引き出すための関数
    function returnLoanTokenToDebtor(address _to, uint _amount) public {
	    //この関数を呼び出したアカウントに返済金が移される。
	   // 担保設定者のみ実行可能
	   // 債務の履行後にのみ実行可能
	    require(msg.sender == debtor);
	    erc20LoanTokenContract.transfer(_to, _amount);
	}
	
	// 債権者がコントラクトアドレスに供与した返済金を引き出すための関数
    function returnLoanTokenToCreditor(address _to, uint _amount) public {
	    //この関数を呼び出したアカウントに返済金が移される。
	   // 担保設定者のみ実行可能
	   // 債務の履行後にのみ実行可能
	    require(msg.sender == creditor);
	    debtBalance -= _amount;
	    erc20LoanTokenContract.transfer(_to, _amount);
	}
    
    // 指定したERC20のコントラクトアドレスの中にあるtransfer関数を実行することによって、
    // このコードのコントラクトアドレスに入り込んだERC20TOKENを引き出せるようにしている。
    // withdrawToOwner関数実行時に、任意のアドレスを_toに入れることでコントラクトアドレス内のerc20TOKENを_toアドレスに送ることができる。
    // _amountは小数点第18まで検討する必要がありうる点に注意が必要である。
    // 実装にあたっては、decimalが１８であることを確認するようなコードを書き込むと良いかもしれない。
    // 本当は、 require(debtBalance = 0);にすべきなんだけど、端数が紛れるとめんどくさいからとりあえず< 1にしている。
    // 仮に債権者がこのコードのコントラクトアドレス内から返済金を引き出さなくても、
    // このコントラクトアドレス内に送られた返済額が、残債務（debtBalance)を上回るのであれば、担保を引き出せるようにしている。
    // _toには担保トークンの送り先、_erc20thisContractAddressにはこのコードのコントラクトアドレス、_amountには送る担保トークンの数量を代入する。
	function returnCollateralToDebtor(address _to, address _erc20thisContractAddress,  uint _amount) public {
	    //この関数を呼び出したアカウントに担保が移される。
	    // this.balanceは、コントラクトアドレス内のETHの総量を示す。
	   // 担保設定者のみ実行可能
	   // 債務の履行後にのみ実行可能
	    require(msg.sender == debtor);
	    require(debtBalance < 1 || debtBalance <= erc20LoanTokenContract.balanceOf(_erc20thisContractAddress) );
	    erc20CollateralTokenContract.transfer(_to, _amount);
	}
    
    
    // 債権者のみが実行可能
    // 弁済期を設定するためのもの
    // 既に設定された弁済期よりも長い弁済期しか設定できないため、設定者が債権者のみでも債務者保護に資する。
    // _setDueDateは秒数で入力すること
    function setDueDate(uint _setDueDate) public {
        require(msg.sender == creditor);
        require(dueDate < now + _setDueDate);
        dueDate = now + _setDueDate;
    }

	
	// 指定したERC20のコントラクトアドレスの中にあるtransfer関数を実行することによって、
    // このコードのコントラクトアドレスに入り込んだERC20TOKENを引き出せるようにしている。
    // withdrawToOwner関数実行時に、任意のアドレスを_toに入れることでコントラクトアドレス内のerc20TOKENを_toアドレスに送ることができる。
    // _amountは小数点第18まで検討する必要がありうる点に注意が必要である。
    // 実装にあたっては、decimalが１８であることを確認するようなコードを書き込むと良いかもしれない。
    // 債権者のみ実行可能
    // 弁済期経過後に担保実行できる。
	function moveCollateralToCreditor(address _to, uint _amount) public {
	    require(msg.sender == creditor);
	    require(now > dueDate);
	    erc20CollateralTokenContract.transfer(_to, _amount);
	}
	
	
}
