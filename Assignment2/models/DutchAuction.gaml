/**
* Name: Auctions
* Model with several dutch auctions which pop up every now and then. Potential bidders get 
* informed about auctions which start and can participate in them. 
* Author: Marco Molinari <molinarimarco8@gmail.com>, Felix Seifert <mail@felix-seifert.com>
*/


model DutchAuction

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
	string closeMsg <- 'agent-close';	// Sent when agent is close to target
	
	string priceInfoMsg <- 'price-info';
	
	string priceGoodMsg <- 'price-good';
	string priceTooHighMsg <- 'price-too-high';
	
	string proposalAcceptedMsg <-'accepted-proposal';
	string proposalRejectedMsg <-'rejected-proposal';
	
	string agreeMsg <- 'agree';
	
	string clothesGenre <- 'clothes';
	string jewelryGenre <- 'jewelry';
	string recordingsGenre <- 'recordings';
	string accessoriesGenre <- 'accessories';
	list<string> auctionGenres <- [clothesGenre, jewelryGenre, recordingsGenre, accessoriesGenre];
	
	init {
		create Auctioneer number: nbAuctioneers;
		create Bidder number: nbBidders;
	}
}

species Auctioneer skills: [fipa] {
	image_file icon <- image_file('../includes/data/auctioneer.png');
	
	int startingPrice <- 100;
	int minimumPrice <- 50;
	int priceStep <- 1;
	
	float probabilityToStartAuction <- 0.05;
	
	int auctionStep <- 0;		// auctionStep guides reflexes through different auction phases
	int currentPrice <- -1;		// currentPrice gets resetted at beginning of each auction
	list<Bidder> currentRefusals <- [];
	
	string auctionGenre <- nil;	// Each auction has genre. Maximum one auction per genre 
								// by removing current auctionGenre from list auctionGenres.
	list<Bidder> subscribedBidders <- [];
	int nbOfCloseSubscribers <- 0;
	
	reflex startAuction when: auctionStep = 0 and !empty(auctionGenres) 
			and flip(probabilityToStartAuction) {
		
		auctionGenre <- any(auctionGenres);
		remove auctionGenre from: auctionGenres;
		subscribedBidders <- [];
		nbOfCloseSubscribers <- 0;
		
		currentPrice <- startingPrice;
		currentRefusals <- [];
		
		write name + ' started Dutch auction with genre ' + auctionGenre 
				+ ' and starting price of ' + currentPrice;
		
		do start_conversation to: list(Bidder) protocol: 'fipa-contract-net' 
				performative: 'inform' contents: [auctionStartedMsg, auctionGenre];
		
		auctionStep <- 1;
	}
	
	reflex addAuctionSubscribers when: auctionStep = 1 and !empty(subscribes) {
		
		loop s over: subscribes {
			list<unknown> c <- s.contents;
			
			if(c[0] = subscribeMsg) {
				add Bidder(s.sender) to: subscribedBidders;
				//write Bidder(s.sender).name + ' subscribed to the auction of ' + self.name;
			}
		}
	}
	
	reflex registerCloseBidders when: auctionStep = 1 and !empty(informs) 
			and empty(subscribes) {
				
		loop msg over: informs {
			list<unknown> c <- msg.contents;
			
			if(c[0] = closeMsg) {
				nbOfCloseSubscribers <- nbOfCloseSubscribers + 1;
			}
		}
		
		if(nbOfCloseSubscribers = length(subscribedBidders)) {
			auctionStep <- 2;
		}
	}
	
	reflex informBiddersAboutPrice when: auctionStep = 2 {
		
		//write self.name + ' informs bidders about current price of ' + currentPrice;
		do start_conversation to: subscribedBidders protocol: 'fipa-contract-net' 
				performative: 'cfp' contents: [priceInfoMsg, currentPrice];
		
		auctionStep <- 3;
	}
	
	reflex handleRefusals when: auctionStep = 3 and empty(proposes) {
		
		loop r over: refuses {
			list<unknown> c <- r.contents;
			
			if(c[0] = priceTooHighMsg and c[1] = currentPrice
					and !(currentRefusals contains r.sender)) {
				add Bidder(r.sender) to: currentRefusals;
			}
		}
	}
	
	reflex lowerPrice when: auctionStep = 3 
			and length(currentRefusals) = length(subscribedBidders) {
		
		currentPrice <- currentPrice - priceStep;
		currentRefusals <- [];
		
		if(currentPrice < minimumPrice) {
			do informAboutEndedAuction;
			return;
		}
		
		auctionStep <- 2;
	}
	
	reflex handleProposals when: auctionStep = 3 and !empty(proposes) {
		
		loop acceptedProposal over: proposes {
			list<unknown> c <- acceptedProposal.contents;
			
			if(c[0] = priceGoodMsg and c[1] = currentPrice) {
				do accept_proposal message: acceptedProposal
						contents: [proposalAcceptedMsg, currentPrice];
				break;
			}
		}
		
		loop rejectedProposal over: proposes {
			do reject_proposal message: rejectedProposal contents: [proposalRejectedMsg];
		}
		
		auctionStep <- 4;
	}
	
	reflex acknowledgeWinner when: auctionStep = 4 and !empty(informs) {
		
		loop msg over: informs {
			list<unknown> c <- msg.contents;
			
			if(c[0] = agreeMsg and c[1] = currentPrice) {
				write Bidder(msg.sender).name + ' won auction of ' + self.name 
						+ ' and has to pay ' + currentPrice;
			}
		}
		
		do informAboutEndedAuction;
	}
	
	action informAboutEndedAuction {
		do start_conversation to: subscribedBidders protocol: 'fipa-contract-net' 
				performative: 'inform' contents: [auctionEndedMsg];
		
		auctionStep <- 5;
	}
	
	reflex removeAuctionSubscribers when: auctionStep = 5 and !empty(subscribes) {
		
		loop s over: subscribes {
			list<unknown> c <- s.contents;
			
			if(c[0] = unsubscribeMsg) {
				remove s.sender from: subscribedBidders;
				//write Bidder(s.sender).name + ' unsubscribed from the auction of ' + self.name;
			}
		}
	}
	
	reflex endAuction when: auctionStep = 5 and empty(subscribedBidders) {
		
		add auctionGenre to: auctionGenres;
		write 'Auction of ' + name + ' ended';
		auctionStep <- 0;
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
	
	bool registeredClose <- false;
	
	Auctioneer target <- nil;
	
	string auctionGenreInterested <- any(auctionGenres);
	int maximumPrice <- rnd(65, 90);
	
	reflex randomMove when: target = nil {
		do wander;
	}

	reflex moveToTarget when: target != nil 
			and location distance_to(target.location) > 2 {
		do goto target: target.location;
	}
	
	reflex findNewAuction when: target = nil and !empty(informs) {
		
		loop msg over:informs {
			list<unknown> c <- msg.contents;
			
			if(c[0] = auctionStartedMsg and c[1] = auctionGenreInterested) {
				target <- Auctioneer(msg.sender);
				do subscribe message: msg contents: [subscribeMsg];
			}
		}
	}
	
	reflex notifyAboutCloseDistance when: target != nil 
			and self.location distance_to target.location < 3 and !registeredClose {
		
		registeredClose <- true;
		
		list<Auctioneer> recipientList <- [target];
		do start_conversation to: recipientList protocol: 'fipa-contract-net' 
				performative: 'inform' contents: [closeMsg];
	}
	
	reflex reactOnSuggestedPrice when: target != nil and !empty(cfps) 
			and self.location distance_to target.location < 3 {
		
		loop msg over: cfps {
			list<unknown> c <- msg.contents;
			int suggestedPrice <- int(c[1]);
			
			if(c[0] = priceInfoMsg and suggestedPrice <= self.maximumPrice) {
				do propose message: msg contents: [priceGoodMsg, suggestedPrice];
				write self.name + ' accepts price of ' + suggestedPrice;
				break;
			}
			if(c[0] = priceInfoMsg) {
				do refuse message: msg contents: [priceTooHighMsg, suggestedPrice];
				//write self.name + ' refuses price of ' + suggestedPrice;
			}
		}
	}
	
	reflex handleAcceptedProposal when: target != nil and !empty(accept_proposals) {
		
		loop msg over: accept_proposals {
			list<unknown> c <- msg.contents;
			
			if(c[0] = proposalAcceptedMsg) {
				do inform message: msg contents: [agreeMsg, c[1]];
				color <- #orange;
			}
		}
	}
	
	reflex unsubscribeFromAuction when: target != nil and !empty(informs) {
		
		loop msg over: informs {
			list<unknown> c <- msg.contents;
			
			if(c[0] = auctionEndedMsg) {
				do subscribe message: msg contents: [unsubscribeMsg];
				target <- nil;
				registeredClose <- false;
			}
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

