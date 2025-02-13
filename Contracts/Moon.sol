// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Moon is ERC721, Ownable {
    // Whitelist mapping and array for tracking Trusted Third Party (TTP) addresses
    mapping(address => bool) private whitelist;
    address[] private whitelistedAddresses;
    
    // Structure representing properties of an NFT
    struct NFTProperties {
        address currentPosition;
        address holder;
        address proposedPosition;
        bool holderApprovedChange;
        bool proposedApprovedChange;
    }
    
    // Mappings for NFT properties and tracking NFTs held by addresses
    mapping(uint256 => NFTProperties) private nftProperties;
    mapping(address => uint256[]) private holderToNFTs;
    uint256 private _currentTokenId = 0;

    // Constructor: initializes contract with a whitelist and sets the owner as a TTP
    constructor(address[] memory initialWhitelist) ERC721("Moon", "MOON") {
        // Add the contract owner to the whitelist
        address contractOwner = msg.sender;
        whitelist[contractOwner] = true;
        whitelistedAddresses.push(contractOwner);

        // Add provided addresses to the whitelist
        for (uint256 i = 0; i < initialWhitelist.length; i++) {
            address addr = initialWhitelist[i];
            if (!whitelist[addr]) {
                whitelist[addr] = true;
                whitelistedAddresses.push(addr);
            }
        }
    }

    // Modifier to restrict function access to the NFT holder
    modifier onlyHolder(uint256 tokenId) {
        require(msg.sender == nftProperties[tokenId].holder, "Caller is not the holder of the NFT");
        _;
    }

    // Adds an address to the TTP whitelist
    function addToWhitelist(address _address) external onlyOwner {
        require(!whitelist[_address], "Address is already whitelisted");
        whitelist[_address] = true;
        whitelistedAddresses.push(_address);
    }

    // Returns true if an address is whitelisted as a TTP
    function isWhitelisted(address _address) external view returns (bool) {
        return whitelist[_address];
    }

    // Retrieves all addresses in the TTP whitelist
    function getWhitelistedAddresses() external view returns (address[] memory) {
        return whitelistedAddresses;
    }

    // Initiates a position change to a new TTP address
    function initiateSend(uint256 tokenId, address _newPosition) external onlyHolder(tokenId) {
        require(whitelist[_newPosition], "New position must be a whitelisted TTP address");
        nftProperties[tokenId].proposedPosition = _newPosition;
        nftProperties[tokenId].holderApprovedChange = true;
        nftProperties[tokenId].proposedApprovedChange = false;
    }

    // Approves a proposed position change; only callable by the proposed TTP address
    function approveSend(uint256 tokenId) external {
        require(msg.sender == nftProperties[tokenId].proposedPosition, "Caller is not the proposed TTP address");
        require(nftProperties[tokenId].holderApprovedChange, "Position change not initiated by the holder");

        nftProperties[tokenId].proposedApprovedChange = true;

        if (nftProperties[tokenId].holderApprovedChange && nftProperties[tokenId].proposedApprovedChange) {
            nftProperties[tokenId].currentPosition = nftProperties[tokenId].proposedPosition;
            nftProperties[tokenId].holderApprovedChange = false;
            nftProperties[tokenId].proposedApprovedChange = false;
            nftProperties[tokenId].proposedPosition = address(0);
        }
    }

    // Initiates the return of the NFT's position to the holder
    function initiateGrab(uint256 tokenId) external onlyHolder(tokenId) {
        require(nftProperties[tokenId].currentPosition != nftProperties[tokenId].holder, "NFT is already with the holder");
        nftProperties[tokenId].proposedPosition = nftProperties[tokenId].holder;
        nftProperties[tokenId].holderApprovedChange = true;
        nftProperties[tokenId].proposedApprovedChange = false;
    }

    // Approves the return of the NFT's position to the holder; callable by the current position's TTP
    function approveGrab(uint256 tokenId) external {
        require(msg.sender == nftProperties[tokenId].currentPosition, "Caller is not the current position owner");
        require(nftProperties[tokenId].holderApprovedChange, "Position change not initiated");

        nftProperties[tokenId].proposedApprovedChange = true;

        if (nftProperties[tokenId].holderApprovedChange && nftProperties[tokenId].proposedApprovedChange) {
            nftProperties[tokenId].currentPosition = nftProperties[tokenId].holder;
            nftProperties[tokenId].holderApprovedChange = false;
            nftProperties[tokenId].proposedApprovedChange = false;
            nftProperties[tokenId].proposedPosition = address(0);
        }
    }

    // Mints a new NFT and assigns its initial properties
    function mintNFT(address _to) external onlyOwner {
        uint256 newTokenId = _currentTokenId + 1;
        _currentTokenId = newTokenId;

        nftProperties[newTokenId] = NFTProperties({
            currentPosition: owner(),
            holder: _to,
            proposedPosition: address(0),
            holderApprovedChange: false,
            proposedApprovedChange: false
        });

        _safeMint(_to, newTokenId);
        holderToNFTs[_to].push(newTokenId);
    }

    // Retrieves the current position of a specified NFT
    function getPosition(uint256 tokenId) external view returns (address) {
        return nftProperties[tokenId].currentPosition;
    }

    // Retrieves the most recent token ID minted
    function currentTokenId() external view returns (uint256) {
        return _currentTokenId;
    }

    // Returns all NFTs held by a specific holder
    function getNFTsByHolder(address holder) external view returns (uint256[] memory) {
        return holderToNFTs[holder];
    }

    // Private function to get the selected tokenId, choosing automatically if only one is held
    function _getSelectedTokenId(uint256 tokenId) private view returns (uint256) {
        uint256[] memory heldTokens = holderToNFTs[msg.sender];
        require(heldTokens.length > 0, "Caller does not hold any NFT");

        if (heldTokens.length == 1) {
            return heldTokens[0];
        } else {
            require(tokenId > 0, "Token ID required when holding multiple NFTs");
            require(_isHeldByCaller(tokenId), "Caller does not hold the specified NFT");
            return tokenId;
        }
    }

    // Helper function to check if the caller holds a specific tokenId
    function _isHeldByCaller(uint256 tokenId) private view returns (bool) {
        uint256[] memory heldTokens = holderToNFTs[msg.sender];
        for (uint256 i = 0; i < heldTokens.length; i++) {
            if (heldTokens[i] == tokenId) {
                return true;
            }
        }
        return false;
    }

    // Internal function to update NFT holder information upon transfer, ensuring whitelist validation
    function _update(address to, uint256 tokenId, address auth) internal virtual override returns (address) {
        require(whitelist[nftProperties[tokenId].currentPosition], "Transfer denied: Current position is not whitelisted");

        // Call the parent contract's _update function
        address previousOwner = super._update(to, tokenId, auth);

        // Remove token from the previous holder's list
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

        // Add token to the new holder's list
        if (to != address(0)) {
            holderToNFTs[to].push(tokenId);
        }

        // Update holder information
        if (to != address(0)) {
            nftProperties[tokenId].holder = to;
        }

        return previousOwner;
    }
}
