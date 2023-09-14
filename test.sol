
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/interfaces/IERC20.sol';
import '@openzeppelin/contracts/interfaces/IERC2981.sol';
import '@openzeppelin/contracts/interfaces/IERC721.sol';
import '@openzeppelin/contracts/interfaces/IERC1155.sol';
import '@openzeppelin/contracts/token/ERC721/presets/ERC721PresetMinterPauserAutoId.sol';
import '@openzeppelin/contracts/utils/Counters.sol';

contract LilFTMCube is ERC721PresetMinterPauserAutoId, IERC2981, Ownable {
    using Counters for Counters.Counter;
    
    uint8 public immutable MAX_SUPPLY; // = 129;
    uint8 public immutable MAX_MINT; // = 4;
    uint256 public immutable CUBE_PRICE; // = 100 * 10**18;

    // royalty with base 10000, so 500 = 5%
    uint16 private royalty = 500;

    // track token ids as they are minted
    Counters.Counter private tokenIds;

    // uses the OZ preset
    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseURI,
        uint8 _maxSupply,
        uint8 _maxPerMint,
        uint256 _cubePrice
    ) ERC721PresetMinterPauserAutoId(_name, _symbol, _baseURI) {
        MAX_SUPPLY = _maxSupply;
        MAX_MINT = _maxPerMint;
        CUBE_PRICE = _cubePrice;
    }
    

    function mintCube(uint256 _quantity) public payable returns (uint[] memory) {
        require(CUBE_PRICE * _quantity == msg.value, 'The value sent does not match the minting price.');
        require(MAX_SUPPLY >= tokenIds.current() + _quantity, 'There are not this many cubes remaining.');

        for (uint8 i = 0; i < _quantity; i++) {
            tokenIds.increment();

            _safeMint(msg.sender, tokenIds.current());
        }
    }
    
    
    

    /// @notice Minting is only allowed through the mintCube function
    /// @dev only allow minting through safe mint
    function mint(address) public pure override {
        require(false, 'You must mintCube().');
    }

    /// @dev override to check the max supply when minting
    function _mint(address to, uint256 _id) internal override {
        require(_id <= MAX_SUPPLY, 'All the Cubes are minted.');
        super._mint(to, _id);
    }

    /// @dev Return the URI for the token as the base URL + tokenId as string
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, uint2str(_tokenId))) : '';
    }

    //* Helper Functions *//
    /// @dev Converts each position in a number to a character: 123 = abc
    function uint2str(uint256 _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return '0';
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    /// @dev Support for IERC-2981, royalties
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(IERC165, ERC721PresetMinterPauserAutoId)
        returns (bool)
    {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    /// @notice Calculate the royalty payment
    /// @param _salePrice the sale price of the token
    function royaltyInfo(uint256, uint256 _salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        return (address(this), (_salePrice * royalty) / 10000);
    }

    /// @dev set the royalty
    /// @param _royalty the royalty in base 10000, 500 = 5%
    function setRoyalty(uint16 _royalty) external onlyOwner {
        require(_royalty >= 0, 'Royalty must be greater than or equal to 0%');
        require(_royalty <= 750, 'Royalty must be greater than or equal to 7.5%');

        royalty = _royalty;
    }

    /// @dev withdraw native tokens divided by splits
    function withdraw() external {
        uint256 _amount = address(this).balance;
        (bool sent, ) = payable(this.owner()).call{value: _amount}('');
        require(sent, 'Failed to send payment');
    }

    /// @dev withdraw ERC20 tokens divided by splits
    function withdrawTokens(address _tokenContract) external {
        IERC20 tokenContract = IERC20(_tokenContract);

        // transfer the token from address of this contract
        uint256 _amount = tokenContract.balanceOf(address(this));
        tokenContract.transfer(this.owner(), _amount);
    }
}

