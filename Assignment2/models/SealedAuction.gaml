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
	string sealedBidAuction <- 'sealed';
	
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
	
	int priceStep <- 1;
	
	float probabilityToStartAuction <- 0.005;
	
	int auctionId <- -1;
	bool auctionStarted <- false;
	int currentPrice <- 101;
	list<Bidder> currentRefusals <- [];
	bool highestBid <- false;
	
	string auctionGenre <- nil;
	list<Bidder> subscribedBidders <- [];
	list<Bidder> subscribedBiddersWhoAreClose <- [];
	
	
	reflex startSealedBidAuction when: auctionType = sealedBidAuction and !auctionStarted and empty(subscribedBidders) and flip(probabilityToStartAuction){
		auctionStarted <- true;
		auctionGenre <- any(auctionGenres);
		currentRefusals <- [];
		currentPrice <- 101;
		
		write name + ' started sealed bid auction with genre ' + auctionGenre;
		
		auctionId <- nextAuctionId;
		nextAuctionId <- nextAuctionId + 1;
			
	}
	

	reflex anounceAuction when: auctionStarted and empty(subscribedBidders) {
		do start_conversation to: list(Bidder) protocol: 'fipa-contract-net' 
				performative: 'inform' contents: [auctionStartedMsg, auctionId, auctionGenre];
	}
	
	
	reflex endSealedBidAuction when: auctionStarted and auctionType = sealedBidAuction and !empty(informs) and highestBid = true and (subscribedBidders - subscribedBiddersWhoAreClose = []) {
		loop msg over: informs {
			list<unknown> contents <- msg.contents;
			if(contents[0] = agreeMsg and contents[1] = currentPrice) {
				write Bidder(msg.sender).name + ' won auction of ' + self.name + ' and has to pay ' + currentPrice;
				remove msg.sender from: subscribedBiddersWhoAreClose;
				remove msg.sender from: subscribedBidders;
				highestBid <- false;
			}
		}
		
		do endAuctionMethod;
	}
	
	
	action endAuctionMethod {
		
		if !(empty(subscribedBiddersWhoAreClose)) {
			do start_conversation to: subscribedBiddersWhoAreClose protocol: 'fipa-contract-net' performative: 'inform' contents: [auctionEndedMsg];
		}		
		
		auctionStarted <- false;
		write 'The auction of ' + name + ' ended';
		write subscribes;
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
	
	
	reflex handleProposalsSealedBidAuction when: auctionStarted and auctionType = sealedBidAuction and !empty(subscribedBiddersWhoAreClose) and !empty(proposes) and highestBid = false {
		currentPrice <- 0;
		list<unknown> contents <- [];
		list<unknown> currentProposes <- proposes;
		
		write proposes;
		
		loop acceptedProposal over: currentProposes {
			contents <- acceptedProposal.contents;
			if(contents[0] = priceGoodMsg and int(contents[1]) > currentPrice) {
				currentPrice <- int(contents[1]);
				write 'The highest bid is ' + currentPrice;
			}
		}
			
		loop acceptedProposal over: currentProposes {
			contents <- acceptedProposal.contents;
			if(contents[0] = priceGoodMsg and int(contents[1]) = currentPrice) {
				write 'accepted!';
				do accept_proposal message: acceptedProposal contents: [proposalAcceptedMsg, currentPrice];	
				highestBid <- true;			
				break;
			}
		}
		
		loop rejectedProposal over: proposes {
			do reject_proposal message: rejectedProposal contents: [proposalRejectedMsg];
		}
	}
	
	
	reflex informBiddersAboutPriceSealedBidAuction when: auctionStarted and auctionType = sealedBidAuction and !empty(subscribedBiddersWhoAreClose) and (subscribedBidders - subscribedBiddersWhoAreClose = []) and highestBid = false {
		
		write self.name + ' informs bidders to make a sealed bid';
		do start_conversation to: subscribedBiddersWhoAreClose protocol: 'fipa-contract-net' 
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
	rgb color <- rgb(80, 80, 255) update: target = nil ? rgb(80, 80, 255) : color;
	
	bool agentMoved <- false;
	
	Auctioneer target <- nil;
	
	string auctionGenreInterested <- any(auctionGenres);
	int maximumPrice <- rnd(65, 90);
	
	bool onAuction <- false;
	
	reflex randomMove when: target = nil{
		do wander;
		agentMoved <- true;
	}

	reflex moveToTarget when: target != nil 
			and location distance_to(target.location) > 2 {
		do goto target: target.location;
		agentMoved <- true;
	}
	
	reflex beIdle when: onAuction = false {
		do wander;
		target <- nil;
	}

	
	reflex subscribeToNewAuction when: target = nil and !empty(informs) and !onAuction {
		
		loop msg over: informs {
			list<unknown> contents <- msg.contents;
			
			if(contents[0] = auctionStartedMsg and contents[2] = auctionGenreInterested) {
				target <- Auctioneer(msg.sender);
				do subscribe message: msg contents: [subscribeMsg, contents[1]];
				onAuction <- true;
				write name + ' subscribed to the auction!';
			}
		}
	}
	
	reflex notifyAboutCloseDistance when: target != nil 
			and location distance_to(target.location) < 2 and agentMoved {
		
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
				write name + ' successfully unsubscribed!';
				do subscribe message: msg contents: [unsubscribeMsg];
				target <- nil;
				onAuction <- false;
			}
		}
	}
	

	reflex reactOnSuggestedPriceSealedBidAuction when: target != nil and auctionType = sealedBidAuction and !empty(cfps) and location distance_to(target.location) < 3 {
		
		loop msg over: cfps {
			list<unknown> contents <- msg.contents;
			
			do propose message: msg contents: [priceGoodMsg, maximumPrice];
			write self.name + ' proposes a price of ' + maximumPrice;
		}
	}

	
	reflex handleAcceptedProposalSealedBidAuction when: target != nil and auctionType = sealedBidAuction and !empty(accept_proposals) {
		
		message msg <- accept_proposals[0];
		list<unknown> contents <- msg.contents;
		
		if(contents[0] = proposalAcceptedMsg) {
			do inform message: msg contents: [agreeMsg, contents[1]];
			color <- #orange;
		}
				
		target <- nil;
		onAuction <- false;
	}

	
	aspect default {
		draw circle(1) at: location color: color;
		
		if(displayEntityName) {
			draw string(name) color: #black;	
		}
	}
}

grid AuctionCell width: gridWidth height: gridHeight neighbors: 4 {}


experiment sealedBidAuction type: gui {
	
	init {
		auctionType <- sealedBidAuction;
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
