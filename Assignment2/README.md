# Assignment 2

The model describes the interaction between ‘Auctioneers’ and ‘Bidders’. Both of them are introduced as species with ‘fipa’ skill that allows them to manage an auction system.

If there are no auctions held over the map, the Bidders will wander around it (with the ‘moving’ skill).

When an auction starts, the Auctioneer announces it to all the Bidders (‘reflex announceAuction’) through a conversation managed by fipa protocol (‘fipa-contract-net’) and Bidders will be able to subscribe to the auction if they are close enough.

The base auction is based on the “dutch” version: the Auctioneer starts with a high price (‘startingPriceDutch’, equal to 100) and lowers it through the time (by the ‘priceStep’ variable) until one Participant is available to accept the proposed price for the auctioned good. If the proposed price falls lower than a minimum amount (‘minimumPriceDutch’), the auction is cancelled.

To make the auctions more varied, the price Bidders are willing to pay is a random variable (‘maximumPrice’) between 65 and 90. When the maximum price for one Bidder is equal to the current proposed price for the auction, it will communicate it to the responsible Auctioneer with a proposal message.

Every time the price is lowered by a step, the Auctioneer will check the list of refuses and accept proposals: if there is at least one proposal, the auction will end with the current proposed price. Otherwise, the auction will go on.

Once the auction is finished, all the participants will be unsubscribed from the ended auction.

