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
	
	list<image_file> icons <- [
		image_file("../includes/data/singer.png"), 
		image_file("../includes/data/band.png"), 
		image_file("../includes/data/cello.png"), 
		image_file("../includes/data/piano.png")
	];
	
	int nbStages <- 4;
	int nbGuests <- 10;
	int nbLeader <- 1;
	
	int nbCyclesActDuration <- 100;
	int nbCyclesPauseBetweenActs <- 300;
	
	string requestAttributesMsg <- 'request-attributes';
	string provideAttributesMsg <- 'provide-attributes';
	
	string requestPlaceMsg <- 'request-place';
	string providePlaceMsg <- 'provide-place';
	
	string actEndedMsg <- 'act-ended';
	
	list<string> importantAttributes <- ['band', 'show', 'sound-engineer', 
			'sound-quality', 'light-engineer', 'lightshow'];
	
	init {
		create Stage number: nbStages;
		create Guest number: nbGuests;
		create Leader number: nbLeader;
	}
}

species Stage skills: [fipa] {
	
	image_file icon <- nil;
	
	float size <- 5.0;		// Defines vertical of stage. Horizontal width is 2 * size.
	rgb color <- rgb(240, 100, 100);
	
	float sizeFloor <- size * 2;	// Defines vertical height of guest floor. Same horizontal width as stage.
	rgb colorFloor <- rgb(240, 170, 170);
	
	geometry stageArea <- rectangle(size * 2, size);
	geometry floorArea <- rectangle(size * 2, sizeFloor);
	
	int durationAct <- 0 update: durationAct + 1;
	int durationPause <- 0 update: durationPause + 1;
	bool actStarted <- false;
	
	int currentCrowdSize <- 0;
	
	map<string, float> actAttributes;
	
	init {
		do generateActAttributes;
	}
	
	action generateActAttributes {
		loop attr over: importantAttributes {
			add attr::rnd(0.0, 1.0) to: actAttributes;
		}
	}
	
	reflex startAct when: !actStarted and durationPause > nbCyclesPauseBetweenActs {
		durationAct <- 0;
		actStarted <- true;
		
		color <- rgb(100, 200, 90);
		colorFloor <- rgb(160, 210, 160);
		icon <- one_of(icons);
		
//		write 'Act at ' + name + 'started';
	}
	
	reflex endAct when: actStarted and durationAct > nbCyclesActDuration {
		durationPause <- 0;
		actStarted <- false;
		
		//write actAttributes;
		actAttributes <- [];
		do generateActAttributes;
		
		do start_conversation to: (list(Guest)+list(Leader)) performative: 'inform' 
				contents: [actEndedMsg, self];
			
		color <- rgb(240, 100, 100);
		colorFloor <- rgb(240, 170, 170);
		icon <- nil;
		
//		write 'Act at ' + name + ' ended';
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
//				write name + ' informs ' + agent(r.sender).name + ' about place ' 
//						+ placeForVisitor;
			}
		}
	}
	
	aspect default {
		draw stageArea color: color;
		draw floorArea color: colorFloor 
				at: (self.location + {0, size/2 + sizeFloor/2});
		
		draw icon size: 4.5;
		
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
	bool enjoyCrowds <- flip(0.5);
	float crowdsEnjoymentRate <- 0.1;
	int currentCrowdSize <- 0;
	bool said <- true;
	bool shouldChangeStage <- false;
	
	reflex aaa when: said = true {
		if enjoyCrowds {
			color <- rgb(80, 80, 0);
		}
		write enjoyCrowds;
		said <- false;
	}
	
	map<string, float> weightOfAttributes;
	
	init {
		loop attr over: importantAttributes {
			add attr::rnd(0.0, 1.0) to: weightOfAttributes;
			//write weightOfAttributes; ///////////////////////////////////////////////////
		}
		if !enjoyCrowds {
			crowdsEnjoymentRate <- -0.1;
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
			
//			write name + ' has utility of ' + calculateUtility(map<string, float>(c[1])) 
//					+ ' for ' + agent(i.sender).name;
			
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
			result <- result + (weightOfAttributes[attr] * actsAttributes[attr]);
		}
		
		write string(crowdsEnjoymentRate * targetStage.currentCrowdSize) + " is " + string(self) + " current enjoyment of the crowd at stage " + string(targetStage);
		
		return result;
	}
 
	reflex getPlace when: targetStage != nil and targetLocation = nil 
			and !empty(informs) {
		
		loop i over: informs {
			list<unknown> c <- i.contents;
			
			if(c[0] = providePlaceMsg) {
				targetLocation <- c[1];
//				write name + ' goes to ' + targetLocation;
			}
		}
	}
	
	reflex realiseActEnded when: targetStage != nil and targetLocation != nil 
			and !empty(informs) {
		
		loop i over: informs {
			list<unknown> c <- i.contents;
			
			//write name + ' realised that act ' + c[1] + ' ended';
			//write name + '\'s targetStage is ' + targetStage;
			
			if(c[0] = actEndedMsg and c[1] = targetStage) {
				targetStage <- nil;
				targetLocation <- nil;
				currentUtility <- 0.0;
				//write currentUtility;
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


species Leader parent: Guest {
	
	float size <- 2.0;
	rgb color <- rgb(0, 120, 120);
	bool said <- false;
	bool allGuestsHaveTargetStage <- false;
	list<Stage> guestsTargetStage <- [];
	float globalUtility <- 0.0;
	list<int> nbGuestsPerStage <- [];
	bool nbGuestsPerStageCounted <- false;
	
	//reflex checkIfGuestsHaveTarget when: currentUtility != 0.0 and !allGuestsHaveTargetStage {
	reflex checkIfGuestsHaveTarget when: currentUtility != 0.0 {
		//check if Guests have a Target != nil
		int nbGuestsWithTarget <- 0;
		
		loop g over: list(Guest) {
			if g.currentUtility != 0.0 {
				nbGuestsWithTarget <- nbGuestsWithTarget + 1;
			}
		}
		
		if length(list(Guest)) = nbGuestsWithTarget {
			allGuestsHaveTargetStage <- true;
			do countNumberOfGuestsPerStage;
		}
	}
	
	reflex checkGuestsIntentions when: allGuestsHaveTargetStage and guestsTargetStage = [] {
		
		loop g over: list(Guest) {
			add g.targetStage to: guestsTargetStage;
		}
		
		//write guestsTargetStage;
		do calculateGlobalUtility;
		
	}
	
	action calculateGlobalUtility {
		// calculate global utility
		
		loop g over: list(Guest) {
			globalUtility <- globalUtility + g.currentUtility;
		}
		
		//write string(globalUtility);
		do resetGlobalUtility;
	}
	
	action resetGlobalUtility {
		globalUtility <- 0.0;
		//write "reset global utility!";
	}
	
	action resetGuestsTargetStage {
		guestsTargetStage <- [];
	}
	
	action countNumberOfGuestsPerStage {
		
		nbGuestsPerStage <- [];
		
		loop s over: list(Stage) {
			add (guestsTargetStage count(each = s)) to: nbGuestsPerStage;
			s.currentCrowdSize <- (guestsTargetStage count(each = s));
		}
		
		loop g over: list(Guest) {
			g.currentCrowdSize <- nbGuestsPerStage[index_of(list(Stage), g.targetStage)];
			//write g.currentCrowdSize;
			//Now every Guest has the number of Guests in the same Stage allocated in the variable "currentCrowdSize"
			//With this it's possible to calculate how much does every guest like the crowd in their current Stage
		}
		
		//write string(nbGuestsPerStage) + " nbGuestsPerStage";
		guestsTargetStage <- [];
		nbGuestsPerStageCounted <- true;
		

	}
	
	reflex suggestNewStage when: nbGuestsPerStageCounted {
		
		list<float> allUtilityCombinations <- [];
		
		
	}
	
	
	


}



grid Cell width: gridWidth height: gridHeight neighbors: 4 {}

experiment OptimiseIndividualUtility type: gui {
 
	parameter "Width of grid: " var: gridWidth min: 10 max: 100 
			category: "Grid Size";
	parameter "Height of grid: " var: gridHeight min: 10 max: 100 
			category: "Grid Size";
	
	parameter "Initial number of stages: " var: nbStages min: 4 max: 8 category: "Initial Numbers";
	parameter "Initial number of guests: " var: nbGuests min: 10 max: 100 category: "Initial Numbers";
	parameter "Initial number of leaders: " var: nbGuests min: 1 max: 1	category: "Initial Numbers";
	
	parameter "Number of cycles for act duration" var: nbCyclesActDuration 
			min: 50 max: 500 category: "Durations";
	parameter "Number of cycles for pause between acts" var: nbCyclesPauseBetweenActs 
			min: 20 max: 100 category: "Durations";
	
	parameter "Display entity names" var: displayEntityName category: "Options";
	
	output {
		display main_display {
			grid Cell lines: #lightgrey;
			
			species Stage;
			species Guest;
			species Leader;
		}
	}
}
