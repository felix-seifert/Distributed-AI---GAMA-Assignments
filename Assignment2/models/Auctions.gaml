/**
* Name: Auctions
* Model with several auctions which pop up every now and then. Potential bidders get informed 
* about auctions which start and can participate in them. 
* Author: Marco Molinari <molinarimarco8@gmail.com>, Felix Seifert <mail@felix-seifert.com>
*/


model Auctions

global {
	
	string dutchAuction <- 'dutch';
	string englishAuction <- 'english';
	
	string auctionType <- dutchAuction;	// Type of auctions gets set by starting different experiments
 
	int gridWidth <- 10;
	int gridHeight <- 10;
	bool displayEntityName <- false;
	
	int nbAuctioneers <- 1;
	int nbBidders <- 10;
	
	string auctionStartedMsg <- 'auction-started';
	string auctionEndedMsg <- 'auction-ended';
	
	string subscribeMsg <- 'subscribe';
	string subscribeAndCloseMsg <- 'subscribe-close';	// Sent when agent wants subscription and is close to target
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
	
	int startingPriceDutch <- 100;
	int minimumPriceDutch <- 50;
	int priceStep <- 1;
	
	float probabilityToStartAuction <- 0.05;
	
	int auctionId <- -1;
	bool auctionStarted <- false;
	int currentPrice <- startingPriceDutch;
	list<Bidder> currentRefusals <- [];
	Bidder highestBidder <- nil;
	
	string auctionGenre <- nil;
	list<Bidder> subscribedBidders <- [];
	list<Bidder> subscribedBiddersWhoAreClose <- [];
	
	reflex startDutchAuction when: auctionType = dutchAuction and !auctionStarted 
			and empty(subscribedBidders) and flip(probabilityToStartAuction) {
		
		auctionStarted <- true;
		auctionGenre <- any(auctionGenres);
		currentPrice <- startingPriceDutch;
		currentRefusals <- [];
		
		write name + ' started Dutch auction with genre ' + auctionGenre 
				+ ' and starting price of ' + currentPrice;
		
		auctionId <- nextAuctionId;
		nextAuctionId <- nextAuctionId + 1;
	}
	
	reflex startEnglishAuction when: auctionType = englishAuction and !auctionStarted 
			and empty(subscribedBidders) and flip(probabilityToStartAuction) {
		
		auctionStarted <- true;
		auctionGenre <- any(auctionGenres);
		currentPrice <- 1;
		highestBidder <- nil;
		
		write name + ' started English auction with genre ' + auctionGenre 
				+ ' and starting price of ' + currentPrice;
		
		auctionId <- nextAuctionId;
		nextAuctionId <- nextAuctionId + 1;
	}
	
	reflex anounceAuction when: auctionStarted and empty(subscribedBidders) {
		do start_conversation to: list(Bidder) protocol: 'fipa-contract-net' 
				performative: 'inform' contents: [auctionStartedMsg, auctionId, auctionGenre];
	}
	
	reflex endDutchAuction when: auctionStarted and auctionType = dutchAuction 
			and !empty(informs) {
				
		loop msg over: informs {
			list<unknown> contents <- msg.contents;
			if(contents[0] = agreeMsg and contents[1] = currentPrice) {
				write Bidder(msg.sender).name + ' won auction of ' + self.name 
						+ ' and has to pay ' + currentPrice;
				break;
			}
		}
		
		do endAuctionMethod;
	}
	
	action endAuctionMethod {
		do start_conversation to: subscribedBiddersWhoAreClose protocol: 'fipa-contract-net' 
				performative: 'inform' contents: [auctionEndedMsg];
		
		auctionStarted <- false;
		write 'The auction of ' + name + ' ended';
	}
	
	reflex endEnglishAuction when: auctionStarted and auctionType = englishAuction 
			and !empty(informs) {
		
		loop msg over: informs {
			list<unknown> contents <- msg.contents;
			if(contents[0] = agreeMsg and contents[1] = currentPrice) {
				write Bidder(msg.sender).name + ' won auction of ' + self.name 
						+ ' and has to pay ' + currentPrice;
				remove msg.sender from: subscribedBiddersWhoAreClose;
				remove msg.sender from: subscribedBidders;
		
				auctionStarted <- false;
				write 'The auction of ' + name + ' ended';
				
				break;
			}
		}
	}
	
	reflex acknowledgeWinnerEnglishAuction when: auctionStarted and auctionType = englishAuction 
			and length(subscribedBiddersWhoAreClose) = 1 and subscribedBiddersWhoAreClose[0] = highestBidder {
		
		do start_conversation to: subscribedBiddersWhoAreClose protocol: 'fipa-contract-net' 
				performative: 'accept_proposal' contents: [proposalAcceptedMsg, currentPrice];
	} 
	
	reflex addAndRemoveAuctionSubscribers when: !empty(subscribes) {
		
		loop s over: subscribes {
			list<unknown> contents <- s.contents;
			
			if(contents[0] = subscribeMsg and contents[1] = auctionId and !(subscribedBidders contains s.sender)) {
				add Bidder(s.sender) to: subscribedBidders;
				//write Bidder(s.sender).name + ' subscribed to the auction of ' + self.name;
				break;
			}
			if(contents[0] = subscribeAndCloseMsg and !(subscribedBiddersWhoAreClose contains s.sender)) {
				add Bidder(s.sender) to: subscribedBiddersWhoAreClose;
				break;
			}
			if(contents[0] = unsubscribeMsg and subscribedBidders contains s.sender) {
				remove Bidder(s.sender) from: subscribedBidders;
				//write Bidder(s.sender).name + ' unsubscribed from the auction of ' + self.name;
			}
			if(contents[0] = unsubscribeMsg and subscribedBiddersWhoAreClose contains s.sender) {
				remove Bidder(s.sender) from: subscribedBiddersWhoAreClose;
			}
		}
	}
	
	reflex handleRefusalsDutchAuction when: auctionStarted and auctionType = dutchAuction 
			and !empty(subscribedBiddersWhoAreClose) and empty(proposes) and !empty(refuses) {
		
		loop refusal over: refuses {
			list<unknown> contents <- refusal.contents;
			
			if(contents[0] = priceTooHighMsg and contents[1] = currentPrice 
					and !(currentRefusals contains Bidder(refusal.sender))) {
				
				add Bidder(refusal.sender) to: currentRefusals;
			}
		}
	}
	
	reflex handleRefusalsEnglishAuction when: auctionStarted and auctionType = englishAuction 
			and !empty(refuses) {
		
		loop refusal over: refuses {
			list<unknown> contents <- refusal.contents;
			
			if(contents[0] = priceTooHighMsg
					and (subscribedBiddersWhoAreClose contains Bidder(refusal.sender))) {
				
				remove Bidder(refusal.sender) from: subscribedBiddersWhoAreClose;
				remove Bidder(refusal.sender) from: subscribedBidders;
			}
		}
	}
	
	reflex handleProposalsDutchAuction when: auctionStarted and auctionType = dutchAuction 
			and !empty(subscribedBiddersWhoAreClose) and !empty(proposes) {
		
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
	
	reflex handleProposalsEnglishAuction when: auctionStarted and auctionType = englishAuction
			and !empty(subscribedBiddersWhoAreClose) and !empty(proposes) {
		
		loop proposal over: proposes {
			list<unknown> contents <- proposal.contents;
			if(contents[0] = priceGoodMsg and int(contents[1]) > currentPrice) {
				currentPrice <- int(contents[1]);
				highestBidder <- proposal.sender;
			}
		}
	}
	
	reflex lowerPriceDutchAuction when: auctionStarted and auctionType = dutchAuction 
			and !empty(subscribedBiddersWhoAreClose) 
			and length(currentRefusals) = length(subscribedBiddersWhoAreClose) {
		
		currentPrice <- currentPrice - priceStep;
		currentRefusals <- [];
		
		if(currentPrice < minimumPriceDutch) {
			do endAuctionMethod;
		}
	}
	
	reflex informBiddersAboutPriceDutchAuction when: auctionStarted and auctionType = dutchAuction 
			and !empty(subscribedBiddersWhoAreClose) and length(currentRefusals) < length(subscribedBiddersWhoAreClose) 
			and length(subscribedBidders) = length(subscribedBiddersWhoAreClose) {
		
		//write self.name + ' informs bidders about current price of ' + currentPrice;
		do start_conversation to: subscribedBiddersWhoAreClose protocol: 'fipa-contract-net' 
				performative: 'cfp' contents: [priceInfoMsg, currentPrice];
	}
	
	reflex informBiddersAboutPriceEnglishAuction when: auctionStarted 
			and auctionType = englishAuction and length(subscribedBiddersWhoAreClose) > 1 
			and length(subscribedBidders) = length(subscribedBiddersWhoAreClose) {
		
		//write self.name + ' informs bidders about current price of ' + currentPrice;
		do start_conversation to: subscribedBiddersWhoAreClose protocol: 'fipa-contract-net' 
				performative: 'cfp' contents: [priceInfoMsg, currentPrice + priceStep];
	}
	
	aspect default {
		draw icon size: 3.5 at: location;
		
		if(displayEntityName) {
			draw string(name) color: #black;	
		}
	}
}

species Bidder skills: [moving, fipa] {
	rgb color <- rgb(80, 80, 255) update: target = nil ? rgb(80, 80, 255) : color;
	
	bool agentMoved <- false;
	
	Auctioneer target <- nil;
	
	string auctionGenreInterested <- any(auctionGenres);
	int maximumPrice <- rnd(65, 90);
	
	reflex randomMove when: target = nil{
		do wander;
		agentMoved <- true;
	}

	reflex moveToTarget when: target != nil 
			and location distance_to(target.location) > 2 {
		do goto target: target.location;
		agentMoved <- true;
	}
	
	reflex subscribeToNewAuction when: target = nil and !empty(informs) {
		
		loop msg over: informs {
			list<unknown> contents <- msg.contents;
			
			if(contents[0] = auctionStartedMsg and contents[2] = auctionGenreInterested) {
				target <- Auctioneer(msg.sender);
				do subscribe message: msg contents: [subscribeMsg, contents[1]];
			}
		}
	}
	
	reflex notifyAboutCloseDistance when: target != nil 
			and location distance_to(target.location) < 3 and agentMoved {
		
		agentMoved <- false;
		
		list<Auctioneer> auctioneerList <- [];
		add target to: auctioneerList;
		do start_conversation to: auctioneerList protocol: 'fipa-contract-net' 
				performative: 'subscribe' contents: [subscribeAndCloseMsg];
	}
	
	reflex unsubscribeFromAuction when: target != nil and !empty(informs) {
		
		loop msg over: informs {
			list<unknown> contents <- msg.contents;
			
			if(contents[0] = auctionEndedMsg) {
				do subscribe message: msg contents: [unsubscribeMsg];
				target <- nil;
			}
		}
	}
	
	reflex reactOnSuggestedPriceDutchAuction when: target != nil 
			and auctionType = dutchAuction and !empty(cfps) 
			and location distance_to(target.location) < 3 {
		
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
	
	reflex reactOnSuggestedPriceEnglishAuction when: target != nil 
			and auctionType = englishAuction and !empty(cfps) 
			and location distance_to(target.location) < 3 {
		
		loop msg over: cfps {
			list<unknown> contents <- msg.contents;
			int suggestedPrice <- int(contents[1]);
		
			if(contents[0] = priceInfoMsg and suggestedPrice <= maximumPrice) {
				do propose message: msg contents: [priceGoodMsg, suggestedPrice];
				//write self.name + ' accepts price ' + (suggestedPrice);
				break;
			}
			do refuse message: msg contents: [priceTooHighMsg, suggestedPrice];
			write self.name + ' refuses price of ' + suggestedPrice;
			target <- nil;
		}
	}
	
	reflex handleAcceptedProposalDutchAuction when: target != nil and auctionType = dutchAuction 
			and !empty(accept_proposals) {
		
		message msg <- accept_proposals[0];
		list<unknown> contents <- msg.contents;
		
		if(contents[0] = proposalAcceptedMsg) {
			do inform message: msg contents: [agreeMsg, contents[1]];
			color <- #orange;
		}
	}
	
	reflex handleAcceptedProposalEnglishAuction when: target != nil 
			and auctionType = englishAuction and !empty(accept_proposals) {
		
		message msg <- accept_proposals[0];
		list<unknown> contents <- msg.contents;
		
		if(contents[0] = proposalAcceptedMsg) {
			do inform message: msg contents: [agreeMsg, contents[1]];
			color <- #orange;
		}
		
		target <- nil;
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
	
	init {
		auctionType <- dutchAuction;
	}
 
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

experiment EnglishAuction type: gui {
	
	init {
		auctionType <- englishAuction;
	}
 
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
