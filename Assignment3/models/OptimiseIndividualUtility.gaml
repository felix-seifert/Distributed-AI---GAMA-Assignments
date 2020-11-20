/**
* Name: OptimiseIndividualUtility
* Model in which guests optimise their own utility with deciding on which concert stage to visit. 
* Author: Marco Molinari <molinarimarco8@gmail.com>, Felix Seifert <mail@felix-seifert.com>
*/


model OptimiseIndividualUtility

global {
 
	int gridWidth <- 10;
	int gridHeight <- 10;
	bool displayEntityName <- false;
	
	int nbStages <- 4;
	int nbGuests <- 4;
	
	string requestAttributesMsg <- 'request-attributes';
	string provideAttributesMsg <- 'provide-attributes';
	
	string requestPlaceMsg <- 'request-place';
	string providePlaceMsg <- 'provide-place';
	
	list<string> importantAttributes <- ['band', 'show', 'sound-engineer', 
			'sound-quality', 'light-engineer', 'lightshow'];
	
	init {
		create Stage number: nbStages;
		create Guest number: nbGuests;
	}
}

species Stage skills: [fipa] {
	
	float size <- 5.0;		// Defines vertical of stage. Horizontal width is 2 * size.
	rgb color <- rgb(240, 100, 100);
	
	float sizeFloor <- size * 2;	// Defines vertical height of guest floor. Same horizontal width as stage.
	rgb colorFloor <- rgb(100, 200, 90);
	
	geometry stageArea <- rectangle(size * 2, size);
	geometry floorArea <- rectangle(size * 2, sizeFloor);
	
	map<string, float> actAttributes;
	
	init {
		loop attr over: importantAttributes {
			add attr::rnd(0.0, 1.0) to: actAttributes;
		}
	}
	
	reflex answerRequests when: !empty(requests) {
		
		loop r over: requests {
			list<unknown> c <- r.contents;
			
			if(c[0] = requestAttributesMsg) {
				do inform message: r contents: [provideAttributesMsg, actAttributes];
			}
			else if(c[0] = requestPlaceMsg) {
				point placeForVisitor <- any_location_in(floorArea);
				do inform message: r contents: [providePlaceMsg, placeForVisitor];
				//write name + ' informs ' + agent(r.sender).name + ' about place ' + placeForVisitor;
			}
		}
	}
	
	aspect default {
		draw stageArea color: color;
		draw floorArea color: colorFloor 
				at: (self.location + {0, size/2 + sizeFloor/2});
		
		if(displayEntityName) {
			draw name color: #black;
		}
	}
}

species Guest skills: [moving, fipa] {
	
	float size <- 1.0;
	rgb color <- rgb(80, 80, 255);
	
	Stage targetStage <- nil;
	point targetLocation <- nil;
	float currentUtility <- 0.0;
	
	map<string, float> weightOfAttributes;
	
	init {
		loop attr over: importantAttributes {
			add attr::rnd(0.0, 1.0) to: weightOfAttributes;
		}
	}
	
	reflex randomMove when: targetStage = nil {
		do wander;
	}
	
	reflex moveToTarget when: targetLocation != nil {
		do goto target: targetLocation;
	}
	
	reflex requestAttributesFromStages when: targetStage = nil and empty(informs) {
		
		do start_conversation to: list(Stage) performative: 'request' 
				contents: [requestAttributesMsg];
	}
	
	reflex gatherAttributesFromStages when: targetStage = nil and !empty(informs) {
		
		loop i over: informs {
			list<unknown> c <- i.contents;
			
			if(c[0] = provideAttributesMsg 
					and calculateUtility(map<string, float>(c[1])) > currentUtility) {
				
				currentUtility <- calculateUtility(map<string, float>(c[1]));
				targetStage <- i.sender;
			}
		}
		
		if(targetStage != nil) {
			do start_conversation to: [targetStage] performative: 'request' 
				contents: [requestPlaceMsg];
		}
	}
	
	float calculateUtility(map<string, float> actsAttributes) {
		
		float result <- 0.0;
		
		loop attr over: weightOfAttributes.keys {
			result <- weightOfAttributes[attr] * actsAttributes[attr];
		}
		
		return result;
	}
 
	reflex getPlace when: targetStage != nil and targetLocation = nil 
			and !empty(informs) {
		
		loop i over: informs {
			list<unknown> c <- i.contents;
			
			if(c[0] = providePlaceMsg) {
				targetLocation <- c[1];
				write name + ' goes to ' + targetLocation;
			}
		}
	}
	
	aspect default {
		draw circle(size) color: color;
		
		if(displayEntityName) {
			draw name color: #black;
		}
	}
}

grid Cell width: gridWidth height: gridHeight neighbors: 4 {}

experiment OptimiseIndividualUtility type: gui {
 
	parameter "Width of grid: " var: gridWidth min: 10 max: 100 
			category: "Grid Size";
	parameter "Height of grid: " var: gridHeight min: 10 max: 100 
			category: "Grid Size";
	
	parameter "Initial number of stages: " var: nbStages min: 4 max: 8 
			category: "Initial Numbers";
	parameter "Initial number of guests: " var: nbGuests min: 4 max: 100 
			category: "Initial Numbers";
	
	parameter "Display entity names" var: displayEntityName category: "Options";
	
	output {
		display main_display {
			grid Cell lines: #lightgrey;
			
			species Stage;
			species Guest;
		}
	}
}