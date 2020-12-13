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
	
	int nbPubs <- 2;
	int nbConcertHalls <- 2;
	
	int nbPartyLovers <- 20;
	int nbChillPeople <- 20;
	int nbCriminals <- 10;
	
	int nbAllMovers <- nbPartyLovers + nbChillPeople + nbCriminals;
	
	float valueForGenerousEnough <- 0.4;
	float incrementGenerous <- 0.005;
	float chanceToInviteSomeoneForDrink <- 0.5;
	
	int nbDrinkInvitations <- 0;
	float globalGenerous <- 0.0;
	
	list<Stall> stalls <- [];
	list<string> musicGenres <- ['Rock', 'Metal', 'Blues', 'Funk', 'Hip Hop'];
	
	string typePub <- 'pub';
	string typeConcertHall <- 'concert-hall';
	
	// Messages for communication
	string requestPlaceMsg <- 'request-place';
	string providePlaceMsg <- 'receive-place';
	string enterStallMsg <- 'enter-stall';
	string leaveStallMsg <- 'leave-stall';
	string inquireGenreMsg <- 'inquire-genre';
	string informAboutGenreMsg <- 'inform-about-genre';
	string inquireKitchenMsg <- 'inquire-kitchen';
	string informAboutKitchenMsg <- 'inform-about-kitchen';
	string askForGuestsMsg <- 'who-is-there';
	string provideGuestListMsg <- 'they-are-here';
	string inviteSomeoneForDrink <- 'invite-someone-for-drink';
	string drinkInvitationMsg <- 'drink-invitation';
	
	// BDI
	float sightDistance <- 3.0;
	
	string pubAtLocation <- "pubAtLocation";
    string emptyPubLocation <- "emptyPubLocation";
    
    predicate pubLocation <- new_predicate(pubAtLocation);
    predicate choosePub <- new_predicate("choose a pub");
    predicate hasFood <- new_predicate("steal food");
    predicate findFood <- new_predicate("find food");
    predicate consumeFood <- new_predicate("consume food");
    
    reflex end_simulation when: sum(Criminal collect each.stolenFoodConsumed) > 10 {
    	do pause;
    	ask Criminal {
    		write name + " has consumed " + stolenFoodConsumed + "stolen food!";
    	}
    }

	reflex updateGlobalGenerous when: cycle mod 10 = 0 {
		
		globalGenerous <- 0.0;
		
		loop p over: list(PartyLover) {
			globalGenerous <- globalGenerous + p.generous;
		}
		loop p over: list(ChillPerson) {
			globalGenerous <- globalGenerous + p.generous;
		}
		loop p over: list(Criminal) {
			globalGenerous <- globalGenerous + p.generous;
		}
		
		globalGenerous <- globalGenerous / nbAllMovers;
	}
	
	init {
		create Pub number: nbPubs;
		create ConcertHall number: nbConcertHalls;
		
		stalls <- list(Pub) + list(ConcertHall);
		
		create PartyLover number: nbPartyLovers;
		create ChillPerson number: nbChillPeople;
		create Criminal number: nbCriminals;
	}
}

species Stall skills: [fipa] {
	
	float size <- 10.0;
	rgb color <- rgb(240, 100, 100);
	image_file icon <- nil;
	geometry area <- rectangle(size, size);
	
	string typeOfStall <- nil;
	
	list<Mover> guests <- [];
	
	int currentCycle <- 0;
	
	reflex handleRequests when: !empty(requests) {
		
		loop r over: requests {
			list<unknown> c <- r.contents;
			
			if(c[0] = requestPlaceMsg) {
				point assignedPlace <- any_location_in(area);
				do inform message: r contents: [providePlaceMsg, assignedPlace];
			}
			else if(c[0] = askForGuestsMsg) {
				do inform message: r contents: [provideGuestListMsg, guests];
			}
		}
	}
	
	reflex guestEntersOrLeaves when: !empty(subscribes) {
		
		loop s over: subscribes {
			list<unknown> c <- s.contents;
			
			if(c[0] = enterStallMsg) {
				add Mover(s.sender) to: guests;
			}
			else if(c[0] = leaveStallMsg) {
				remove Mover(s.sender) from: guests;
			}
		}
		
		//write 'Guests of ' + self.name + ': ' + guests;
	}
	
	reflex someoneShouldReceiveDrink when: !empty(cfps) {
		
		loop call over: cfps {
			list<unknown> c <- call.contents;
			
			if(c[0] = inviteSomeoneForDrink and length(guests) > 1) {
				Mover chosenGuest <- chooseRandomGuest(call.sender);
				
				do start_conversation to: [chosenGuest] performative: 'propose'
						contents: [drinkInvitationMsg, call.sender];
			}
		}
	}
	
	Mover chooseRandomGuest(Mover guestWhichShouldBeIgnored) {
		remove guestWhichShouldBeIgnored from: guests;
		Mover chosenGuest <- any(guests);
		add guestWhichShouldBeIgnored to: guests;
		return chosenGuest;
	}
	
	reflex timeProgress {
		currentCycle <- currentCycle + 1;
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
	
	string typeOfStall <- typePub;
	
	bool kitchenIsOpen <- true;
	int kitchenOpenedCycles <- 100;
	int kitchenClosedCycles <- 50;
	
	// BDI
	int stealableFood <- rnd(5,10);
	
	reflex openKitchen when: !kitchenIsOpen and currentCycle >= kitchenClosedCycles {
		kitchenIsOpen <- true;
		currentCycle <- 0;
		//write self.name + ' opened kitchen';
	}
	
	reflex closeKitchen when: kitchenIsOpen and currentCycle >= kitchenOpenedCycles {
		kitchenIsOpen <- false;
		currentCycle <- 0;
		//write self.name + ' closed kitchen';
	}
	
	reflex informAboutKitchen when: !empty(queries) {
		
		loop q over: queries {
			list<unknown> c <- q.contents;
			
			if(c[0] = inquireKitchenMsg) {
				do query message: q contents: [informAboutKitchenMsg, kitchenIsOpen];
			}
		}
	}
}

species ConcertHall parent: Stall {
	image_file icon <- image_file("../includes/data/concert-hall.png");
	
	string typeOfStall <- typeConcertHall;
	
	int concertCycles <- 70;
	string currentConcertGenre <- any(musicGenres);
	
	reflex startNewConcert when: currentCycle > concertCycles {
		currentCycle <- 0;
		currentConcertGenre <- any(musicGenres);
		//write self.name + ' started concert with genre ' + currentConcertGenre;
	}
	
	reflex informAboutMusicGenre when: !empty(queries) {
		
		loop q over: queries {
			list<unknown> c <- q.contents;
			
			if(c[0] = inquireGenreMsg) {
				do query message: q contents: [informAboutGenreMsg, currentConcertGenre];
			}
		}
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
	bool oneTimeInteractionDone <- false;
	bool inviteForDrinkOptionChecked <- false;
	
	int cyclesInStallMin <- 50;
	int cyclesInStall <- 0;
	
	float noisy <- rnd(0.2);
	float generous <- rnd(0.35);
	float hungry <- rnd(1.0);
	
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
			and !inStall and !empty(informs) {
		
		loop i over: informs {
			list<unknown> c <- i.contents;
			
			if(c[0] = providePlaceMsg) {
				targetPlace <- c[1];
			}
		}
	}
	
	reflex enterStall when: targetPlace != nil and !inStall 
			and self.location = targetPlace {
		
		do start_conversation to: [targetStall] performative: 'subscribe' 
				contents: [enterStallMsg];
				
		inStall <- true;
		oneTimeInteractionDone <- false;
		inviteForDrinkOptionChecked <- false;
		cyclesInStall <- 0;
	}
	
	reflex spendCycleInStall when: inStall {
		cyclesInStall <- cyclesInStall + 1;
	}
	
	reflex leaveStall when: inStall and cyclesInStall > cyclesInStallMin 
			and rnd(1.0) <= chanceToLeaveStall {
		
		do leaveStallAction;
	}
	
	action leaveStallAction {
		
		do start_conversation to: [targetStall] performative: 'subscribe' 
				contents: [leaveStallMsg];
						
		targetStall <- nil;
		targetPlace <- nil;
		inStall <- false;
	}
	
	reflex inviteForDrinkOption when: inStall and !inviteForDrinkOptionChecked {
		
		bool generousEnough <- generous > valueForGenerousEnough;
		bool invite <- rnd(1.0) <= chanceToInviteSomeoneForDrink;
		
		if(generousEnough and invite) {
			do start_conversation to: [targetStall] performative: 'cfp'
					contents: [inviteSomeoneForDrink];
		}
		
		inviteForDrinkOptionChecked <- true;
	}
	
	reflex acceptDrinkInvitation when: !empty(proposes) {
		
		loop p over: proposes {
			list<unknown> c <- p.contents;
			
			if(c[0] = drinkInvitationMsg) {
				generous <- min(generous + incrementGenerous, 1);
				nbDrinkInvitations <- nbDrinkInvitations + 1;
//				write Mover(c[1]).name + ' increased generous value of ' 
//						+ self.name + ' to ' + self.generous;
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

species PartyLover parent: Mover {
	rgb color <- rgb(220, 120, 50);
	
	float noisy <- rnd(0.3, 1.0);
	
	list<string> favouriteMusicGenres <- [any(musicGenres), any(musicGenres)];
	
	reflex askForMusicGenre when: inStall and !oneTimeInteractionDone 
			and targetStall.typeOfStall = typeConcertHall {
		
		do start_conversation to: [targetStall] performative: 'query' 
				contents: [inquireGenreMsg];
		
		oneTimeInteractionDone <- true;
	}
	
	reflex reactOnMusicGenre when: inStall and !empty(queries) {
		
		loop q over: queries {
			list<unknown> c <- q.contents;
			
			if(c[0] = informAboutGenreMsg) {
				do leaveStallIfMusicIsBad receivedMusicGenre: c[1];
			}
		}
	}
	
	action leaveStallIfMusicIsBad(string receivedMusicGenre) {
		
		//write self.name + ' received the music genre ' + receivedMusicGenre;
		
		bool likeReceivedGenre <- favouriteMusicGenres contains receivedMusicGenre;
		bool generousEnoughToStay <- rnd(0.6) <= generous;
		
		if(!likeReceivedGenre and !generousEnoughToStay) {
			
			//write self.name + ' does not like music in ' + targetStall.name + ' and left';
			
			do leaveStallAction;
		}
	}
}

species ChillPerson parent: Mover {
	rgb color <- rgb(120, 120, 120);
	
	float generous <- rnd(0.3, 1.0);
	
	float maximumAcceptedNoiseLevel <- 0.4;
	
	reflex askForFellowGuests when: inStall and !oneTimeInteractionDone {
		
		do start_conversation to: [targetStall] performative: 'request'
				contents: [askForGuestsMsg];
		
		oneTimeInteractionDone <- true;
	}
	
	reflex reactOnFellowGuests when: inStall and !empty(informs) {
		
		loop i over: informs {
			list<unknown> c <- i.contents;
			
			if(c[0] = provideGuestListMsg) {
				do leaveIfOtherGuestsAreTooNoisy guests: c[1];
			}
		}
	}
	
	action leaveIfOtherGuestsAreTooNoisy(list<Mover> guests) {
		
		float noiseLevel <- 0.0;
		
		loop g over: guests {
			noiseLevel <- noiseLevel + g.noisy;
		}
		
		noiseLevel <- noiseLevel / length(guests);
		
		if(noiseLevel > maximumAcceptedNoiseLevel) {
			
			//write self.name + ' finds it too noisy in ' + targetStall.name + ' and left';
			
			do leaveStallAction;
		}
	}
}

species Criminal parent: Mover control: simple_bdi {
	rgb color <- rgb(75, 75, 180);
	float size <- 1.5;
	
	// BDI
	point theftTarget;
	int stolenFoodConsumed <- 0;
	
	init {
		do add_desire(findFood);
	}
	
	perceive target: Pub where (each.stealableFood > 0) in: sightDistance {
		focus id: pubAtLocation var: location;
		ask myself{
			do remove_intention(findFood, false);
		}
	}
	
	rule belief: pubLocation new_desire: hasFood strength: 1.0;
	rule belief: hasFood new_desire: consumeFood strength: 2.0;
	
	plan wander intention: findFood {
		do wander;
	}
	
	plan stealFood intention: hasFood {
		if(theftTarget = nil) {
			do add_subintention(get_current_intention(), choosePub, true);
			do current_intention_on_hold();
		}
		else {
			do goto target: theftTarget;
			if(theftTarget = location) {
				Pub currentPub <- Pub first_with (theftTarget = each.location);
				if(currentPub.stealableFood > 0) {
					do add_belief(hasFood);
					ask Pub {
						stealableFood <- stealableFood - 1;
					}
				}
				else {
					do add_belief(new_predicate(emptyPubLocation, ["locationValue"::theftTarget]));
				}
				theftTarget <- nil;
			}
		}
	}
	
	plan chooseClosestPub intention: choosePub instantaneous: true {
		
		list<point> possiblePubs <- get_beliefs_with_name(pubAtLocation) collect 
				(point(get_predicate(mental_state(each)).values["location_value"]));
		write "1. Possible pubs: " + possiblePubs;
		list<point> emptyPubs <- get_beliefs_with_name(emptyPubLocation) collect 
				(point(get_predicate(mental_state(each)).values["location_value"]));
		write "Empty pubs: " + emptyPubs;
		
		possiblePubs <- possiblePubs - emptyPubs;
		
		write "Possible pubs: " + possiblePubs;
		
		if(empty(possiblePubs) or possiblePubs = nil) {
			do remove_intention(hasFood, true);
			write "EMTPY PUB LIST!";
			
		}
		else {
			write "PUB LIST AVAILABLE!";
			write possiblePubs;
			theftTarget <- (possiblePubs with_min_of (each distance_to self)).location;
		}
		do remove_intention(choosePub, true);
	}
	
	plan leavePubUnnoticed intention: consumeFood {
		point awayFromTheftPub <- {0.0, 0.0};
		
		loop while: (distance_to(awayFromTheftPub, theftTarget.location) < 4.0) {
			awayFromTheftPub <- {rnd(0, float(gridWidth)), rnd(0, float(gridHeight))};
		}
		
		do goto target: awayFromTheftPub;
		
		if(awayFromTheftPub = location) {
			do remove_belief(hasFood);
			do remove_intention(consumeFood, true);
			stolenFoodConsumed <- stolenFoodConsumed + 1;
		}
	}
	

	// REFLEXES
	
	reflex askIfKitchenIsOpen when: inStall and !oneTimeInteractionDone 
			and targetStall.typeOfStall = typePub {
		
		do start_conversation to: [targetStall] performative: 'query' 
				contents: [inquireKitchenMsg];
		
		oneTimeInteractionDone <- true;
	}
	
	reflex reactOnKitchenInformation when: inStall and !empty(queries) {
		
		loop q over: queries {
			list<unknown> c <- q.contents;
			
			if(c[0] = informAboutKitchenMsg) {
				do stealFoodIfHungryAndLeaveStall kitchenIsOpen: bool(c[1]);
			}
		}
	}
	
	action stealFoodIfHungryAndLeaveStall(bool kitchenIsOpen) {
		
		bool criminalIsHungryEnough <- hungry >= 0.5;
		
		if(kitchenIsOpen and criminalIsHungryEnough) {
			
			//write self.name + ' stole food in ' + targetStall.name + ' and left';
			
			do leaveStallAction;
		}
	}
}

grid Cell width: gridWidth height: gridHeight neighbors: 4 {}

experiment EnjoyFreeTime type: gui {
 
	parameter "Width of grid: " var: gridWidth min: 10 max: 100 
			category: "Grid Size";
	parameter "Height of grid: " var: gridHeight min: 10 max: 100 
			category: "Grid Size";
	
	parameter "Number of Pubs: " var: nbPubs min: 1 max: 10 
			category: "Number of Stalls";
	parameter "Number of Conert Halls: " var: nbConcertHalls min: 1 max: 10 
			category: "Number of Stalls";
			
	parameter "Number of Party Lovers: " var: nbPartyLovers min: 20 max: 50 
			category: "Number of Movers";
	parameter "Number of Chill People: " var: nbChillPeople min: 20 max: 50 
			category: "Number of Movers";
	parameter "Number of Criminals: " var: nbCriminals min: 10 max: 20 
			category: "Number of Movers";
			
	parameter "Minimum Generosity to Invite for Drink: " var: valueForGenerousEnough min: 0.1 max: 1.0 
			category: "Invitation for Drinks";
	parameter "Chance to Invite for Drink: " var: chanceToInviteSomeoneForDrink min: 0.1 max: 1.0 
			category: "Invitation for Drinks";
	parameter "Increment of Generosity after Drink Invitation: " var: incrementGenerous min: 0.005 max: 0.1 
			category: "Invitation for Drinks";
	
	output {
		display main_display {
			grid Cell lines: #lightgrey;
			
			species Pub;
			species ConcertHall;
			
			species PartyLover;
			species ChillPerson;
			species Criminal;
		}
		display generous_chart {
			chart 'Global Generosity' type: series {
				data 'Global Generosity' value: globalGenerous color: #red;
			}
		}
		display drink_invitations {
			chart 'Drink Invitations' type: series {
				data 'Number Drink Invitations' value: nbDrinkInvitations color: #blue;
			}
		}
	}
}
