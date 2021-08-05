// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./NFTCollection.sol";

contract NFTMarketplace {
  uint public offerCount;
  mapping (uint => _Offer) public offers;
  mapping (address => uint) public userFunds;
  NFTCollection nftCollection;
  
  struct _Offer {
    uint offerId;
    uint id;
    address user;
    uint price;
    bool fulfilled;
    bool cancelled;
  }

  event Offer(
    uint offerId,
    uint id,
    address user,
    uint price,
    bool fulfilled,
    bool cancelled
  );

  event OfferFilled(uint offerId);
  event OfferCancelled(uint offerId);
  event OfferModified(uint offerId, uint price);
  event ClaimFunds(address user, uint amount);

  constructor(address _nftCollection) {
    nftCollection = NFTCollection(_nftCollection);
  }
  
  function makeOffer(uint _id, uint _price) public {
    nftCollection.transferFrom(msg.sender, address(this), _id);
    offerCount ++;
    offers[offerCount] = _Offer(offerCount, _id, msg.sender, _price, false, false);
    emit Offer(offerCount, _id, msg.sender, _price, false, false);
  }

  function fillOffer(uint _offerId) public payable {
    _Offer storage _offer = offers[_offerId];
    require(_offer.offerId == _offerId); // the offer must exist
    require(!_offer.fulfilled, 'An offer cannot be fulfilled twice');
    require(!_offer.cancelled, 'Only non-cancelled offers can be executed');
    require(msg.value == _offer.price, 'The ETH amount should match with the NFT Price');
    nftCollection.transferFrom(address(this), msg.sender, _offer.id);
    _offer.fulfilled = true;
    userFunds[_offer.user] += msg.value;
    emit OfferFilled(_offerId);
  }

  function cancelOffer(uint _offerId) public {
    _Offer storage _offer = offers[_offerId];
    require(_offer.offerId == _offerId); // the offer must exist
    require(_offer.user == msg.sender, 'The offer can only be canceled by the owner');
    require(_offer.fulfilled == false, 'Only non-fulfilled orders can be cancelled');
    require(_offer.cancelled == false, 'An offer cannot be cancelled twice');
    _offer.cancelled = true;
    emit OfferCancelled(_offerId);
  }

  function changePrice(uint _offerId, uint _newPrice) public {
    _Offer storage _offer = offers[_offerId];
    require(_offer.offerId == _offerId); // the offer must exist
    require(_offer.user == msg.sender, 'Only the owner can modify its offer');
    require(_offer.fulfilled == false, 'Only non-fulfilled orders can be modified');
    require(_offer.cancelled == false, 'Only non-cancelled orders can be modified');
    _offer.price = _newPrice;
    emit OfferModified(_offerId, _newPrice);
  }

  function claimFunds() public {
    require(userFunds[msg.sender] > 0, 'This user has no funds to be claimed');
    payable(msg.sender).transfer(userFunds[msg.sender]);
    emit ClaimFunds(msg.sender, userFunds[msg.sender]);
    userFunds[msg.sender] = 0;    
  }

  // Fallback: reverts if Ether is sent to this smart contract by mistake
  fallback () external {
    revert();
  }
}