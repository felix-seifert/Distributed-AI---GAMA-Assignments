/**
* Name: FreeTime
* Model which simulates different humanoid entities who spend their free time and interact with each other 
* Author: Marco Molinari <molinarimarco8@gmail.com>, Felix Seifert <mail@felix-seifert.com>
*/


model FreeTime

global {
	
	int gridWidth <- 10;
	int gridHeight <- 10;
	bool displayEntityName <- false;
	
	list<Stall> stalls <- [];
	list<string> musicGenres <- ['Rock', 'Metal', 'Blues', 'Funk', 'Hip Hop'];
	
	string requestPlaceMsg <- 'request-place';
	string providePlaceMsg <- 'receive-place';
	string enterStallMsg <- 'enter-stall';
	string leaveStallMsg <- 'leave-stall';
	
	init {
		create Pub number: 1;
		create ConcertHall number: 1;
		
		stalls <- list(Pub) + list(ConcertHall);
		
		create PartyLover number: 2;
		create ChillPerson number: 2;
		create Criminal number: 2;
	}
}

species Stall skills: [fipa] {
	
	float size <- 10.0;
	rgb color <- rgb(240, 100, 100);
	image_file icon <- nil;
	geometry area <- rectangle(size, size);
	
	list<Mover> guests <- [];
	
	reflex assignPlace when: !empty(requests) {
		
		loop r over: requests {
			list<unknown> c <- r.contents;
			
			if(c[0] = requestPlaceMsg) {
				point assignedPlace <- any_location_in(area);
				do inform message: r contents: [providePlaceMsg, assignedPlace];
			}
		}
	}
	
	reflex guestEntersOrLeaves when: !empty(informs) {
		
		loop i over: informs {
			list<unknown> c <- i.contents;
			
			if(c[0] = enterStallMsg) {
				add Mover(i.sender) to: guests;
			}
			else if(c[0] = leaveStallMsg) {
				remove Mover(i.sender) from: guests;
			}
		}
		
		write 'Guests of ' + self.name + ': ' + guests;
	}
	
	aspect default {
		draw area color: color;
		
		draw icon size: 4.5;
		
		if(displayEntityName) {
			draw name color: #black;
		}
	}
}

species Pub parent: Stall {
	image_file icon <- image_file("../includes/data/pub.png");
	
	bool kitchenOpen <- true;
	int kitchenOpenedCycles <- 100;
	int kitchenClosedCycles <- 50;
	int currentCycle <- 0;
	
	reflex openKitchen when: !kitchenOpen and currentCycle >= kitchenClosedCycles {
		kitchenOpen <- true;
		currentCycle <- 0;
		write self.name + ' opened kitchen';
	}
	
	reflex closeKitchen when: kitchenOpen and currentCycle >= kitchenOpenedCycles {
		kitchenOpen <- false;
		currentCycle <- 0;
		write self.name + ' closed kitchen';
	}
	
	reflex timeProgress {
		currentCycle <- currentCycle + 1;
	}
}

species ConcertHall parent: Stall {
	image_file icon <- image_file("../includes/data/concert-hall.png");
	
	int concertCycles <- 70;
	int currentCycle <- 0;
	string currentConcertGenre <- any(musicGenres);
	
	reflex startNewConcert when: currentCycle > concertCycles {
		currentCycle <- 0;
		currentConcertGenre <- any(musicGenres);
		write self.name + ' started concert with genre ' + currentConcertGenre;
	}
	
	reflex timeProgress {
		currentCycle <- currentCycle + 1;
	}
}

species Mover skills: [moving, fipa] {
	
	float size <- 1.0;
	rgb color <- rgb(80, 80, 255);
	
	Stall targetStall <- nil;
	point targetPlace <- nil;
	float chanceToGoToStall <- 0.01;
	float chanceToLeaveStall <- 0.1;
	
	bool inStall <- false;
	
	int cyclesInStallMin <- 50;
	int cyclesInStall <- 0;
	
	reflex randomMove when: targetStall = nil and empty(informs) {
		do wander;
	}
	
	reflex moveToTarget when: targetPlace != nil and !inStall {
		do goto target: targetPlace;
	}
	
	reflex decideToGoToStall when: targetStall = nil 
			and rnd(1.0) <= chanceToGoToStall and empty(informs) {
				
		targetStall <- any(stalls);
		
		do start_conversation to: [targetStall] performative: 'request' 
				contents: [requestPlaceMsg];
	}
	
	reflex receivePlaceInStall when: targetStall != nil and targetPlace = nil 
			and !empty(informs) {
		
		loop i over: informs {
			list<unknown> c <- i.contents;
			
			if(c[0] = providePlaceMsg) {
				targetPlace <- c[1];
			}
		}
	}
	
	reflex enterStall when: targetPlace != nil and !inStall 
			and self distance_to targetPlace <= 10 {
		
		do start_conversation to: [targetStall] performative: 'inform' 
				contents: [enterStallMsg];
				
		inStall <- true;
		cyclesInStall <- 0;
	}
	
	reflex spendCycleInStall when: inStall {
		cyclesInStall <- cyclesInStall + 1;
	}
	
	reflex leaveStall when: inStall and cyclesInStall > cyclesInStallMin 
			and rnd(1.0) <= chanceToLeaveStall {
		
		do start_conversation to: [targetStall] performative: 'inform' 
				contents: [leaveStallMsg];
				
		targetStall <- nil;
		targetPlace <- nil;
		inStall <- false;
	}
	
	aspect default {
		draw circle(size) color: color;
		
		if(displayEntityName) {
			draw name color: #black;
		}
	}
}

species PartyLover parent: Mover {
	rgb color <- rgb(220, 120, 50);
	
	list<string> favouriteMusicGenres <- [any(musicGenres), any(musicGenres)];
}

species ChillPerson parent: Mover {
	rgb color <- rgb(120, 120, 120);
}

species Criminal parent: Mover {
	rgb color <- rgb(75, 75, 180);
}

grid Cell width: gridWidth height: gridHeight neighbors: 4 {}

experiment EnjoyFreeTime type: gui {
	
	output {
		display main_display {
			grid Cell lines: #lightgrey;
			
			species Pub;
			species ConcertHall;
			
			species PartyLover;
			species ChillPerson;
			species Criminal;
		}
	}
}
