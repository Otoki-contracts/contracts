// crypt zombieを基本資料としたので0.4.18にしている。
pragma solidity ^0.4.18;

// living messageや　withdrawToOwnerはコントラクト生成者（遺言者）のみが行うべきであるため、ownable修飾を用いたかった。

import "./ownable.sol";
 
contract Will is Ownable {
    
    // Ownable Contractに定義されているため下記不要。
    // address public owner; 
    
    address public receiver;
	uint private amount;
	uint withdrawableTime;
	uint cooldownTime = 1 minutes;
	

	
// 	下記はreceiverとして、firefoxのmetamskアカウントをconstructorで書き込んだ。
	constructor() {
	    receiver = 0xC960804664D3fAdDcD037240BFD55A2e1F197503;
	}
	
	
//  Ownableのconstructorに定義されているため下記不要。 
// 	function Will() public {
// 	    //ownerにはこのコントラクトを生成したアカウントが設定される
// 		owner = msg.sender;
// 	}
	
	function deposit() public payable {
	    //この関数を呼び出したアカウントから指定分のイーサが入る
	    // このときdeployボタンの上にある　VALUE欄の数字をいじることで送金できるETHの量を変更できることに注意！！！
	   
	}
	
	function withdrawToOwner() public onlyOwner {
	    //この関数を呼び出したアカウントにamountが支払われる
	    // this.balanceは、コントラクトアドレス内のETHの総量を示す。
	    msg.sender.transfer(this.balance);
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
	    msg.sender.transfer(this.balance);    
	}
	
}
