// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

contract StarterUpgradeable is ERC721PausableUpgradeable, AccessControlUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using StringsUpgradeable for uint256;

    uint256 public mintingPhase; // 0 closed, 1+ = open (you can define additional phases and logic)
    uint256 public maxSupply;
    uint256 public salePrice;
    uint256 public maxPerWallet;
    
    address payable private withdrawWallet;

    string public baseURI;
    string public contractURI;

    bool public numberedMetadata;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant AIRDROPPER_ROLE = keccak256("AIRDROPPER_ROLE");
    bytes32 public constant CROSSMINT_ROLE = keccak256("CROSSMINT_ROLE");

    CountersUpgradeable.Counter internal nextId;

    struct InitArgs {
        string name;
        string symbol;
        uint256 mintingPhase;
        uint256 maxSupply;
        uint256 salePrice;
        uint256 maxPerWallet;
        address payable withdrawWallet;
        address crossmintWallet;
        string baseURI;
        string contractURI;
        bool numberedMetadata;
    }   

    function initialize(InitArgs calldata _init) public initializer {
        
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(AIRDROPPER_ROLE, msg.sender);
        _grantRole(CROSSMINT_ROLE, msg.sender); // for testing
        _grantRole(CROSSMINT_ROLE, _init.crossmintWallet);
        
        mintingPhase = _init.mintingPhase;
        maxSupply = _init.maxSupply;
        salePrice = _init.salePrice;
        maxPerWallet = _init.maxPerWallet;
        withdrawWallet = _init.withdrawWallet;
        baseURI = _init.baseURI;
        contractURI = _init.contractURI;
        numberedMetadata = _init.numberedMetadata;

        __ERC721_init_unchained(_init.name, _init.symbol);
        __Pausable_init_unchained();

        // start out with transfers paused/locked
        _pause();

        // start token ID counter at 1 instead of 0
        nextId.increment();
    }

    // MODIFIERS

    modifier isCorrectPayment(uint256 _quantity) {
        require(msg.value == (salePrice * _quantity), "Incorrect Payment Sent");
        _;
    }

    modifier isActive() {
        require(mintingPhase > 0, "Minting is not active");
        _;
    }

    modifier isWithinWalletLimit(address _recipient, uint256 _quantity) {
        require(balanceOf(_recipient) + _quantity <= maxPerWallet, "Exceeds max wallet count");
        _;
    }

    modifier isAvailable(uint256 _quantity) {
        require(nextId.current() + _quantity <= maxSupply, "Not enough tokens left for quantity");
        _;
    }

    // MINTING

    function mint(uint256 _quantity) 
        external  
        payable
        isActive()
        isCorrectPayment(_quantity)
        isAvailable(_quantity)
    {
        mintInternal(msg.sender, _quantity);
    }

    function crossmint(address _recipient, uint256 _quantity) 
        external  
        payable
        onlyRole(CROSSMINT_ROLE)
        isActive()
        isCorrectPayment(_quantity)
        isAvailable(_quantity)
    {
        mintInternal(_recipient, _quantity);
    }

    function airdrop(address _recipient, uint256 _quantity)
        external 
        isActive()
        isAvailable(_quantity) 
        onlyRole(AIRDROPPER_ROLE)
    {
        mintInternal(_recipient, _quantity);
    }

    // INTERNAL

    function mintInternal(address _to, uint256 _quantity) internal {
        for (uint256 i = 0; i < _quantity; i++) {
            uint256 tokenId = nextId.current();
            nextId.increment();

            _safeMint(_to, tokenId);
        }
    }

    // ADMIN

    function setMintingPhase(uint256 _phase) external onlyRole(ADMIN_ROLE) {
        mintingPhase = _phase;
    }

    function setPrice(uint256 _newPrice) external onlyRole(ADMIN_ROLE) {
        salePrice = _newPrice;
    }

    function setWithdrawWallet(address payable _wallet) external onlyRole(ADMIN_ROLE) {
        withdrawWallet = _wallet;
    }

    function setBaseURI(string calldata _newURI) external onlyRole(ADMIN_ROLE) {
        baseURI = _newURI;
    }

    function setContractURI(string calldata _newURI) external onlyRole(ADMIN_ROLE) {
        contractURI = _newURI;
    }

    function setNumberedMetadata(bool _numbered) external onlyRole(ADMIN_ROLE) {
        numberedMetadata = _numbered;
    }

    function pauseTransfers() external onlyRole(ADMIN_ROLE) {
        _pause();
    }

    function unpauseTransfers() external onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    function withdraw() public onlyRole(ADMIN_ROLE) {
        require(withdrawWallet != address(0), "Withdraw wallet not set");
        payable(withdrawWallet).transfer(address(this).balance);
    }    

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireMinted(tokenId);

        if (numberedMetadata) {
            return string(abi.encodePacked(baseURI, tokenId.toString(), ".json")); 
        }
        else {
            return baseURI;
        }
    }

    function supportsInterface(bytes4 interfaceId) 
        public 
        view 
        virtual 
        override
    (ERC721Upgradeable, AccessControlUpgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
