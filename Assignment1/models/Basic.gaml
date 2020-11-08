/**
* Name: BasicFestival
* Festival with visitors and stores 
* Author: Felix Seifert <mail@felix-seifert.com>
* Tags: 
*/


model BasicFestival

global {
	
	int gridWidth <- 5;
	int gridHeight <- 5;
	
	// Food and beverage attributes for visitors
	float foodMax <- 1.0;
	float foodMin <- 0.0;
	float foodReduction <- 0.001;
	float drinksMax <- 1.0;
	float drinksMin <- 0.0;
	float drinksReduction <- 0.002;
	float interactionRate <- 0.1;
	float memoryRate <- 0.9;
	float forgetRate <- 0.0005;
	float communicationDistance <- 2.0;
	int successfulInteractions <- 0;
	float guardRange <- 4.0;
	int totalBadBehaving <- 0;
	int totalSuccessfulBadBehaving <- 0;
	int totalCaughtBadBehaving <- 0;
	
	int nbInformationCentres <- 2;
	int nbStores <- 20;
	int nbVisitors <- 30;
	int nbGuards <- 15;
	
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
	
	string goodsAvailable;
	
	aspect default {
		if(icon != nil) {
			draw icon size: 3.5 * size;
			draw string(name) color:#black;
			return;
		}
	draw circle(size) at: location color: color;
	}
}

species InformationCentre parent: Stall {
	bool providesInformation <- true;
	image_file icon <- image_file("includes/data/info.png");

	list<FoodStore> foodStores;
	list<DrinksStore> drinksStores;
}

species FoodStore parent: Stall {
	bool sellsFood <- true;
	string goodsAvailable <- "food";
	image_file icon <- image_file("includes/data/food.png");
}

species DrinksStore parent: Stall {
	bool sellsDrinks <- true;
	string goodsAvailable <- "drinks";
	image_file icon <- image_file("includes/data/drinks.png");
}


species Guard skills: [moving] {
	float size <- 1.0;
	image_file icon <- nil;
	list<Visitor> badBehaviourVisitorsOnSight <- [];
	list<Visitor> visitorsOnSight <- [];
	bool goToBadBehaviourVisitor <- false;
	bool followWitnessVisitor <- false;
	
	
//	reflex discoverBadVisitor{
//		if (Visitor at_distance(guardRange) != []){
//			self.visitorsOnSight <- Visitor at_distance(guardRange);
//			
//			loop visitorOnSight over: self.visitorsOnSight{
//				if((visitorOnSight.badBehaviour = true) and !(visitorOnSight in self.badBehaviourVisitorsOnSight)){
//					add visitorOnSight to: self.badBehaviourVisitorsOnSight;
//				}
//				if(self.badBehaviourVisitorsOnSight!=[]){
//					write self.badBehaviourVisitorsOnSight;					
//				}
//			}
//		}
//	}
	
	reflex catchBadVisitor when: (self.badBehaviourVisitorsOnSight!=[]) {
		
		ask self.badBehaviourVisitorsOnSight {
			self.badBehaviourCaught <- true;
			write string(myself) + " is catching " + self;
			myself.goToBadBehaviourVisitor <- true;
			do goto target: self.location;
			write string(self) + " was caught misbehaving by " + string(myself);
		}
	}
	
	reflex reachedBadBehaviourVisitor when: (self.goToBadBehaviourVisitor) {
		write "Suspect caught.";
		
		ask self.badBehaviourVisitorsOnSight[0] {
			self.visitorDie <- true;
			myself.goToBadBehaviourVisitor <- false;
			myself.badBehaviourVisitorsOnSight <- [];
		}
	}
	
	reflex random_move when: !(self.goToBadBehaviourVisitor) {
		do wander;
	}
	
//	reflex escortBadVisitorOut when: 
	
	aspect default {
		draw circle(size+0.25) color:#red;
		draw circle(size) color: #white;
		if (self.goToBadBehaviourVisitor = true){
			draw circle(size) color: #blue;
		}
		draw string(name) color:#black;
	}
}



species Visitor skills: [moving] {
	
	float exploitingMemoryRate <- 0.5;	
	list<Stall> locationMemory;
	bool badBehaviour <- false;
	bool badBehaviourCaught <- false;
	bool visitorDie <- false;
	int stealthRate <- 0;
	float badBehaviourRate <- rnd(-0.010, 0.010);
	bool witnessedBadBehaviour <- false;
	list<Visitor> badBehaviourVisitorsOnSight <- [];
	list<Visitor> visitorsOnSight <- [];
	
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
			update: rgb(80, 80, (255 - (int(145 * (1 - min(foodStorage, drinksStorage))))));
	
	
	reflex reportBadBehaviourToInformationCentre when: self.witnessedBadBehaviour = true {
		targetStall <- InformationCentre closest_to(self);
		write self.name + " is going to report " + self.caughtVisitor.name + " to the information centre";
		if(location distance_to(targetStall.location) < 2)	{
			ask targetStall {
				//
			}
			targetStall <- nil;

			targetGuard <- Guard closest_to(self);	
			write self.name + "is going to report " + self.caughtVisitor.name + " to " + targetGuard.name;
		}
		if(location distance_to(targetGuard.location) < 2) {
			ask targetGuard {
				self.followWitnessVisitor <- true;
				add myself.caughtVisitor to: self.badBehaviourVisitorsOnSight;
			}
			self.targetGuard <- nil;
			do goto target: self.caughtVisitor.location;
		}
		if(location distance_to(caughtVisitor.location) < 2){
			self.caughtVisitor <- nil;
			self.badBehaviourVisitorsOnSight <- [];
			self.witnessedBadBehaviour <- false;
		}
	}
	
	
	reflex caughtVisitorDies when: self.visitorDie = true {
		write self.name + " dies.";
		totalCaughtBadBehaving <- totalCaughtBadBehaving + 1;
		write "Total Caught Bad Behaving :" + totalCaughtBadBehaving;
		self.visitorDie <- false;
		do die;
	}
	
	reflex stopMovementCaughtByGuard when: self.badBehaviourCaught = true {
		self.speed <- 0.0;
		//self.size <- self.size + 2;
	}
	
//	reflex getEscortedOut when: escortedOut = true;
	
	reflex random_move when: foodStorage > 0 and drinksStorage > 0 and !(self.badBehaviourCaught)and !(self.witnessedBadBehaviour) {
		do wander;
	}
	
//	reflex memoryComparison when: targetStall = InformationCentre closest_to(self) and flip(interactionRate){
//		ask Visitor closest_to(self) {
//			write self.locationMemory;
//			write myself.locationMemory;
//			write "The difference is " + string(self.locationMemory - myself.locationMemory);
//		}
//	}
	
	reflex visitKnownStall when: targetStall = nil and self.locationMemory != [] and flip(exploitingMemoryRate) and (foodStorage = 0 or drinksStorage = 0){
		self.exploitingMemoryRate <- max(self.exploitingMemoryRate - 0.1, 0);
		self.targetStall <- self.locationMemory[rnd(length(self.locationMemory) - 1)];
		//write self.exploitingMemoryRate;
	}
	
	reflex discoverBadVisitor{
		if (Visitor at_distance(guardRange) != []){
			self.visitorsOnSight <- Visitor at_distance(guardRange);
			
			loop visitorOnSight over: self.visitorsOnSight{
				if((visitorOnSight.badBehaviour = true) and !(visitorOnSight in self.badBehaviourVisitorsOnSight)){
					add visitorOnSight to: self.badBehaviourVisitorsOnSight;
				}
				if(self.badBehaviourVisitorsOnSight!=[]){
					self.witnessedBadBehaviour <- true;
					self.targetStall <- nil;
					self.targetGuard <- nil;
					self.caughtVisitor <- self.badBehaviourVisitorsOnSight[0];
					write self.name + " discovered " + self.badBehaviourVisitorsOnSight[0] + " bad behaving.";					
				}
			}
		}
	}
	
	reflex interactWithVisitor when: targetStall = InformationCentre closest_to(self) and flip(interactionRate) and (foodStorage = 0 or drinksStorage = 0) and !(self.witnessedBadBehaviour) {
		if (Visitor at_distance(communicationDistance) != []){
			//write (Visitor at_distance(communicationDistance));
			ask (Visitor closest_to(self)) {
				myself.color <- rgb(252, 186, 3);
				if (self.locationMemory - myself.locationMemory != []) {
					add (self.locationMemory - myself.locationMemory)[length(self.locationMemory - myself.locationMemory) - 1] to: myself.locationMemory;
					//write myself.name + " got the location of " + string(myself.locationMemory[length(myself.locationMemory) - 1]) + " from " + self.name;
					myself.targetStall <- myself.locationMemory[length(myself.locationMemory) - 1];
					//write myself.locationMemory;
					//myself.size <- myself.size + 1;
					myself.color <- rgb(252, 107, 3);
					//draw string(length(Visitor at_distance(communicationDistance))) color: #black;
					//draw polyline([self.location, myself.location]) color: rgb(252, 107, 3);
					self.exploitingMemoryRate <- min(self.exploitingMemoryRate + 0.1, 1);
					successfulInteractions <- successfulInteractions + 1;
					//write "Successful interactions: " + successfulInteractions;
					//write self.exploitingMemoryRate;
				}
			}
		}
	}
	
	reflex setTargetPointToInfoCentre when: (foodStorage = 0 or drinksStorage = 0) and targetStall = nil {
		if(visitClosestStall) {
			targetStall <- InformationCentre closest_to(self);
			return;
		}
		targetStall <- one_of(InformationCentre);
	}
	
	reflex moveToTarget when: targetStall != nil or targetGuard != nil or caughtVisitor != nil{
		if targetGuard != nil{
			do goto target: targetGuard;
		}
		if targetStall != nil{
			do goto target: targetStall;			
		}
	}
	
	reflex lowerProfile when: self.stealthRate > 0 {
		self.stealthRate <- max(self.stealthRate - 1, 0);
		if (self.stealthRate = 0) {
			self.badBehaviour <- false;
			write self.name + " didn't get caught.";
			totalSuccessfulBadBehaving <- totalSuccessfulBadBehaving + 1;
			write "Total Successful Bad Behaving :" + totalSuccessfulBadBehaving;
			
		}
	}
	
	reflex interactWithStall when: targetStall != nil and location distance_to(targetStall.location) < 2 {
		
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
				write "Bad Behaviour!";
				totalBadBehaving <- totalBadBehaving + 1;
				write "Total Bad Behaving :" + totalBadBehaving;
				myself.stealthRate <- rnd(10, 30);
			}
			
			if(flip(memoryRate) and !(self in myself.locationMemory)) {
				add self to: myself.locationMemory;
				//write myself.name + " will remember the location of " + string(self);
			}
			
			myself.targetStall <- nil;
			
		}
	}

//	reflex writeMemoryLength {
//		write length(self.locationMemory);
//	}
	
	//reflex forgetLocation when: flip(forgetRate) and locationMemory!=[] {
	//	Stall locationToForget <- locationMemory[rnd(0, length(locationMemory) - 1)];
	//	self.locationMemory <- self.locationMemory - locationToForget;
		//write self.name + " forgot where " + string(locationToForget) + " is located";
	//}
	
	aspect default {
		draw circle(size) color: color;
		draw string(name) color:#black;
	}
}

grid FestivalCell width: gridWidth height: gridHeight neighbors: 4 {}

experiment Festival type: gui {
	
	parameter "Width of festival grid: " var: gridWidth min: 10 max: 1000 category: "Grid Size";
	parameter "Height of festival grid: " var: gridHeight min: 10 max: 1000 category: "Grid Size";
	
	parameter "Initial number of information centres: " var: nbInformationCentres min: 1 max: 5 category: "Initial Numbers";
	parameter "Initial number of stores: " var: nbStores min: 4 max: 50 category: "Initial Numbers";
	parameter "Initial number of visitors: " var: nbVisitors min: 10 max: 500 category: "Initial Numbers";
	parameter "Initial number of guards: " var: nbGuards min: 2 max: 25 category: "Initial Numbers";
	
	parameter "Maximum food storage per visitor: " var: foodMax min: 1.0 max: 50.0 category: "Consumption";
	parameter "Maximum drinks storage per visitor: " var: drinksMax min: 1.0 max: 50.0 category: "Consumption"; 
	
	parameter "Visit closes stall (random stall if false)" var: visitClosestStall category: "Display Options";
	
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
