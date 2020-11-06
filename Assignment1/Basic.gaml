/**
* Name: BasicFestival
* Festival with visitors and stores 
* Author: Felix Seifert <mail@felix-seifert.com>
* Tags: 
*/


model BasicFestival

global {
	
	int gridWidth <- 100;
	int gridHeight <- 100;
	
	// Food and beverage attributes for visitors
	float foodMax <- 1.0;
	float foodMin <- 0.0;
	float foodReduction <- 0.01;
	float drinksMax <- 1.0;
	float drinksMin <- 0.0;
	float drinksReduction <- 0.02;
	
	int nbInformationCentres <- 1;
	int nbStores <- 4;
	int nbVisitors <- 10;
	
	init {
		int nbFoodStores <- rnd(int(nbStores/4), nbStores - int(nbStores/4));
		int nbDrinksStores <- nbStores - nbFoodStores;
		
		create InformationCentre number: nbInformationCentres;
		create FoodStore number: nbFoodStores;
		create DrinksStore number: nbDrinksStores;
		create Visitor number: nbVisitors;
		
		loop centre over: list(InformationCentre) {
			centre.foodStores <- list(FoodStore);
			centre.drinksStores <- list(DrinksStore);
		}
	}
}

species Stall {
	float size <- 1.0;
	rgb color <- #white;
	
	bool providesInformation <- false;
	bool sellsFood <- false;
	bool sellsDrinks <- false;
		
	aspect default {
		draw circle(size) at: location color: color;
	}
}

species InformationCentre parent: Stall {
	bool providesInformation <- true;
	rgb color <- #red;
	
	list<FoodStore> foodStores;
	list<DrinksStore> drinksStores;
}

species FoodStore parent: Stall {
	bool sellsFood <- true;
	rgb color <- #orange;
}

species DrinksStore parent: Stall {
	bool sellsDrinks <- true;
	rgb color <- #yellow;
}

species Visitor skills: [moving] {
	
	float foodStorage <- rnd(foodMin, foodMax, foodReduction) min: foodMin max: foodMax update: foodStorage - foodReduction;
	float drinksStorage <- rnd(drinksMin, drinksMax, drinksReduction) min: drinksMin max: drinksMax update: drinksStorage - drinksReduction;
	
	Stall targetStall <- nil;
	
	float size <- 0.8;
	rgb color <- rgb(100, 110, (255 - (int(145 * (1 - min(foodStorage, drinksStorage)))))) 
			update: rgb(100, 110, (255 - (int(145 * (1 - min(foodStorage, drinksStorage))))));
	
	reflex random_move when: foodStorage > 0 and drinksStorage > 0 {
		do wander;
	}
	
	reflex setTargetPointToInfoCentre when: (foodStorage = 0 or drinksStorage = 0) and targetStall = nil {
		targetStall <- InformationCentre closest_to(self);
	}
	
	reflex moveToTarget when: targetStall != nil {
		do goto target: targetStall;
	}
	
	reflex interactWithStall when: targetStall != nil and location distance_to(targetStall.location) < 2 {
		
		ask targetStall {
			
			if(self.providesInformation and myself.drinksStorage = 0) {
				myself.targetStall <- DrinksStore closest_to(myself);
				return;
			}
			
			if(self.providesInformation and myself.foodStorage = 0) {
				myself.targetStall <- FoodStore closest_to(myself);
				return;
			}
			
			if(self.sellsFood) {
				myself.foodStorage <- foodMax;
			}
			
			if(self.sellsDrinks) {
				myself.drinksStorage <- drinksMax;
			}
			
			myself.targetStall <- nil;
		}
	}
	
	aspect default {
		draw circle(size) color: color;
	}
}

grid FestivalCell width: gridWidth height: gridHeight neighbors: 4 {}

experiment Festival type: gui {
	
	parameter "Width of festival grid: " var: gridWidth min: 10 max: 1000 category: "Grid Size";
	parameter "Height of festival grid: " var: gridHeight min: 10 max: 1000 category: "Grid Size";
	
	parameter "Initial number of information centres: " var: nbInformationCentres min: 1 max: 5 category: "Initial Numbers";
	parameter "Initial number of stores: " var: nbStores min: 4 max: 50 category: "Initial Numbers";
	parameter "Initial number of visitors: " var: nbVisitors min: 10 max: 500 category: "Initial Numbers";
	
	output {
		display main_display {
			grid FestivalCell lines: #lightgrey;
			
			species InformationCentre;
			species FoodStore;
			species DrinksStore;
			species Visitor;
		}
	}
}