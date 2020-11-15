/**
* Name: Auctions
* Model with several auctions which pop up every now and then. Potential bidders get informed 
* about auctions which start and can participate in them. 
* Author: Marco Molinari <molinarimarco8@gmail.com>, Felix Seifert <mail@felix-seifert.com>
*/


model Auctions

global {
 
	int gridWidth <- 10;
	int gridHeight <- 10;
	bool displayEntityName <- false;
	
	int nbAuctioneers <- 1;
	int nbBidders <- 10;
	
	string auctionStartedMsg <- 'auction-started';
	string auctionEndedMsg <- 'auction-ended';
	
	string subscribeMsg <- 'subscribe';
	string unsubscribeMsg <- 'unsubscribe';
	
	string priceInfoMsg <- 'price-info';
	
	string priceGoodMsg <- 'price-good';
	string priceTooHighMsg <- 'price-too-high';
	
	string proposalAcceptedMsg <-'accepted-proposal';
	string proposalRejectedMsg <-'rejected-proposal';
	
	string agreeMsg <- 'agree';
	
	int nextAuctionId <- 0;
	
	list<string> auctionGenres <- ['cloths', 'jewelry', 'recordings']; 
	
	init {
		create Auctioneer number: nbAuctioneers;
		create Bidder number: nbBidders;
	}
}

species Auctioneer skills: [fipa] {
	image_file icon <- image_file('../includes/data/auctioneer.png');
	
	int startingPrice <- 100;
	int priceStep <- 1;
	int minimumPrice <- 50;
	
	float probabilityToStartAuction <- 0.05;
	
	int auctionId <- -1;
	bool auctionStarted <- false;
	int currentPrice <- startingPrice;
	list<Bidder> currentRefusals <- [];
	
	string auctionGenre <- nil;
	list<Bidder> subscribedBidders <- [];
	
	reflex startAuction when: !auctionStarted and empty(subscribedBidders) 
			and flip(probabilityToStartAuction) {
		
		auctionStarted <- true;
		auctionGenre <- any(auctionGenres);
		currentPrice <- startingPrice;
		currentRefusals <- [];
		
		write name + ' started auction with genre ' + auctionGenre 
				+ ' and starting price of ' + currentPrice;
		
		auctionId <- nextAuctionId;
		nextAuctionId <- nextAuctionId + 1;
		
		do start_conversation to: list(Bidder) protocol: 'fipa-contract-net' 
				performative: 'inform' contents: [auctionStartedMsg, auctionId, auctionGenre];
	}
	
	reflex endAuction when: auctionStarted and !empty(informs) {
				
		loop msg over: informs {
			list<unknown> contents <- msg.contents;
			if(contents[0] = agreeMsg and contents[1] = currentPrice) {
				write Bidder(msg.sender).name + ' won the auction of ' + self.name 
						+ ' and has to pay ' + currentPrice;
				break;
			}
		}
		
		do endAuction;
	}
	
	action endAuction {
		do start_conversation to: subscribedBidders protocol: 'fipa-contract-net' 
				performative: 'inform' contents: [auctionEndedMsg];
		
		auctionStarted <- false;
		write 'The auction of ' + name + ' ended';
	}
	
	reflex addAndRemoveAuctionSubscribers when: !empty(subscribes) {
		
		loop s over: subscribes {
			list<unknown> contents <- s.contents;
			
			if(contents[0] = subscribeMsg and contents[1] = auctionId) {
				add Bidder(s.sender) to: subscribedBidders;
				write Bidder(s.sender).name + ' subscribed to the auction of ' + self.name;
				break;
			}
			if(contents[0] = unsubscribeMsg) {
				remove Bidder(s.sender) from: subscribedBidders;
				write Bidder(s.sender).name + ' unsubscribed from the auction of ' + self.name;
			}
		}
	}
	
	reflex handleRefusals when: auctionStarted and !empty(subscribedBidders) 
			and empty(proposes) and !empty(refuses) {
		
		loop refusal over: refuses {
			list<unknown> contents <- refusal.contents;
			
			if(contents[0] = priceTooHighMsg and contents[1] = currentPrice 
					and !(currentRefusals contains Bidder(refusal.sender))) {
				
				add Bidder(refusal.sender) to: currentRefusals;
			}
		}
	}
	
	reflex handleProposals when: auctionStarted and !empty(subscribedBidders) 
			and !empty(proposes) {
		
		loop acceptedProposal over: proposes {
			list<unknown> contents <- acceptedProposal.contents;
			if(contents[0] = priceGoodMsg and contents[1] = currentPrice) {
				do accept_proposal message: acceptedProposal contents: [proposalAcceptedMsg, currentPrice];
				break;
			}
		}
		
		loop rejectedProposal over: proposes {
			do reject_proposal message: rejectedProposal contents: [proposalRejectedMsg];
		}
	}
	
	reflex lowerPrice when: auctionStarted and !empty(subscribedBidders) 
			and length(currentRefusals) = length(subscribedBidders) {
		
		currentPrice <- currentPrice - priceStep;
		currentRefusals <- [];
		
		if(currentPrice < minimumPrice) {
			do endAuction;
		}
	}
	
	reflex informBiddersAboutPrice when: auctionStarted and !empty(subscribedBidders) 
			and length(currentRefusals) < length(subscribedBidders) {
		
		//write self.name + ' informs bidders about current price of ' + currentPrice;
		do start_conversation to: subscribedBidders protocol: 'fipa-contract-net' 
				performative: 'cfp' contents: [priceInfoMsg, currentPrice];
	}
	
	aspect default {
		draw icon size: 3.5 at: location;
		
		if(displayEntityName) {
			draw string(name) color: #black;	
		}
	}
}

species Bidder skills: [moving, fipa] {
	rgb color <- rgb(80, 80, 255) update: targetLocation = nil ? rgb(80, 80, 255) : color;
	
	point targetLocation <- nil;
	
	string auctionGenreInterested <- any(auctionGenres);
	int maximumPrice <- rnd(65, 90);
	
	reflex randomMove when: targetLocation = nil{
		do wander;
	}

	reflex moveToTarget when: targetLocation != nil 
			and location distance_to(targetLocation) > 2 {
		do goto target: targetLocation;
	}
	
	reflex subscribeToAndUnsubscribeFromAuction when: !empty(informs) {
		
		loop msg over: informs {
			list<unknown> contents <- msg.contents;
			
			if(contents[0] = auctionStartedMsg and contents[2] = auctionGenreInterested) {
				targetLocation <- agent(msg.sender).location;
				do subscribe message: msg contents: [subscribeMsg, contents[1]];
				break;
			}
			if(contents[0] = auctionEndedMsg) {
				do subscribe message: msg contents: [unsubscribeMsg];
				targetLocation <- nil;
				break;
			}
		}
	}
	
	reflex reactOnSuggestedPrice when: targetLocation != nil and !empty(cfps) 
			and location distance_to(targetLocation) < 3 {
		
		loop msg over: cfps {
			list<unknown> contents <- msg.contents;
			int suggestedPrice <- int(contents[1]);
		
			if(contents[0] = priceInfoMsg and suggestedPrice <= maximumPrice) {
				do propose message: msg contents: [priceGoodMsg, suggestedPrice];
				//write self.name + ' accepts price of ' + suggestedPrice;
				break;
			}
			do refuse message: msg contents: [priceTooHighMsg, suggestedPrice];
			//write self.name + ' refuses price of ' + suggestedPrice;
		}
	}
	
	reflex handleAcceptedProposal when: targetLocation != nil and !empty(accept_proposals) {
		message msg <- accept_proposals[0];
		list<unknown> contents <- msg.contents;
		
		if(contents[0] = proposalAcceptedMsg) {
			do inform message: msg contents: [agreeMsg, contents[1]];
			color <- #orange;
		}
	}
	
	aspect default {
		draw circle(1) at: location color: color;
		
		if(displayEntityName) {
			draw string(name) color: #black;	
		}
	}
}

grid AuctionCell width: gridWidth height: gridHeight neighbors: 4 {}

experiment DutchAuction type: gui {
 
	parameter "Width of festival grid: " var: gridWidth min: 10 max: 100 category: "Grid Size";
	parameter "Height of festival grid: " var: gridHeight min: 10 max: 100 category: "Grid Size";
	
	parameter "Initial number of auctioneers: " var: nbAuctioneers min: 1 max: 20 category: "Initial Numbers";
	parameter "Initial number of potential bidders: " var: nbBidders min: 10 max: 250 category: "Initial Numbers";
	
	parameter "Display entity names" var: displayEntityName category: "Options";
	
	output {
		display main_display {
			grid AuctionCell lines: #lightgrey;
			
			species Auctioneer;
			species Bidder;
		}
	}
}
