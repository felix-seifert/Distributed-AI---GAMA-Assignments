/**
* Name: BasicFestival
* Festival with visitors and stores 
* Author: Felix Seifert <mail@felix-seifert.com>
* Tags: 
*/
 
 
model BasicFestival
 
global {
 
	int gridWidth <- 4;
	int gridHeight <- 4;
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
	float criminalRate <- 0.003; 			// every Visitor has chance of rnd(0, criminalRate)*100% to commit bad action
	list<Visitor> criminalVisitors <- [];	// list of reported Visitors
 
	int nbInformationCentres <- 1;
	int nbStores <- 4;
	int nbVisitors <- 10;
	int nbGuards <- 1;
 
	bool visitClosestStall <- true;
 
	init {
		int nbFoodStores <- rnd(int(nbStores/4), nbStores - int(nbStores/4));
		int nbDrinksStores <- nbStores - nbFoodStores;
 
		create InformationCentre number: nbInformationCentres;
		create FoodStore number: nbFoodStores;
		create DrinksStore number: nbDrinksStores;
		create Visitor number: nbVisitors;
		create Guard number: nbGuards;
 
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
	
	list<Visitor> badBehaviourVisitorsOnSight <- [];	// list of bad behaving Visitors in guardRange
	list<Visitor> visitorsOnSight <- []; 				// list of all Visitors in guardRange
	
	bool followWitnessVisitor <- false;		// true if Guard follows Visitor who is reporting another Visitor
	bool goToBadBehaviourVisitor <- false; 	// true if Guard heads to capture criminal Visitor

 
	reflex identifyBadBehaviourVisitor when: (followWitnessVisitor = true and badBehaviourVisitorsOnSight!=[]) { //identify the suspect
 
		ask self.badBehaviourVisitorsOnSight {
			
			self.badBehaviourCaught <- true;
			
			//write string(myself) + " identified " + string(self);
			
			myself.goToBadBehaviourVisitor <- true;
		}
		
		followWitnessVisitor <- false;
	}
	
	
	reflex moveToTarget when: goToBadBehaviourVisitor = true { //get closer to the suspect
		
		if (self distance_to(badBehaviourVisitorsOnSight[0]) > 2.0) {
			do goto target: badBehaviourVisitorsOnSight[0];
		}
		
		else{
			
			//write string(badBehaviourVisitorsOnSight[0]) + " was caught misbehaving by " + string(self);
			goToBadBehaviourVisitor <- false;
			
			ask self.badBehaviourVisitorsOnSight[0] {
				self.visitorDie <- true; //if true, triggers the considered Visitor to leave the simulation
				myself.badBehaviourVisitorsOnSight <- []; //empties the list of criminals and restart
				
			}			
		}
	}

	reflex random_move when: !(self.goToBadBehaviourVisitor) {
		do wander;
	}
 
	aspect default {
		draw circle(size+0.25) color:#red;
		draw circle(size) color: #white;
		
		if (self.goToBadBehaviourVisitor = true){ // Guard changes color if Visitor approaches
			draw circle(size) color: #blue;
		}
		
		if(displayEntityName) {
			draw string(name) color: #black;	
		}
	}
}

species Visitor skills: [moving] {
	
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
	rgb color <- rgb(80, 80, (255 - (int(145 * (1 - min(foodStorage, drinksStorage)))))) 
			update: rgb(80, 80, (255 - (int(145 * (1 - min(foodStorage, drinksStorage))))));	//decrease tone of blue with rising food/drink necessity
 
	float exploitingMemoryRate <- 0.5;		// how much Visitor relies on its memory about drinks/food stalls
	float exploitingMemoryVariation <- 0.1;	// variation (+,-) for each memory change, depending on use of memory
	
	list<Stall> locationMemory;		// list of memorised locations
	
	bool badBehaviour <- false;			// true for bad behaviour of Visitor
	float badBehaviourRate <- rnd(-criminalRate/4, criminalRate);
	
	bool badBehaviourCaught <- false; 		// true if Visitor gets caught by another Visitor
	bool witnessedBadBehaviour <- false; 	// true if Visitor witnessed bad behaviour of another Visitor
	
	bool visitorDie <- false;
	
	bool goingToInformationCentreToReport <- false;
	bool goingToGuardToReport <- false;
	bool goingToBadBehaviourVisitorToReport <- false;
	
	/*
	 * Search for badly behaving visitors in surroundings
	 */
	reflex discoverBadVisitor when: !(self.witnessedBadBehaviour) {
		
		if (Visitor at_distance(guardRange) != []) {
			
			loop visitorOnSight over: Visitor at_distance(guardRange) {
				
				if((visitorOnSight.badBehaviour = true)){
					caughtVisitor <- visitorOnSight;
					witnessedBadBehaviour <- true;
					goingToInformationCentreToReport <- true;
					//write string(self) + " discovered " + string(visitorOnSight) + " behaving badly.";
					break;
				}
			}
		}
	}
	
	reflex goToInformationCentreToReport when: goingToInformationCentreToReport = true {
		targetGuard <- nil;
		targetStall <- InformationCentre closest_to(self);
		
		if (location distance_to(targetStall) < 2.0){
			goingToInformationCentreToReport <- false;
			goingToGuardToReport <- true;
			
			if caughtVisitor in criminalVisitors or dead(caughtVisitor) { //if criminal was already reported, free the Visitor
				
				caughtVisitor <- nil;
				targetGuard <- nil;
				witnessedBadBehaviour <- false;				
				goingToGuardToReport <- false;
				goingToInformationCentreToReport <- false;
				goingToBadBehaviourVisitorToReport <- false;
				
				return;
			}
				
			add caughtVisitor to: criminalVisitors;
			//write string(self) + " reported " + string(caughtVisitor) + " to an information centre.";
		}
	}
	
	reflex goToGuardToReport when: goingToGuardToReport = true {
		targetStall <- nil;
		targetGuard <- one_of(Guard);
		
		if (targetGuard.badBehaviourVisitorsOnSight = []) {
			if (location distance_to(targetGuard) < communicationDistance) {
				
				ask targetGuard {
					self.followWitnessVisitor <- true;
					add myself.caughtVisitor to: self.badBehaviourVisitorsOnSight;
				}
				
				goingToGuardToReport <- false;
				goingToBadBehaviourVisitorToReport <- true;
				//write string(self) + " reported " + string(caughtVisitor) + " to " + string(targetGuard) + ".";
			}	
		}
	}
	
	/*
	 * Stop following the guard once the arrest is done
	 */
	reflex stopHelpingGuard when: caughtVisitor != nil and dead(caughtVisitor) {
		caughtVisitor <- nil;
		targetGuard <- nil;
		witnessedBadBehaviour <- false;
		goingToBadBehaviourVisitorToReport <- false; //true if the Visitor is following the Guard to show the criminal's position
	}
	
	reflex caughtVisitorDies when: self.visitorDie = true {
		write string(self) + " dies.";
		totalCaughtBadBehaving <- totalCaughtBadBehaving + 1;
		//write "Total caught visitors with bad behaviour: " + totalCaughtBadBehaving;
		self.visitorDie <- false;
		badBehaviour <- false;
		do die;
	}
	
	reflex random_move when: foodStorage > 0 and drinksStorage > 0 
			and !(self.badBehaviourCaught) and !(self.witnessedBadBehaviour) {
		do wander;
	}
	
	reflex moveToTarget when: targetStall != nil or targetGuard != nil or caughtVisitor != nil {
		
		if(targetStall != nil) {
			do goto target: targetStall;			
		}

		if(targetGuard != nil and witnessedBadBehaviour) {
			do goto target: targetGuard;
		}
		
		if(caughtVisitor != nil and goingToBadBehaviourVisitorToReport = true) {
			do goto target: caughtVisitor;
			targetGuard <- nil;
		}
	}
	
	reflex setTargetPointToKnownStall when: (foodStorage = 0 or drinksStorage = 0) 
			and targetStall = nil and !(self.witnessedBadBehaviour) 
			and allowMemory and self.locationMemory != [] and flip(exploitingMemoryRate) {
		
		self.exploitingMemoryRate <- max(self.exploitingMemoryRate - exploitingMemoryVariation, 0);
		self.targetStall <- self.locationMemory[rnd(length(self.locationMemory) - 1)]; // pick one random location memory as new destination
	}
 
	reflex setTargetPointToInfoCentre when: (foodStorage = 0 or drinksStorage = 0) 
			and targetStall = nil and !(self.witnessedBadBehaviour) {
				
		if(visitClosestStall) {
			targetStall <- InformationCentre closest_to(self);
			return;
		}
		targetStall <- one_of(InformationCentre);
	}
	
	reflex interactWithTargetStall when: targetStall != nil and location distance_to(targetStall.location) < 2 
			and !(self.witnessedBadBehaviour) {
 
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
 
			if(flip(myself.badBehaviourRate)) {
				myself.badBehaviour <- true;
				myself.color <- rgb(255, 0, 234);
				//write "Bad Behaviour!";
				totalBadBehaving <- totalBadBehaving + 1;
				write "Total Bad Behaving :" + totalBadBehaving;
			}
			
//			if(myself.badBehaviour = true) {
//				myself.badBehaviour <- false;
//			}
 
			if(flip(memoryRate) and !(self in myself.locationMemory)) {
				add self to: myself.locationMemory;
				//write myself.name + " will remember the location of " + string(self);
			}
 
			myself.targetStall <- nil;
 
		}
	}
 
	reflex interactWithOtherVisitor when: targetStall != nil and targetStall.providesInformation 
			and allowInteraction and flip(interactionRate) and !(self.witnessedBadBehaviour) {
		
		// interaction between Visitors to exchange missing information about stalls locations
		if (Visitor at_distance(communicationDistance) != []){

			ask (Visitor closest_to(self)) {
				
				myself.color <- rgb(252, 186, 3);	// Visitor becomes yellow when interact with another Visitor
				
				if (self.locationMemory - myself.locationMemory != []) {
					// Difference in between two memories can be learnt
					
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
	parameter "Initial number of visitors: " var: nbVisitors min: 10 max: 500 category: "Initial Numbers";
	parameter "Initial number of guards: " var: nbGuards min: 1 max: 25 category: "Initial Numbers";
 
	parameter "Maximum food storage per visitor: " var: foodMax min: 1.0 max: 50.0 category: "Consumption";
	parameter "Maximum drinks storage per visitor: " var: drinksMax min: 1.0 max: 50.0 category: "Consumption"; 
 
	parameter "Display entity names" var: displayEntityName category: "Display Options";
	parameter "Visit closes stall (random stall if false)" var: visitClosestStall category: "Display Options";
	
	parameter "Allow location memory of visitors" var: allowMemory category: "Advanced Options";
	parameter "Allow interaction between visitors" var: allowInteraction category: "Advanced Options";
 
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
