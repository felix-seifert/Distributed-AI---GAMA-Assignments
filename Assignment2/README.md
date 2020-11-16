# Assignment 2

The model describes the interaction between ‘Auctioneers’ and ‘Bidders’. Both of them are introduced as species with ‘fipa’ skill that allows them to manage an auction system.

If there are no auctions held over the map, the Bidders will wander around it (with the ‘moving’ skill).

When an auction starts, the Auctioneer announces it to all the Bidders (‘reflex announceAuction’) through a conversation managed by fipa protocol (‘fipa-contract-net’) and Bidders will be able to subscribe to the auction if they are close enough.

The base auction is based on the “dutch” version: the Auctioneer starts with a high price (‘startingPriceDutch’, equal to 100) and lowers it through the time (by the ‘priceStep’ variable) until one Participant is available to accept the proposed price for the auctioned good. If the proposed price falls lower than a minimum amount (‘minimumPriceDutch’), the auction is cancelled.

To make the auctions more varied, the price Bidders are willing to pay is a random variable (‘maximumPrice’) between 65 and 90. When the maximum price for one Bidder is equal to the current proposed price for the auction, it will communicate it to the responsible Auctioneer with a proposal message.

Every time the price is lowered by a step, the Auctioneer will check the list of refuses and accept proposals: if there is at least one proposal, the auction will end with the current proposed price. Otherwise, the auction will go on.

Once the auction is finished, all the participants will be unsubscribed from the ended auction.


# Sealed Bid Auction

The auction is started randomly ('probabilityToStartAuction') by an Auctioneer. Every Bidder that is interested in the auctioned good will be notified and will reach the Auctioneer position.
When all the interested Bidders are close to the Auctioneer, the auction can start through the 'startSealedBidAuction' reflex. The parameters of the auction are communicated to the Bidders through the 'anounceAuction' reflex. The Bidders can now request to subscribe ('subscribeToNewAuction' reflex) to the open auction. The subscribtion/unsubscription of Bidders is managed by the Auctioneer via the 'addAndRemoveAuctionSubscribers' reflex.

Every Bidder is informed about the initial price (equal to 1) by the Auctioneer ('informBiddersAboutPriceSealedBidAuction' reflex), in order to allow them to propose their price offers.
Each of them will propose the maximum price that is willing to pay for the auctioned good through the 'reactOnSuggestedPriceSealedBidAuction' reflex. Now the Auctioneer can check all the offers by the Bidders and select the highest one ('handleProposalsSealedBidAuction' reflex). The Bidder that offered the highest price will be assigned as winner of the auction ('endSealedBidAuction' reflex). As last step, the winner Bidder will accept the price agree ('handleAcceptedProposalSealedBidAuction' reflex) and each Bidder will be released from the ended auction.
