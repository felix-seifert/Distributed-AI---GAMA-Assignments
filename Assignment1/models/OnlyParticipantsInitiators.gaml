/**
* Name: NewModel
* Based on the internal empty template. 
* Author: mrcmlnr
* Tags: 
*/


/**
* Name: NewModel1sub
* Based on the internal empty template. 
* Author: mrcmlnr
* Tags: 
*/


model BasicFestival
 
global {
	
	
	
	point auctionLocation <- {3, 4};
	point shopExample <- {3, 7};
	string informStartAuctionMSG <- 'inform-start-of-auction';
	string informEndAuctionFailedMSG <- 'auction-failed';
	string wonActionMSG <- 'won-auction';
	string lostActionMSG <- 'lost-auction';
	string acceptProposal <-'accepted-proposal';
	string refusedProposal <-'rejected-proposal';
	int nbOfParticipants <- 0;
 
	int gridWidth <- 10;
	int gridHeight <- 10;
	bool displayEntityName <- false;
 
	// Food and beverage attributes for visitors
	float foodMax <- 1.0;
	float foodMin <- 0.0;
	float foodReduction <- 0.003;
	float drinksMax <- 1.0;
	float drinksMin <- 0.0;
	float drinksReduction <- 0.005;
	
	bool allowInteraction <- false;		// allow interaction between Visitors
	bool allowMemory <- false;			// allow usadge of memory
	
	float interactionRate <- 0.1;		// 10% chance of talking with another close Visitor
	float memoryRate <- 0.9; 			// 90% of chance of remembering place just visited
	float communicationDistance <- 3.0;	// distance for communication between agents
	int successfulInteractions <- 0; 	// counter of all the successful memory interactions between two Visitors
	
	float guardRange <- 4.0; 				// range for checking bad behaviours among other Visitors
	int totalBadBehaving <- 0; 				// counter of all bad behaviours
	int totalCaughtBadBehaving <- 0; 		// counter of deaths
	float criminalRate <- 0.013; 			// every Visitor has chance of rnd(0, criminalRate)*100% to commit bad action
 
	int nbInformationCentres <- 1;
	int nbStores <- 4;
	int nbVisitors <- 0;
	int nbGuards <- 0;		// Functionality of bad behaviour gets activated when at least one guard exists.
	int nbParticipants <- 2;
	int nbInitiators <- 1;
 
	bool visitClosestStall <- true;
 
	init {
		int nbFoodStores <- rnd(int(nbStores/4), nbStores - int(nbStores/4));
		int nbDrinksStores <- nbStores - nbFoodStores;
 
		create Participant number: nbParticipants;
		create Initiator number: nbInitiators;
		
	}
}



species Participant skills: [moving, fipa] {
	rgb color <- #green;

	point targetLocation <- nil;
	bool onAction <- false;

	int auctionStep <- 0;
	int maximumPrice <- rnd(70, 85);
	
	reflex random_move when: targetLocation = nil{
		
		do wander;
		
	}

	reflex moveToTarget when: targetLocation != nil {
		
		do goto target: targetLocation;
		
	}
	
	reflex onAuctionArrival when: location distance_to(auctionLocation) < communicationDistance and onAction = false {
		
		targetLocation <- nil;
		
	}
	
	// not sure about this
	reflex auctionStart when: !empty(informs) and auctionStep = 0 {
		
		onAction <- true;
		targetLocation <- shopExample;
		loop message over: informs {
			
			if (message.contents = informStartAuctionMSG){
				
				write name + ' Auction started, ' + string(message.contents);
				auctionStep <- 1;
				
			}
		}
	}
	
	reflex getInitiatorCFP when: !empty(cfps) {

		message proposalFromInitiator <- cfps[0];
		
		list proposedPrices <- proposalFromInitiator.contents;
		
		int proposedPrice <- int(proposedPrices[0]);
		
		write 'CFP by ' + agent(proposalFromInitiator.sender) + '; price: ' + proposedPrice;
		
		if(proposedPrice > maximumPrice) {
			
			write name + ': ' + 'price too high for me';
			do refuse message: proposalFromInitiator contents: [refusedProposal];	

		}
		
		else{
			
			write name + ': price is reasonable';
			do accept_proposal message: proposalFromInitiator contents: [acceptProposal];
				
		}
	}
	
	
	aspect default{
		draw squircle(2.0, 2.0) at: location color: color;
	}
}




species Initiator skills: [fipa] {
	
	int startingPrice <- 100;
	int currentPrice <- 100;
	int priceStep <- 1;
	int minimumPrice <- 50;
	int auctionStep <- 0;
	int participantsBidding <- 0;
	float canStartAuction <- 0.001;
	rgb color <- #purple;
	
	bool auctionStarted <- false;

	reflex startAuction when: (auctionStarted = false) {
		
		auctionStarted <- flip(canStartAuction);
		
		if auctionStarted{
			
			write "Auction open!";
			
			do start_conversation to: list(Participant) protocol: 'fipa-contract-net' performative: 'inform' contents: [ (informStartAuctionMSG)];
			auctionStep <- 1;
			
		}
	}
	
	
	reflex sendCFPToParticipants when: (auctionStep = 1) and (length(Participant at_distance 3) = nbOfParticipants) {
		
		write name + ' sends CFP to everyone: ' + currentPrice;
		do start_conversation to: list(Participant) protocol: 'fipa-contract-net' performative: 'cfp' contents: [currentPrice];
		participantsBidding <- length(Participant);
		auctionStep <- 2;
		
	}


	reflex manageRefuseMessage when: auctionStep = 2 and empty(accept_proposals) and !empty(refuses) and (participantsBidding = (length(refuses))) {
		write name + ' received a refuse';
		write 'Still competing: ' + participantsBidding;
		
		if ((currentPrice - priceStep) >= minimumPrice) {
			currentPrice <- currentPrice - priceStep;
			write name + "Lowered the price to: "+ currentPrice;
			
			//TODO
			loop eachRefuse over: refuses { 
				message refuseByParticipant <- refuses[0];
		 		do cfp message: refuseByParticipant contents: [currentPrice];
			}
		}
		
		else {
			write name + " minimum price reached!";
			
			loop refuseMessage over: refuses { 
				
				message refuseByParticipant <- refuseMessage;
		 	
				do end_conversation message: refuseByParticipant contents: [(informEndAuctionFailedMSG)];
				
			}
		}
		
		
	}
	
	reflex acceptProposalMessages when: !empty(accept_proposals) and auctionStep = 2 and (empty(refuses) and ((length(accept_proposals) = participantsBidding)) or (participantsBidding = (length(accept_proposals)+length(refuses)))) {
		
		auctionStep <- 3;
		
		message firstAccept <- accept_proposals[0];
		
		write agent(firstAccept.sender).name + 'won the bid of ' + name;
		do end_conversation message: firstAccept contents: [(wonActionMSG)];
		
		//send losing message to the others
		
		loop while: !empty(accept_proposals) {
			
			message otheAccepts <- accept_proposals[0];
	 	do end_conversation message: otheAccepts contents: [lostActionMSG];
	 	
		}

		loop while: !empty(refuses) {
			message refusesMSG <- refuses[0];
	 	do end_conversation message: refusesMSG contents: [lostActionMSG];
		}
		
		currentPrice <- startingPrice;
		auctionStarted <- false;
		
		ask Participant {
			
			targetLocation <- auctionLocation + {rnd(-communicationDistance, communicationDistance), rnd(-communicationDistance, communicationDistance)};
			onAction <- false;
			
		}

	}
	
	reflex auctionClosed when: auctionStep = 3 and (!empty(accept_proposals) or !empty(refuses)) {
		
		loop while: !empty(accept_proposals) {
			
			message otheAccepts <- accept_proposals[0];
	 		do end_conversation message: otheAccepts contents: [lostActionMSG];
	 	
		}
		
		loop while: !empty(refuses) { 
			
			message refusesMSG <- refuses[0];
	 		do end_conversation message: refusesMSG contents: [lostActionMSG];
	 	
		}
	}
	
	aspect default {
		draw squircle(2.0, 2.0) at: location color: color;
	}
}





grid FestivalCell width: gridWidth height: gridHeight neighbors: 4 {}
 
experiment Festival type: gui {
 
	parameter "Width of festival grid: " var: gridWidth min: 10 max: 1000 category: "Grid Size";
	parameter "Height of festival grid: " var: gridHeight min: 10 max: 1000 category: "Grid Size";
 
	parameter "Initial number of information centres: " var: nbInformationCentres min: 1 max: 5 category: "Initial Numbers";
	parameter "Initial number of stores: " var: nbStores min: 4 max: 50 category: "Initial Numbers";
	parameter "Initial number of visitors: " var: nbVisitors min: 0 max: 500 category: "Initial Numbers";
	parameter "Initial number of Participant: " var: nbParticipants min: 1 max: 500 category: "Initial Numbers";
	parameter "Initial number of Initiators: " var: nbInitiators min: 1 max: 500 category: "Initial Numbers";
	
	
	parameter "Maximum food storage per visitor: " var: foodMax min: 1.0 max: 50.0 category: "Consumption";
	parameter "Maximum drinks storage per visitor: " var: drinksMax min: 1.0 max: 50.0 category: "Consumption"; 
 
	parameter "Display entity names" var: displayEntityName category: "Options";
	parameter "Visit closes stall (random stall if false)" var: visitClosestStall category: "Options";
	
	parameter "Allow location memory of visitors" var: allowMemory category: "Advanced Options";
	parameter "Allow interaction between visitors" var: allowInteraction category: "Advanced Options";
	parameter "Number of guards" var: nbGuards min: 0 max: 5 category: "Advanced Options";
 
	output {
		display main_display {
			grid FestivalCell lines: #lightgrey;
 
			species Initiator;
			species Participant;
			
		}
	}
}





/////////////////////////////////////////////////


/* Insert your model definition here */



/* Insert your model definition here */

