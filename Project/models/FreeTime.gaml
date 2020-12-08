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
	
	string requestPlaceMsg <- 'request-place';
	string providePlaceMsg <- 'receive-place';
	
	init {
		create Pub number: 1;
		create ConcertHall number: 1;
		
		stalls <- list(Pub) + list(ConcertHall);
		
		create PartyLover number: 2;
		create ChillPerson number: 2;
		create Criminal number: 2;
		create Journalist number: 2;
		create Scientist number: 2;
	}
}

species Stall skills: [fipa] {
	
	float size <- 10.0;
	rgb color <- rgb(240, 100, 100);
	image_file icon <- nil;
	geometry area <- rectangle(size, size);
	
	reflex assignPlace when: !empty(requests) {
		
		loop r over: requests {
			list<unknown> c <- r.contents;
			
			if(c[0] = requestPlaceMsg) {
				point assignedPlace <- any_location_in(area);
				do inform message: r contents: [providePlaceMsg, assignedPlace];
			}
		}
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
}

species ConcertHall parent: Stall {
	image_file icon <- image_file("../includes/data/concert-hall.png");
}

species Mover skills: [moving, fipa] {
	
	float size <- 1.0;
	rgb color <- rgb(80, 80, 255);
	
	point targetLocation <- nil;
	float chanceToGoToStall <- 0.01;
	float chanceToLeaveStall <- 0.1;
	
	bool statusInStall <- false;
	
	int cyclesInStallMin <- 50;
	int cyclesInStall <- 0;
	
	reflex randomMove when: targetLocation = nil and empty(informs) {
		do wander;
	}
	
	reflex moveToTarget when: targetLocation != nil {
		do goto target: targetLocation;
	}
	
	reflex decideToGoToStall when: targetLocation = nil 
			and rnd(1.0) <= chanceToGoToStall and empty(informs) {
		
		do start_conversation to: [any(stalls)] performative: 'request' 
				contents: [requestPlaceMsg];
	}
	
	reflex receivePlaceInStall when: targetLocation = nil and !empty(informs) {
		
		loop i over: informs {
			list<unknown> c <- i.contents;
			
			if(c[0] = providePlaceMsg) {
				targetLocation <- c[1];
			}
		}
	}
	
	reflex enterStall when: targetLocation != nil and !statusInStall 
			and self distance_to targetLocation <= 10 {
		statusInStall <- true;
		cyclesInStall <- 0;
	}
	
	reflex spendCycleInStall when: targetLocation != nil and statusInStall {
		cyclesInStall <- cyclesInStall + 1;
	}
	
	reflex leaveStall when: targetLocation != nil and statusInStall 
			and cyclesInStall > cyclesInStallMin and rnd(1.0) <= chanceToLeaveStall {
		targetLocation <- nil;
		statusInStall <- false;
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
}

species ChillPerson parent: Mover {
	rgb color <- rgb(120, 120, 120);
}

species Criminal parent: Mover {
	rgb color <- rgb(75, 75, 180);
}

species Journalist parent: Mover {
	rgb color <- rgb(200, 200, 40);
}

species Scientist parent: Mover {
	rgb color <- rgb(100, 200, 100);
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
			species Journalist;
			species Scientist;
		}
	}
}
