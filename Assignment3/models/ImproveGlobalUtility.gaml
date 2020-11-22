/**
* Name: ImproveGlobalUtility
* Model in which guests optimise their own utility with deciding on which concert stage to visit.
* Some agents like crowdy places, some not. After their initial choice, some agents move to 
* improve global utility.
* Author: Marco Molinari <molinarimarco8@gmail.com>, Felix Seifert <mail@felix-seifert.com>
*/


model ImproveGlobalUtility

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
	
	int nbCyclesActDuration <- 100;
	int nbCyclesPauseBetweenActs <- 30;
	
	string requestAttributesMsg <- 'request-attributes';
	string provideAttributesMsg <- 'provide-attributes';
	
	string requestPlaceMsg <- 'request-place';
	string providePlaceMsg <- 'provide-place';
	string removeFromListMsg <- 'remove-from-attendee-list';
	
	string actEndedMsg <- 'act-ended';
	
	string informAboutAttendeesMsg <- 'inform-about-attendees';
	
	string requestCrowdLoverMsg <- 'request-crowd-love';
	string provideCrowdLoverMsg <- 'provide-crowd-love';
	
	string requestPersonalUtilityMsg <- 'request-personal-utility';
	string providePersonalUtilityMsg <- 'provide-personal-utility';
	
	string moveToNewPlaceMsg <- 'move-to-new-place';
	
	list<string> importantAttributes <- ['band', 'show', 'sound-engineer', 
			'sound-quality', 'light-engineer', 'lightshow'];
	
	init {
		create Stage number: nbStages;
		create Guest number: nbGuests;
		create Optimiser number: 1;
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
	
	bool optimiserInformed <- false;
	
	list<Guest> guestsAtAct <- [];
	
	map<string, float> actAttributes;
	
	init {
		do generateActAttributes;
	}
	
	action generateActAttributes {
		loop attr over: importantAttributes {
			add attr::rnd(0.2, 1.0) to: actAttributes;
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
		
		actAttributes <- [];
		do generateActAttributes;
		
		if(!empty(guestsAtAct)) {
			
			do start_conversation to: guestsAtAct performative: 'inform' 
				contents: [actEndedMsg];
				
			guestsAtAct <- [];
		}
		
		// Inform Optimiser about act end
		do start_conversation to: list(Optimiser) performative: 'inform' 
				contents: [actEndedMsg];
		
		optimiserInformed <- false;
			
		color <- rgb(240, 100, 100);
		colorFloor <- rgb(240, 170, 170);
		icon <- nil;
		
//		write 'Act at ' + name + ' ended';
	}
	
	reflex informOptimiserAboutAttendingGuests when: !optimiserInformed 
			and durationPause > 5 {
		
		optimiserInformed <- true;
		
		do start_conversation to: list(Optimiser) performative: 'inform' 
				contents: [informAboutAttendeesMsg, guestsAtAct];
	}
	
	reflex answerRequests when: !empty(requests) {
		
		loop r over: requests {
			list<unknown> c <- r.contents;
			
			if(c[0] = requestAttributesMsg) {
				do inform message: r contents: [provideAttributesMsg, actAttributes];
			}
			else if(c[0] = requestPlaceMsg) {
				
				add Guest(r.sender) to: guestsAtAct;
				
				point placeForVisitor <- any_location_in(floorArea);
				do request message: r contents: [providePlaceMsg, placeForVisitor];
//				write name + ' informs ' + agent(r.sender).name + ' about place ' 
//						+ placeForVisitor;
			}
			else if(c[0] = removeFromListMsg) {
				remove Guest(r.sender) from: guestsAtAct;
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

species Optimiser skills: [fipa] {
	
	list<Stage> actsWithZeroGuests <- [];
	Stage crowdedAct <- nil;
	
	list<Guest> guestsWhoHaveToMoveToEmptyAct <- [];
	list<Guest> guestsWhoHaveToMoveToCrowd <- [];
	
	int cycles <- 0 update: cycles + 1;
	
	reflex triggerNewGlobalUtilityCalculation when: cycles = 10 {
		write 'New global utility: ' + calculateGlobalUtility(list(Stage));
	}
	
	reflex handleInforms when: !empty(informs) {
		
		loop i over: informs {
			list<unknown> c <- i.contents;
			
			if(c[0] = actEndedMsg) {
				// Empty variables of Optimiser when act ended
				actsWithZeroGuests <- [];
				crowdedAct <- nil;
				guestsWhoHaveToMoveToEmptyAct <- [];
				guestsWhoHaveToMoveToCrowd <- [];
				cycles <- 0;
			}
			else if(c[0] = informAboutAttendeesMsg 
					and length(list<unknown>(c[1])) > nbGuests/2) {
				
				// Find single Guest who hates crowd at crowded act
				
				Guest singleCrowdHater <- nil;
				
				loop guest over: list<Guest>(c[1]) {
					if(!guest.lovesCrowd and singleCrowdHater = nil) {
						singleCrowdHater <- guest;
					}
					else if(!guest.lovesCrowd and singleCrowdHater = nil) {
						singleCrowdHater <- nil;
						break;
					}
				}
				
				if(singleCrowdHater != nil) {
					add singleCrowdHater to: guestsWhoHaveToMoveToEmptyAct;
				}
				
				crowdedAct <- Stage(i.sender);
			}
			else if(c[0] = informAboutAttendeesMsg 
					and length(c[1]) = 2) {
				
				// Find single Guest who likes crowd while other event attendee hates crowd
				
				Guest singleCrowdLover <- nil;
				
				loop guest over: list<Guest>(c[1]) {
					if(guest.lovesCrowd and singleCrowdLover = nil) {
						singleCrowdLover <- guest;
					}
					else if(guest.lovesCrowd and singleCrowdLover != nil) {
						singleCrowdLover <- nil;
					}
				}
				
				if(singleCrowdLover != nil) {
					add singleCrowdLover to: guestsWhoHaveToMoveToCrowd;
				}
			}
			else if(c[0] = informAboutAttendeesMsg 
					and length(list<unknown>(c[1])) = 0) {
				
				// Find empty acts
				
				add Stage(i.sender) to: actsWithZeroGuests;
			}
		}
		
		write 'Current global utility: ' + calculateGlobalUtility(list(Stage));
		
//		write 'Acts with zero guests: ' + actsWithZeroGuests;
//		write 'Crowded act: ' + crowdedAct;
//		write 'Guests who have to move to empty act: ' + guestsWhoHaveToMoveToEmptyAct;
//		write 'Guests who have to move to crowd: ' + guestsWhoHaveToMoveToCrowd;
	}
	
	reflex moveGuestsToEmptyActs when: !empty(actsWithZeroGuests) 
			and !empty(guestsWhoHaveToMoveToEmptyAct) {
		
		Guest guest <- any(guestsWhoHaveToMoveToEmptyAct);
		
		Stage actToGoTo;
		float bestUtility <- 0.0;
		
		loop act over: actsWithZeroGuests {
			
			if(calculateUtility(act.actAttributes, guest.preferences) > bestUtility) {
				bestUtility <- calculateUtility(act.actAttributes, guest.preferences);
				actToGoTo <- act;
			}
		}
			
		remove actToGoTo from: actsWithZeroGuests;
		remove guest from: guestsWhoHaveToMoveToEmptyAct;
		
		do start_conversation to: [guest] performative: 'request'
				contents: [moveToNewPlaceMsg, actToGoTo];
		
		write 'A guest was sent to an empty act';
	}
	
	reflex moveGuestsToCrowdedActs when: crowdedAct != nil 
			and !empty(guestsWhoHaveToMoveToCrowd) {
		
		Guest guest <- any(guestsWhoHaveToMoveToCrowd);
		
		do start_conversation to: [guest] performative: 'request'
				contents: [moveToNewPlaceMsg, crowdedAct];
		
		write 'A guest was sent to a more crowded act';
	}
	
	float calculateUtility(map<string, float> actsAttributes, 
			map<string, float> guestPreferences) {
		
		float result <- 0.0;
		
		loop attr over: guestPreferences.keys {
			result <- result + (guestPreferences[attr] * actsAttributes[attr]);
		}
		
		return result;
	}
	
	float calculateGlobalUtility(list<Stage> allStages) {
		
		float globalUtility <- 0.0;
		
		loop stage over: allStages {
			
			float crowdUtilityValue <- length(stage.guestsAtAct) / nbGuests;
			
			loop guest over: stage.guestsAtAct {
				globalUtility <- globalUtility 
						+ calculateUtility(stage.actAttributes, guest.preferences) 
						+ calculateCrowdUtility(crowdUtilityValue, guest);
			}
		}
		
		return globalUtility;
	}
	
	float calculateCrowdUtility(float utilityValue, Guest guest) {
		if(!guest.lovesCrowd) {
			return - utilityValue;
		}
		return utilityValue;
	}
}

species Guest skills: [moving, fipa] {
	
	float size <- 1.0;
	rgb color <- rgb(80, 80, 255);
	
	Stage targetStage <- nil;
	point targetLocation <- nil;
	float currentUtility <- 0.0;
	
	map<string, float> preferences;
	bool lovesCrowd <- rnd(0,1) = 1 ? true : false;
	
	init {
		loop attr over: importantAttributes {
			add attr::rnd(0.2, 1.0) to: preferences;
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
		
		loop attr over: preferences.keys {
			result <- result + (preferences[attr] * actsAttributes[attr]);
		}
		
		return result;
	}
	
	reflex handleRequests when: targetStage != nil and !empty(requests) {
		
		loop r over: requests {
			list<unknown> c <- r.contents;
			
			if(c[0] = moveToNewPlaceMsg) {
				do start_conversation to: [targetStage] performative: 'request'
						contents: [removeFromListMsg];
				targetStage <- c[1];
				do start_conversation to: [targetStage] performative: 'request' 
						contents: [requestPlaceMsg];
			}
			else if(c[0] = providePlaceMsg) {
				targetLocation <- c[1];
//				write name + ' goes to ' + targetLocation;
			}
		}
	}
	
	reflex realiseActEnded when: targetStage != nil and targetLocation != nil 
			and !empty(informs) {
		
		loop i over: informs {
			list<unknown> c <- i.contents;
			
//			write name + ' realised that act ' + c[1] + ' ended';
//			write name + '\'s targetStage is ' + targetStage;
			
			if(c[0] = actEndedMsg) {
				targetStage <- nil;
				targetLocation <- nil;
				currentUtility <- 0.0;
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

experiment ImproveGlobalUtility type: gui {
 
	parameter "Width of grid: " var: gridWidth min: 10 max: 100 
			category: "Grid Size";
	parameter "Height of grid: " var: gridHeight min: 10 max: 100 
			category: "Grid Size";
	
	parameter "Initial number of stages: " var: nbStages min: 4 max: 8 
			category: "Initial Numbers";
	parameter "Initial number of guests: " var: nbGuests min: 10 max: 100 
			category: "Initial Numbers";
	
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
		}
	}
}