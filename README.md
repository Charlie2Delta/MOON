# NFT Authentication for Art and Collectibles
This repository contains the implementation of an NFT-based solution designed for the authentication and exchange of artworks and collectibles. The system combines secure hardware (an NFC chip) with blockchain technology to create a verifiable, trust-based environment for transferring ownership of physical items using NFTs.

# Project Overview
Our project aims to bridge the gap between the digital world of NFTs and the physical realm of art and collectibles. By securely attaching an NFC chip to a physical item and linking it with a unique NFT, we ensure that the item’s authenticity and ownership can be verified and transferred only through our dedicated application.

# Repository Structure
App: The application folder contains the source code for the mobile application that interacts with the NFC chip. This app is responsible for reading the chip and authenticating the physical item.

Contracts: The smart-contracts folder includes all the smart contracts written in Solidity, which are responsible for minting, transferring, and managing the NFTs on the blockchain.

# Features
NFC Chip Integration: A highly secure NFC chip is embedded in the physical item. This chip can only be read by our custom-built application, ensuring the authenticity of the item.

NFT Linking: Each item is linked to a unique NFT on the blockchain. This NFT contains metadata representing the physical item's identity and ownership.

Secure Transfer: The NFT can only be transferred after the physical item has been authenticated by a trusted third party using the application.

On-Chain Position Tracking: The NFTs minted have a built-in function to track and display their position on-chain, providing transparent verification.
