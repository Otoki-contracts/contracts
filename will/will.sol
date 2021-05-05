// CAUTION! This contract is just a test contract. If you use this contract on the ETH mainnet, you might loss your precious assets because of security errors or inaccurate codes.

// crypt zombieを基本資料としたので0.4.18にしている。
pragma solidity ^0.4.18;

// living messageや　withdrawToOwnerはコントラクト生成者（遺言者）のみが行うべきであるため、ownable修飾子を用いたかった。

import "./ownable.sol";
 
contract Will is Ownable {
    
    // Ownable Contractにaddress public ownerが定義されている。
    // ownerが遺言者、receiverが受遺者である。
    
    address public receiver;
	uint withdrawableTime;
	uint cooldownTime = 1 minutes;
	
// 	下記はreceiverとして、firefoxのmetamskアカウントをconstructorで書き込んだ。本来であればreceiverを変更できるfunctionを記述すべきであるとも思えるが、セキュリティの向上及び遺言の性質からしてひとまずアドレス変更functionをつけないことにする。
	constructor() public {
	    receiver = 0xC960804664D3fAdDcD037240BFD55A2e1F197503;
	}
	
	
	function deposit() public payable {
	    //この関数を呼び出したアカウントから指定分のイーサが入る
	    // このときdeployボタンの上にある　VALUE欄の数字をいじることで送金できるETHの量を変更できることに注意！！！
	}
	
	function withdrawToOwner() public onlyOwner {
	    //この関数を呼び出したアカウントにamountが支払われる
	    // this.balanceは、コントラクトアドレス内のETHの総量を示す。
	    msg.sender.transfer(address(this).balance);
	}
	
	
    // livingmessageを送り続けることで、受遺者がコントラクトアドレス内のETHを引き出せないようになる。
    // 今回はテスト用としてcooldownTimeを1 minutesとしたが、実装するならば1-3 monthsあたりが適当であると考えられる。
	function livingMessage() public onlyOwner {
	    withdrawableTime = now + cooldownTime;
	}
	
    // onlyOwnerと同じ仕組み
	modifier onlyReceiver() {
        require(msg.sender == receiver);
        _;
    }
	
	function withdrawToReceiver() public onlyReceiver {
	    require(now > withdrawableTime );
	    msg.sender.transfer(address(this).balance);
	    
	}
	
	
	
	
	
	
}
