/**
* Name: BasicFestival
* Festival with visitors and stores. Visitors get information about location of food and 
* drinks stalls where they then replenish their food and drinks storages.
* Author: Marco Molinari <molinarimarco8@gmail.com>, Felix Seifert <mail@felix-seifert.com>
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
	list<Visitor> criminalVisitors <- [];	// list of reported Visitors
 
	int nbInformationCentres <- 1;
	int nbStores <- 4;
	int nbVisitors <- 0;
	int nbGuards <- 0;		// Functionality of bad behaviour gets activated when at least one guard exists.
	int nbParticipants <- 10;
	int nbInitiators <- 2;
 
	bool visitClosestStall <- true;
 
	init {
		int nbFoodStores <- rnd(int(nbStores/4), nbStores - int(nbStores/4));
		int nbDrinksStores <- nbStores - nbFoodStores;
 
		create InformationCentre number: nbInformationCentres;
		create FoodStore number: nbFoodStores;
		create DrinksStore number: nbDrinksStores;
		create Visitor number: nbVisitors;
		create Guard number: nbGuards;
		create Participant number: nbParticipants;
		create Initiator number: nbInitiators;
 
		loop centre over: list(InformationCentre) {
			centre.foodStores <- list(FoodStore);
			centre.drinksStores <- list(DrinksStore);
		}
	}
}
 
species Stall {
	float size <- 1.0;
	rgb color <- #red;
	image_file icon <- nil;
 
	bool providesInformation <- false;
	bool sellsFood <- false;
	bool sellsDrinks <- false;
 
	aspect default {
		
		if(displayEntityName) {
			draw string(name) color: #black;	
		}
		
		if(icon = nil) {
			draw circle(size) at: location color: color;
			return;
		}
		draw icon size: 3.5 * size;
	}
}
 
species InformationCentre parent: Stall {
	bool providesInformation <- true;
	image_file icon <- image_file("../includes/data/info.png");
 
	list<FoodStore> foodStores;
	list<DrinksStore> drinksStores;
}
 
species FoodStore parent: Stall {
	bool sellsFood <- true;
	image_file icon <- image_file("../includes/data/food.png");
}
 
species DrinksStore parent: Stall {
	bool sellsDrinks <- true;
	image_file icon <- image_file("../includes/data/drinks.png");
}

species Guard skills: [moving] {
	float size <- 1.0;
	
	Visitor witness <- nil;
	
	reflex followWitness when: witness != nil {
		do goto target: witness;
	}
	
	reflex arrestVictim when: witness != nil and witness.caughtVisitor != nil 
			and self distance_to(witness.caughtVisitor) <= 2 {
				
		ask witness.caughtVisitor {
			self.visitorDie <- true;
			myself.witness <- nil;
		}
	}

	reflex random_move when: witness = nil {
		do wander;
	}
 
	aspect default {
		draw circle(size+0.25) color:#red;
		draw circle(size) color: #white;
		
		if (witness != nil){	// Guard changes color if he/she follow witness
			draw circle(size) color: #blue;
		}
		
		if(displayEntityName) {
			draw string(name) color: #black;	
		}
	}
}



/////////////////////////////////////////////////




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
	
	reflex onAuctionArrival when: location distance_to(auctionLocation) < 5.5 and onAction = false {
		
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

		int proposedPrice <- int(proposalFromInitiator.contents);
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
	int currentPrice <- startingPrice;
	int priceStep <- 1;
	int minimumPrice <- 50;
	int auctionStep <- 0;
	int participantsBidding <- 0;
	float canStartAuction <- 0.05;
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





/////////////////////////////////////////////////





species Visitor skills: [moving, fipa] {
	
	float foodStorage <- rnd(foodMin, foodMax, foodReduction) 
			min: foodMin max: foodMax 
			update: foodStorage - foodReduction;
	float drinksStorage <- rnd(drinksMin, drinksMax, drinksReduction) 
			min: drinksMin max: drinksMax 
			update: drinksStorage - drinksReduction;

	Stall targetStall <- nil;
	Guard targetGuard <- nil;
	Visitor caughtVisitor <- nil;
 
	float size <- 0.6;
	// decrease tone of blue with decreasing food/drink storage
	rgb color <- rgb(80, 80, (255 - (int(145 * (1 - min(foodStorage, drinksStorage)))))) 
			update: rgb(80, 80, (255 - (int(145 * (1 - min(foodStorage, drinksStorage))))));
 
	float exploitingMemoryRate <- 0.5;		// how much Visitor relies on its memory about drinks/food stalls
	float exploitingMemoryVariation <- 0.1;	// variation (+,-) for each memory change, depending on use of memory
	
	list<Stall> locationMemory;			// list of memorised locations
	
	bool badBehaviour <- false;			// true for bad behaviour of Visitor
	float badBehaviourRate <- rnd(-criminalRate/4, criminalRate);
	
	bool visitorDie <- false;
	
	
	
	/*
	 * Search for badly behaving visitors in surroundings
	 */
	reflex discoverBadVisitor when: caughtVisitor = nil and nbGuards > 0 {
			
		loop visitorOnSight over: Visitor at_distance(guardRange) {
			
			if((visitorOnSight.badBehaviour = true)){
				caughtVisitor <- visitorOnSight;
				targetStall <- InformationCentre closest_to(self);
				//write string(self) + " discovered " + string(visitorOnSight) + " behaving badly.";
				break;
			}
		}
	}
	
	reflex goToInformationCentreToReport when: caughtVisitor != nil and targetStall != nil 
			and location distance_to(targetStall) < 2.0 and nbGuards > 0 {
		
		targetStall <- nil;
		
		// if criminal was already reported, free Visitor
		if(caughtVisitor in criminalVisitors or dead(caughtVisitor)) {
			caughtVisitor <- nil;
			return;
		}
			
		add caughtVisitor to: criminalVisitors;
		targetGuard <- one_of(Guard);
		//write string(self) + " reported " + string(caughtVisitor) + " to an information centre.";
	}
	
	reflex goToGuardToReport when: targetGuard != nil and nbGuards > 0 
				and targetGuard.witness = nil 
				and location distance_to(targetGuard) < communicationDistance {
			
		ask targetGuard {
			self.witness <- myself;
		}
		
		targetGuard <- nil;
		//write string(self) + " reported " + string(caughtVisitor) + " to " + string(targetGuard) + ".";
	}
	
	/*
	 * Stop following the guard once the arrest is done
	 */
	reflex stopHelpingGuard when: caughtVisitor != nil and dead(caughtVisitor) and nbGuards > 0 {
		caughtVisitor <- nil;
	}
	
	reflex caughtVisitorDies when: self.visitorDie = true {
		write string(self) + " got removed from festival.";
		totalCaughtBadBehaving <- totalCaughtBadBehaving + 1;
		//write "Total caught visitors with bad behaviour: " + totalCaughtBadBehaving;
		do die;
	}
	
	reflex random_move when: foodStorage > 0 and drinksStorage > 0 and caughtVisitor = nil {
		do wander;
	}
	
	reflex moveToTarget when: targetStall != nil or targetGuard != nil or caughtVisitor != nil {
		
		if(targetStall != nil) {
			do goto target: targetStall;
			return;	
		}

		if(targetGuard != nil and caughtVisitor != nil) {
			do goto target: targetGuard;
			return;
		}
		
		if(caughtVisitor != nil and targetGuard = nil and targetStall = nil) {
			do goto target: caughtVisitor;
		}
	}
	
	reflex setTargetPointToKnownStall when: (foodStorage = 0 or drinksStorage = 0) 
			and targetStall = nil and caughtVisitor = nil 
			and allowMemory and self.locationMemory != [] and flip(exploitingMemoryRate) {
		
		self.exploitingMemoryRate <- max(self.exploitingMemoryRate - exploitingMemoryVariation, 0);
		self.targetStall <- self.locationMemory[rnd(length(self.locationMemory) - 1)]; // pick one random location memory as new destination
	}
 
	reflex setTargetPointToInfoCentre when: (foodStorage = 0 or drinksStorage = 0) 
			and targetStall = nil and caughtVisitor = nil {
				
		if(visitClosestStall) {
			targetStall <- InformationCentre closest_to(self);
			return;
		}
		targetStall <- one_of(InformationCentre);
	}
	
	reflex interactWithTargetStall when: targetStall != nil and location distance_to(targetStall.location) < 2 
			and caughtVisitor = nil {
 
		ask targetStall {
 
			if(self.providesInformation and myself.drinksStorage = 0 and visitClosestStall) {
				myself.targetStall <- DrinksStore closest_to(myself);
				//write myself.name + " got location of " + myself.targetStall.name;
				return;
			}
 
			if(self.providesInformation and myself.drinksStorage = 0 and !visitClosestStall) {
				myself.targetStall <- one_of(DrinksStore);
				//write myself.name + " got location of " + myself.targetStall.name;
				return;
			}
 
			if(self.providesInformation and myself.foodStorage = 0 and visitClosestStall) {
				myself.targetStall <- FoodStore closest_to(myself);
				//write myself.name + " got location of " + myself.targetStall.name;
				return;
			}
 
			if(self.providesInformation and myself.foodStorage = 0 and !visitClosestStall) {
				myself.targetStall <- one_of(FoodStore);
				//write myself.name + " got location of " + myself.targetStall.name;
				return;
			}
 
			if(self.sellsFood) {
				myself.foodStorage <- foodMax;
				//write myself.name + " replenished foodStorage at " + self.name;
			}
 
			if(self.sellsDrinks) {
				myself.drinksStorage <- drinksMax;
				//write myself.name + " replenished drinksStorage at " + self.name;
			}
 
			if(flip(myself.badBehaviourRate) and nbGuards > 0) {
				myself.badBehaviour <- true;
				myself.color <- rgb(255, 0, 234);
				totalBadBehaving <- totalBadBehaving + 1;
				write "Total bad behaving visitors: " + totalBadBehaving;
			}
 
			if(flip(memoryRate) and !(self in myself.locationMemory)) {
				add self to: myself.locationMemory;
				//write myself.name + " will remember the location of " + string(self);
			}
 
			myself.targetStall <- nil;
 
		}
	}
 
	reflex interactWithOtherVisitor when: targetStall != nil and targetStall.providesInformation 
			and allowInteraction and flip(interactionRate) and caughtVisitor = nil 
			and Visitor at_distance(communicationDistance) != [] {

		ask (Visitor closest_to(self)) {
			
			myself.color <- rgb(252, 186, 3);	// Visitor becomes yellow when interact with another Visitor
			
			if (self.locationMemory - myself.locationMemory != []) {
				// Difference between two memories can be learnt
				
				add (self.locationMemory - myself.locationMemory)[length(self.locationMemory - myself.locationMemory) - 1] 
						to: myself.locationMemory;
				//write myself.name + " learnt location of " + string(myself.locationMemory[length(myself.locationMemory) - 1]) + " from " + self.name;
				
				myself.targetStall <- myself.locationMemory[length(myself.locationMemory) - 1];	// improves memory parameter for next choices

				myself.color <- rgb(252, 107, 3);	// Visitor becomes orange if it receives new location
				//draw polyline([self.location, myself.location]) color: rgb(252, 107, 3);
				
				self.exploitingMemoryRate <- min(self.exploitingMemoryRate + exploitingMemoryVariation, 1);
				successfulInteractions <- successfulInteractions + 1;
				//write "Successful interactions: " + successfulInteractions;
			}
		}
	}
 
	aspect default {
		draw circle(size) color: color;
		
		if(displayEntityName) {
			draw string(name) color: #black;	
		}
	}
}
 
grid FestivalCell width: gridWidth height: gridHeight neighbors: 4 {}
 
experiment Festival type: gui {
 
	parameter "Width of festival grid: " var: gridWidth min: 10 max: 1000 category: "Grid Size";
	parameter "Height of festival grid: " var: gridHeight min: 10 max: 1000 category: "Grid Size";
 
	parameter "Initial number of information centres: " var: nbInformationCentres min: 1 max: 5 category: "Initial Numbers";
	parameter "Initial number of stores: " var: nbStores min: 4 max: 50 category: "Initial Numbers";
	parameter "Initial number of visitors: " var: nbVisitors min: 0 max: 500 category: "Initial Numbers";
	parameter "Initial number of Participant: " var: nbParticipants min: 10 max: 500 category: "Initial Numbers";
	parameter "Initial number of Initiators: " var: nbInitiators min: 10 max: 500 category: "Initial Numbers";
	
	
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
 
			species InformationCentre;
			species FoodStore;
			species DrinksStore;
			species Visitor;
			species Guard;
		}
	}
}
