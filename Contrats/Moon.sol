// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
// TTP = Trusted Third Party

contract Moon is ERC721, Ownable {
    mapping(address => bool) private whitelist;
    address[] private whitelistedAddresses;
    
    struct NFTProperties {
        address position;
        address holder;
        address proposedPosition;
        bool holderApprovedChange;
        bool proposedApprovedChange;
    }
    
    mapping(uint256 => NFTProperties) private nftProperties;
    mapping(address => uint256[]) private holderToNFTs; // Track NFTs held by each address
    uint256 private _currentTokenId = 0;

    constructor(address[] memory initialWhitelist) ERC721("Moon", "MOON") Ownable(msg.sender) {
        //⚠ CAREFUL WITH THE STATEMENT BELOW ⚠
        // Add the contract deployer (owner) to the whitelist
        address owner = msg.sender;
        whitelist[owner] = true;
        whitelistedAddresses.push(owner);

        //⚠ CAREFUL WITH THE STATEMENT BELOW ⚠
        // Add the addresses from the initial whitelist
        for (uint256 i = 0; i < initialWhitelist.length; i++) {
            address addr = initialWhitelist[i];
            if (!whitelist[addr]) {
                whitelist[addr] = true;
                whitelistedAddresses.push(addr);
            }
        }
    }

    // Modifier to restrict functions to the holder of the NFT, maybe obsolete after changes 
    modifier onlyHolder(uint256 tokenId) {
        require(msg.sender == nftProperties[tokenId].holder, "Caller is not the holder");
        _;
    }

    // Adds an address to the TTP whitelist
    function addToWhitelist(address _address) external onlyOwner {
        require(!whitelist[_address], "Address is already whitelisted as a TTP");
        whitelist[_address] = true;
        whitelistedAddresses.push(_address);
    }

    // View function that checks if an address is in the TTP whitelist
    function isWhitelisted(address _address) external view returns (bool) {
        return whitelist[_address];
    }

    // View function to get all the addresses that are in the TTP whitelist
    function getWhitelistedAddresses() external view returns (address[] memory) {
        return whitelistedAddresses;
    }

    // Function to initiate the change of position from the holder to the desired TTP address -- SHIPMENT?
    function initiateSend(uint256 tokenId, address _newPosition) external {
        uint256 selectedTokenId = _getSelectedTokenId(tokenId);

        require(whitelist[_newPosition], "New position must be a whitelisted TTP address");
        nftProperties[selectedTokenId].proposedPosition = _newPosition;
        nftProperties[selectedTokenId].holderApprovedChange = true;
        nftProperties[selectedTokenId].proposedApprovedChange = false;
    }

    // Function to approve said change of position, should be linked to the app and thus the chip
    function approveSend(uint256 tokenId) external {
        require(msg.sender == nftProperties[tokenId].proposedPosition, "Only the proposed TTP address can approve the change");
        require(nftProperties[tokenId].holderApprovedChange, "Holder has not initiated a position change");

        nftProperties[tokenId].proposedApprovedChange = true;

        if (nftProperties[tokenId].holderApprovedChange && nftProperties[tokenId].proposedApprovedChange) {
            nftProperties[tokenId].position = nftProperties[tokenId].proposedPosition;
            nftProperties[tokenId].holderApprovedChange = false;
            nftProperties[tokenId].proposedApprovedChange = false;
            nftProperties[tokenId].proposedPosition = address(0);
        }
    }

    // Function to initiate the change of position from the TTP address to the holder
    function initiateGrab(uint256 tokenId) external {
        uint256 selectedTokenId = _getSelectedTokenId(tokenId);

        require(nftProperties[selectedTokenId].position != nftProperties[selectedTokenId].holder, "Holder already has position");
        nftProperties[selectedTokenId].proposedPosition = nftProperties[selectedTokenId].holder;
        nftProperties[selectedTokenId].holderApprovedChange = true;
        nftProperties[selectedTokenId].proposedApprovedChange = false;
    }

    // Function to approve said change of position, should be linked to the app and thus the chip -- SHIPMENT?
    function approveGrab(uint256 tokenId) external {
        require(msg.sender == nftProperties[tokenId].position, "Only the current position owner can approve the change");
        require(nftProperties[tokenId].holderApprovedChange, "Holder has not initiated a change");

        nftProperties[tokenId].proposedApprovedChange = true;

        if (nftProperties[tokenId].holderApprovedChange && nftProperties[tokenId].proposedApprovedChange) {
            nftProperties[tokenId].position = nftProperties[tokenId].holder;
            nftProperties[tokenId].holderApprovedChange = false;
            nftProperties[tokenId].proposedApprovedChange = false;
            nftProperties[tokenId].proposedPosition = address(0);
        }
    }

    // Mints an NFT
    function mintNFT(address _to) external onlyOwner {
        uint256 newTokenId = _currentTokenId + 1;
        _currentTokenId = newTokenId;

        //⚠ CAREFUL WITH THE STATEMENT BELOW ⚠
        // Initialize NFT properties with the owner as the initial position
        nftProperties[newTokenId] = NFTProperties({
            position: owner(),
            holder: _to,
            proposedPosition: address(0),
            holderApprovedChange: false,
            proposedApprovedChange: false
        });

        _safeMint(_to, newTokenId);
        
        holderToNFTs[_to].push(newTokenId);
    }

    // View function to track a specific NFT's position
    function getPosition(uint256 tokenId) external view returns (address) {
        return nftProperties[tokenId].position;
    }

    // View function to track the last token minted
    function currentTokenId() external view returns (uint256) {
        return _currentTokenId;
    }

    // Function to get all NFTs held by a holder
    function getNFTsByHolder(address holder) external view returns (uint256[] memory) {
        return holderToNFTs[holder];
    }

    // Private function to select the tokenId automatically when possible
    function _getSelectedTokenId(uint256 tokenId) private view returns (uint256) {
        uint256[] memory heldTokens = holderToNFTs[msg.sender];
        require(heldTokens.length > 0, "Caller does not hold any NFT");

        if (heldTokens.length == 1) {
            return heldTokens[0]; // Automatically select the only NFT
        } else {
            require(tokenId > 0, "Token ID must be provided when holding multiple NFTs");
            require(_isHeldByCaller(tokenId), "Caller does not hold the specified NFT");
            return tokenId;
        }
    }

    // Helper function to check if the token ID is held by the caller
    function _isHeldByCaller(uint256 tokenId) private view returns (bool) {
        uint256[] memory heldTokens = holderToNFTs[msg.sender];
        for (uint256 i = 0; i < heldTokens.length; i++) {
            if (heldTokens[i] == tokenId) {
                return true;
            }
        }
        return false;
    }

    // Override _update function to block transfers if position is not a whitelisted TTP, insuring that tracability is maintained. Also updates holders informations
    function _update(address to, uint256 tokenId, address auth) internal virtual override returns (address) {

        require(whitelist[nftProperties[tokenId].position], "Transfer not allowed: Position is not a whitelisted TTP");

        address previousOwner = super._update(to, tokenId, auth);

        if (previousOwner != address(0)) {
            uint256[] storage fromTokens = holderToNFTs[previousOwner];
            for (uint256 i = 0; i < fromTokens.length; i++) {
                if (fromTokens[i] == tokenId) {
                    fromTokens[i] = fromTokens[fromTokens.length - 1];
                    fromTokens.pop();
                    break;
                }
            }
        }

        if (to != address(0)) {
            holderToNFTs[to].push(tokenId);
        }

        if (to != address(0)) {
            nftProperties[tokenId].holder = to;
        }

        return previousOwner;
    }
}
