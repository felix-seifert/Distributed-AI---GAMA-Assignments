/**
* Name: FreeTime
* Model which simulates different humanoid entities who spend their free time and interact with each other 
* Author: Marco Molinari <molinarimarco8@gmail.com>, Felix Seifert <mail@felix-seifert.com>
*/


model FreeTime

global {
	
	int gridWidth <- 20;
	int gridHeight <- 20;
	bool displayEntityName <- false;
	
	list<Stall> stalls <- [];
	list<string> musicGenres <- ['Rock', 'Metal', 'Blues', 'Funk', 'Hip Hop'];
	
	string requestPlaceMsg <- 'request-place';
	string providePlaceMsg <- 'receive-place';
	string enterStallMsg <- 'enter-stall';
	string leaveStallMsg <- 'leave-stall';
	
	string requestInterviewMsg <- 'request-interview';
	string acceptInterviewMsg <- 'accept-interview';
	string continueInterviewMsg <- 'continue-interview';
	string finishInterviewMsg <- 'finishInterviewMsg';
	
	init {
		create Pub number: 4;
		create ConcertHall number:4;
		
		stalls <- list(Pub) + list(ConcertHall);
		
		create PartyLover number: 2;
		create ChillPerson number: 2;
		create Criminal number: 2;
		create Journalist number: 2;
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
	bool inInterview <- false;
	
	int cyclesInStallMin <- 50;
	int cyclesInStall <- 0;
	
	reflex randomMove when: targetStall = nil and empty(informs) {
		do wander;
	}
	
	reflex moveToTarget when: targetPlace != nil and !inStall {
		do goto target: targetPlace;
	}
	
	reflex decideToGoToStall when: targetStall = nil 
			and rnd(1.0) <= chanceToGoToStall and empty(informs) and !inInterview {
				
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
	float chanceToAcceptInterview <- 0.5;
	
	list<string> favouriteMusicGenres <- [any(musicGenres), any(musicGenres)];
	
	reflex randomMove when: targetStall = nil and empty(informs) and !inStall and !inInterview{
		do wander;
	}
	
	reflex moveToTarget when: targetPlace != nil and !inStall and !inInterview {
		do goto target: targetPlace;
	}
	
	reflex moveToInterview when: inInterview {
		targetPlace <- nil;
		targetStall <- nil;
	}	
	
	reflex considerInterview when: !empty(requests) and rnd(1.0) <= chanceToAcceptInterview and !inInterview {
		
		write 'ACCEPTING INTERVIEW! #########################';
		
		loop r over: requests {
			list<unknown> c <- r.contents;
			if(c[0] = requestInterviewMsg) {
				//STAY
				inInterview <- true;

				do inform message: r contents: [acceptInterviewMsg, any(Stall)]; 
				//We can reimplement the memory feature, so the proposed Stall is one that has been visited
			}
		}
	}
	
	reflex continueInterview when: !empty(informs) and inInterview{
		
		loop i over: informs {
			list<unknown> c <- i.contents;
			
			if(c[0] = continueInterviewMsg) {
				//
				write string(i.sender) + 'is interviewing: ' + self.name;
			}
			else if(c[0] = finishInterviewMsg) {
				targetPlace <- nil;
				targetStall <- nil;
				inInterview <- false;
			}
		}
	}

}

species ChillPerson parent: Mover {
	rgb color <- rgb(120, 120, 120);
}

species Criminal parent: Mover {
	rgb color <- rgb(75, 75, 180);
}

species Journalist parent: Mover {
	rgb color <- rgb(252, 186, 3);
	
	Mover targetInterview <- nil;
	float chanceToInterview <- 0.5;
	list<Stall> stallsReport <- [];
	list<Mover> interviewedMovers <- [];
	
	int cyclesInInterviewMin <- 50;
	int cyclesInInterview <- 0;
	
	
	reflex randomMove when: targetStall = nil and targetInterview = nil and empty(informs) and !inStall and !inInterview{
		do wander;
	}
	
	reflex moveToTarget when: targetPlace != nil and !inStall and !inInterview {
		do goto target: targetPlace;
	}
	
	reflex moveToInterview when: targetInterview != nil and !inStall {
		do goto target: targetInterview;
		targetStall <- nil;
	}
		
	
	reflex decideToInterview when: targetInterview = nil 
			and rnd(1.0) <= chanceToInterview and empty(informs) {
		
		Mover nextTarget <- PartyLover closest_to(self);
		
		if !(nextTarget in interviewedMovers) {					
			targetInterview <- PartyLover closest_to(self);
			
			do start_conversation to: [targetInterview] performative: 'request' 
				contents: [requestInterviewMsg];
		}
	}

	reflex askSuggestionAboutStall when: targetInterview != nil and !empty(informs) and !inInterview and self distance_to targetInterview <= 1.5{
		
		loop i over: informs {
			list<unknown> c <- i.contents;
			
			if(c[0] = acceptInterviewMsg) {
				add c[1] to: stallsReport;
				add i.sender to: interviewedMovers;
			}
		}
	}
		
	reflex continueInterview when: targetInterview != nil and !inInterview and !inStall {
		
		do start_conversation to: [targetInterview] performative: 'inform' 
				contents: [continueInterviewMsg];

		cyclesInInterview <- 0;
		inInterview <- true;
	}
	
	reflex spendCycleInInterview when: inInterview {
		cyclesInInterview <- cyclesInInterview + 1;
		//write cyclesInInterview;
	}
	
	reflex finishInterview when: inInterview and cyclesInInterview > cyclesInInterviewMin  {
		write 'interview finished!#########################################################################';
		
		do start_conversation to: [targetInterview] performative: 'inform' 
				contents: [finishInterviewMsg];
				
		targetInterview <- nil;
		targetPlace <- nil;
		inInterview <- false;
		cyclesInInterview <- 0;
	}
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
		}
	}
}
