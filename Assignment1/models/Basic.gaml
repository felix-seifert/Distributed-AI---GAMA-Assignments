/**
* Name: BasicFestival
* Festival with visitors and stores 
* Author: Felix Seifert <mail@felix-seifert.com>
* Tags: 
*/


model BasicFestival

global {
	
	int gridWidth <- 50;
	int gridHeight <- 50;
	
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
	
	bool visitClosestStall <- true;
	
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
	rgb color <- #red;
	image_file icon <- nil;
	
	bool providesInformation <- false;
	bool sellsFood <- false;
	bool sellsDrinks <- false;
		
	aspect default {
		if(icon != nil) {
			draw icon size: 3.5 * size;
			return;
		}
		draw circle(size) at: location color: color;
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

species Visitor skills: [moving] {
	
	float foodStorage <- rnd(foodMin, foodMax, foodReduction) 
			min: foodMin max: foodMax 
			update: foodStorage - foodReduction;
	float drinksStorage <- rnd(drinksMin, drinksMax, drinksReduction) 
			min: drinksMin max: drinksMax 
			update: drinksStorage - drinksReduction;
	
	Stall targetStall <- nil;
	
	float size <- 0.6;
	rgb color <- rgb(100, 110, (255 - (int(145 * (1 - min(foodStorage, drinksStorage)))))) 
			update: rgb(100, 110, (255 - (int(145 * (1 - min(foodStorage, drinksStorage))))));
	
	reflex random_move when: foodStorage > 0 and drinksStorage > 0 {
		do wander;
	}
	
	reflex setTargetPointToInfoCentre when: (foodStorage = 0 or drinksStorage = 0) and targetStall = nil {
		if(visitClosestStall) {
			targetStall <- InformationCentre closest_to(self);
			return;
		}
		targetStall <- one_of(InformationCentre);
	}
	
	reflex moveToTarget when: targetStall != nil {
		do goto target: targetStall;
	}
	
	reflex interactWithStall when: targetStall != nil and location distance_to(targetStall.location) < 2 {
		
		ask targetStall {
			
			if(self.providesInformation and myself.drinksStorage = 0 and visitClosestStall) {
				myself.targetStall <- DrinksStore closest_to(myself);
				write myself.name + " got location of " + myself.targetStall.name;
				return;
			}
			
			if(self.providesInformation and myself.drinksStorage = 0 and !visitClosestStall) {
				myself.targetStall <- one_of(DrinksStore);
				write myself.name + " got location of " + myself.targetStall.name;
				return;
			}
			
			if(self.providesInformation and myself.foodStorage = 0 and visitClosestStall) {
				myself.targetStall <- FoodStore closest_to(myself);
				write myself.name + " got location of " + myself.targetStall.name;
				return;
			}
			
			if(self.providesInformation and myself.foodStorage = 0 and !visitClosestStall) {
				myself.targetStall <- one_of(FoodStore);
				write myself.name + " got location of " + myself.targetStall.name;
				return;
			}
			
			if(self.sellsFood) {
				myself.foodStorage <- foodMax;
				write myself.name + " replenished foodStorage at " + self.name;
			}
			
			if(self.sellsDrinks) {
				myself.drinksStorage <- drinksMax;
				write myself.name + " replenished drinksStorage at " + self.name;
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
		}
	}
}