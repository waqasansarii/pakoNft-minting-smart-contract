//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

contract PakoNFT is ERC721, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using Strings for uint256;

    bytes32 public root;

    address proxyRegistryAddress;

    uint256 public maxSupply = 100;

    string public baseUri;
    string public notRevealedUri =
        "ipfs://QmZdFkqr2z9ebFjUL3fdHjhYRT6bofF7XKCVvR8xZ9vy21/hidden.json";
    string public baseExtension = ".json";

    bool public _paused = false;
    bool public _reveal = false;
    bool public preSaleMint = false;
    bool public publicMint = false;

    uint256 public preSaleAmountLimit = 3;
    mapping(address => uint256) private ownedTokens;

    uint256 public price = 10000000000000000; //eth 0.01

    Counters.Counter private _tokenId;

    // if we have more than 1 account of that project so we can transfer eth
    // uint256[] private teamShares = [50,50];
    // address[] private teamAcounts = [
    //     0x383ec8EFb4EAA1f62DF1A39B83CD2854D2ad2244,  // admin account get 50% of the total revenue
    //     0x94FC1035713F7a2DAae589EA3F7a4494650240f7    // test account get 50% of the total revenue
    // ];

    constructor(
        string memory uri,
        bytes32 merkleRoot,
        address RegistryAddress
    ) ERC721("PAkO NFT", "PAK") ReentrancyGuard() {
        root = merkleRoot;
        proxyRegistryAddress = RegistryAddress;
        setBaseUri(uri);
    }

    function setBaseUri(string memory _baseUri) public onlyOwner {
        baseUri = _baseUri;
    }

    function reveal() public onlyOwner {
        _reveal = true;
    }

    function setMerkleRoot(bytes32 _root) public onlyOwner {
        root = _root;
    }

    modifier onlyAccount() {
        require(msg.sender == tx.origin, "Not allowed origin");
        _;
    }

    // this modifier only for presale mintinig
    modifier isValidMerkleProof(bytes32[] calldata _proof) {
        require(
            MerkleProof.verify(
                _proof,
                root,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Not allowed origin"
        );
        _;
    }

    function togglePause() public onlyOwner {
        _paused = !_paused;
    }

    function togglePreSaleMint() public onlyOwner {
        preSaleMint = !preSaleMint;
    }

    function togglePublicMint() public onlyOwner {
        publicMint = !publicMint;
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    function mint(
        address account,
        uint256 amount,
        bytes32[] calldata _proof
    ) public payable onlyAccount isValidMerkleProof(_proof) {
        require(msg.sender == account, "Not allowed");
        require(!_paused, "Minting is Paused");
        require(preSaleMint, "Pre Sale Minting closed!");
        require(amount <= preSaleAmountLimit, "Can not mint enough Nfts");
        uint256 numOfToken = _tokenId.current();
        require(numOfToken + amount <= maxSupply, "Max Supply excced!");
        require(
            ownedTokens[msg.sender] >= preSaleAmountLimit,
            "can not mint more than 3 nfts!"
        );
        require(msg.value == mul(amount, price), "you dont have enough ether");

        ownedTokens[msg.sender] += amount;

        for (uint256 i = 0; i < amount; i++) {
            mintInternal();
        }
    }

    function publicSaleMint(uint256 amount) public payable onlyAccount {
        require(publicMint, "Pre Sale Minting closed!");
        require(!_paused, "Minting is Paused");
        require(amount > 0, "Amount should be greater than 0");
        require(amount <= preSaleAmountLimit, "Can not mint enough Nfts");
        uint256 numOfToken = _tokenId.current();
        require(numOfToken + amount <= maxSupply, "Max Supply excced!");
        require(
            ownedTokens[msg.sender] >= preSaleAmountLimit,
            "can not mint more than 3 nfts!"
        );
        require(msg.value >= mul(amount, price), "you dont have enough ether");
        ownedTokens[msg.sender] += amount;

        for (uint256 i = 0; i < amount; i++) {
            mintInternal();
        }
    }

    function mintInternal() internal nonReentrant {
        _tokenId.increment();
        uint256 tokenIds = _tokenId.current();
        _safeMint(msg.sender, tokenIds);
    }

    function tokenUri(uint256 tokenId)
        public
        view
        virtual
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721 metadata: URI query for nonexistance token"
        );
        if (_reveal == false) {
            return notRevealedUri;
        }
        string memory currentUri = _baseURI();
        return
            bytes(currentUri).length > 0
                ? string(
                    abi.encodePacked(
                        currentUri,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    function setNotRevealedUri(string memory _uri) public onlyOwner {
        notRevealedUri = _uri;
    }

    function setBaseExtension(string memory _extension) public onlyOwner {
        baseExtension = _extension;
    }

    function totalSupply() public view returns (uint256) {
        return _tokenId.current();
    }

    // override isApprovedForAll to whitelist user's opensea proxy accounts to enable gas=less listing

    function isApprovedForAll(address owner , address operator) public view override returns(bool){
        // whitelist opensea proxy contract for easy trading 
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);

        if(address(proxyRegistry.proxies(owner))==operator){
            return true;
        }
        return super.isApprovedForAll(owner , operator);
    }
}


contract OwnableDelagateProxy{}

/**
 * Used to delegate ownership of a contract to another address, to save on unneeded transactions
  to approve contract use for users
 */
contract ProxyRegistry{

    mapping(address=>OwnableDelagateProxy) public proxies;

}
