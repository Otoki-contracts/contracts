// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


import {ERC721} from "@OpenZeppelin/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import {IERC20} from "@OpenZeppelin/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";


contract EmbedingNFT is ERC721 {
    
    // @dev See {ERC721}.
    constructor() ERC721("EmbededNFT", "ENFT") {}
    
    // Initialized tokenId.
    uint256 public nextTokenId = 0;
 
    // Mapping from tokenId to token URIs.
    mapping(uint256 => string) private _tokenURIs;
    
    // Mapping from tokenId to embededAmount.
    mapping(uint256 => uint256) public embededAmount;
    
    // Mapping from tokenId to embededTokenAddress.
    mapping(uint256 => address) public embededTokenAddress;
    
    


    /** @dev See {ERC721 - _mint}. An ERC20 token have to be embeded.
     * @param _tokenURI e.g. URL, json
     * @param _embededTokenAddress contract address of embeded IRC20 token 
     * @param _embededAmount amount of embeded IRC20 token
     * 
     * stringを入力すれば、それをtokenURIとするNFTがmintされる。
     * ERC20トークンのコントラクトアドレス及び量を入力した場合、その量がコントラクトアドレスの中に保管される。
     * SafeMathを使うのがなんか嫌だったからrequire(nextTokenId + 1 > nexTokenId);を使った。本質的にはsafeMathと変わらない。
     */
    function mint(string memory _tokenURI, address _embededTokenAddress, uint256 _embededAmount) external {
    
      address minter = msg.sender;
      require(IERC20(_embededTokenAddress).balanceOf(minter) >= _embededAmount);
    
      IERC20(_embededTokenAddress).transferFrom(minter, address(this), _embededAmount);
    
      uint256 tokenId = nextTokenId;
      super._mint(msg.sender, tokenId);
      _setTokenURI(tokenId, _tokenURI);
    
      embededAmount[tokenId] = _embededAmount;
      embededTokenAddress[tokenId] = _embededTokenAddress;
    
      require(nextTokenId + 1 > nextTokenId);
      nextTokenId++;
    }
  
  
    // @dev Returns embededAmount
    function getEmbededAmount(uint256 tokenId) external view returns (uint256) {
       return embededAmount[tokenId];
    }
    
    
    // @dev Returns embededTokenAddress
    function getEmbededTokenAddress(uint256 tokenId) external view returns (address) {
       return embededTokenAddress[tokenId];
    }
  
    
    
    /** @dev See {ERC721}.
     * Delete owner's tkenId and transfer embeded token to ownerOf
     * 
     * 存在するtokenIdのownerがtokenIdをburnすればtokenIdがdeleteされ、mint時にembedされたトークンがownerに送金される。
     */
    function burn(uint256 tokenId) external {
       require(ownerOf(tokenId) == msg.sender);
      
       IERC20(embededTokenAddress[tokenId]).transfer(ownerOf(tokenId), embededAmount[tokenId]);
      
       super._burn(tokenId);

    }

  
      /**
     * @dev See {IERC721Metadata-tokenURI}. More information in
     * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/extensions/ERC721URIStorage.sol
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }
        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }
}
