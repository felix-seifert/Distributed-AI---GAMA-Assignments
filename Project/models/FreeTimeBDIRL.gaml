/**
* Name: FreeTime
* Model which simulates different humanoid entities who spend their free time and interact with each other.
* BDI: DustBots collect trash and communicate among them about trash quantities of pubs.
* RL: ConcertHalls interact with PartyLovers to discover music tastes to adapt MusicGenre for next concert.
* Author: Marco Molinari <molinarimarco8@gmail.com>, Felix Seifert <mail@felix-seifert.com>
*/

model FreeTime

global {
	
	int gridWidth <- 10;
	int gridHeight <- 10;
	bool displayEntityName <- false;

	int nbPubs <- 2;
	int nbConcertHalls <- 2;
	
	int nbPartyLovers <- 50;
	int nbChillPeople <- 50;
	int nbCriminals <- 10;
	int nbDustBots <- 3;
	int nbRecycleStations <- 1;
	
	int nbAllMovers <- nbPartyLovers + nbChillPeople + nbCriminals;
	
	float valueForGenerousEnough <- 0.4;
	float incrementGenerous <- 0.005;
	float chanceToInviteSomeoneForDrink <- 0.5;
	
	list<Stall> stalls <- [];
	list<string> musicGenres <- ['Rock', 'Metal', 'Blues', 'Funk', 'Hip Hop'];
	
	string typePub <- 'pub';
	string typeConcertHall <- 'concert-hall';
	
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
	
	int nbDrinkInvitations <- 0;
	float globalGenerous <- 0.0;
	
	emotion joy <- new_emotion("joy");
	
	// RL
	int changeMusicTasteThreshold <- 92;	
	
	// BDI
	RecycleStation festivalRecycleCenter;
    
    string pubAtLocation <- "pubAtLocation";
    string emptyPubLocation <- "emptyPubLocation";

    predicate pubLocation <- new_predicate(pubAtLocation);
    predicate choosePub <- new_predicate("choose a pub");
    predicate hasTrash <- new_predicate("extract trash");
    predicate findTrash <- new_predicate("find trash");
    predicate bringTrashToRecycle <- new_predicate("bring trash to recycle");
    predicate shareInformation <- new_predicate("share information");
        
    int globalTrash <- 0;
    int communicationIndex <- 0;
	
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
		create DustBot number: nbDustBots;
		
		create RecycleStation {
            festivalRecycleCenter <- self;
 			self.location <- {gridWidth*5, gridHeight*5};
        }
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
	bool printed <- false;
	
	int trashAccumulated <- rnd(5,10);
	
	reflex openKitchen when: !kitchenIsOpen and currentCycle >= kitchenClosedCycles {
		kitchenIsOpen <- true;
		currentCycle <- 0;
		//write self.name + " Accumulated trash: " + string(trashAccumulated);
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
				trashAccumulated <- trashAccumulated + rnd(1,5);
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
	
	//###RL
	list<PartyLover> knownPartyLovers <- [];
	list<string> musicTasteDistribution <- [];
	list<int> musicTasteCount <- [0,0,0,0,0];
	int totalCount <- 0;
	list<float>probabilities <- [0.0,0.0,0.0,0.0,0.0];
	list<float>probabilityPerturbations <- [0.0,0.0,0.0,0.0,0.0];
	list<float>probabilitiesAfterPerturbation <- [0.0,0.0,0.0,0.0,0.0];
	string electedConcertGenre <- "";
	string choosenConcertGenre <- "";
	string previousMusicGenre <- "";
	float maxFashionDecay <- rnd(-0.5,0.0);
	
	
	action updateMusicPlanning {
		musicTasteDistribution <- [];
		musicTasteCount <- [];
	
		loop pl over: knownPartyLovers{
			add pl.favouriteMusicGenres[0] to: musicTasteDistribution;
			add pl.favouriteMusicGenres[1] to: musicTasteDistribution;
		}
		
		//write musicTasteDistribution;
		
		totalCount <- 0;
		
		loop mg over: musicGenres {
			add (musicTasteDistribution count (each = mg)) to: musicTasteCount;
			totalCount <- totalCount + (musicTasteDistribution count (each = mg));
		}
		
		//write musicTasteCount;
		
		loop i from: 0 to: length(musicGenres) - 1 {
			probabilities[i] <- musicTasteCount[i] / totalCount;
		}
		
		//write "probabilities: " + string(probabilities);
		loop p from: 0 to: length(probabilities)-1{
			probabilitiesAfterPerturbation[p] <- probabilities[p] + probabilityPerturbations[p];
		}
		
		//write probabilitiesAfterPerturbation;
		//write max(probabilitiesAfterPerturbation);
		//write probabilitiesAfterPerturbation index_of max(probabilitiesAfterPerturbation);
		
		electedConcertGenre <- musicGenres[probabilitiesAfterPerturbation index_of 
				max(probabilitiesAfterPerturbation)];
		
		if(electedConcertGenre = previousMusicGenre) {
			if(probabilityPerturbations[probabilities index_of max(probabilities)] < maxFashionDecay) {
				probabilityPerturbations[probabilities index_of max(probabilities)] <- 
						probabilityPerturbations[probabilities index_of max(probabilities)] - 0.05;	
			}
			return;
		}
		probabilityPerturbations[probabilities index_of max(probabilities)] <- 0.0;
		previousMusicGenre <- electedConcertGenre;
		choosenConcertGenre <- electedConcertGenre;
		probabilityPerturbations[probabilities index_of max(probabilities)] <- 
				probabilityPerturbations[probabilities index_of max(probabilities)] + 0.2;
	}
	
	// BASE	
	reflex startNewConcert when: currentCycle > concertCycles {
		currentCycle <- 0;
		currentConcertGenre <- choosenConcertGenre;
		//write self.name + ' started concert with genre ' + currentConcertGenre;
	}
	
	reflex informAboutMusicGenre when: !empty(queries) {
		loop q over: queries {
			list<unknown> c <- q.contents;
			if(!(q.sender in knownPartyLovers)) {
				add q.sender to: knownPartyLovers;	
			}
			if(c[0] = inquireGenreMsg) {
				do query message: q contents: [informAboutGenreMsg, currentConcertGenre];
			}
		}
		do updateMusicPlanning;
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
	
	//###RL
	int changeMusicTaste <- rnd(0, 100);
	
	//###BASE
	reflex considerNewMusicGenre when: changeMusicTaste > changeMusicTasteThreshold {
		favouriteMusicGenres[rnd(1)] <- any(musicGenres);
	}
	
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

species Criminal parent: Mover {
	rgb color <- rgb(75, 75, 180);
	
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

species RecycleStation {
	
    int totalTrashCollected;
    
    aspect default {
        draw square(5) color: #black ;
    }
}

species DustBot skills: [moving] control: simple_bdi {
	//###BDI
	rgb color <- rgb(235, 255, 255);
	float sightDistance<-50.0;
    point target;
    int trashCurrentlyHeld;
    int totalTrashCollected;
    int trashCapacity <- 5;
    list<point> knownPubLocations <- [];
    
    bool use_social_architecture <- true;
    bool use_emotions_architecture <- true;
    bool use_personality <- true;
    
    float openness <- gauss(0.5,0.12);
    float conscientiousness <- gauss(0.5,0.12);
    float extraversion <- gauss(0.5,0.12);
    float agreeableness <- gauss(0.5,0.12);
    float neurotism <- gauss(0.5,0.12);
    
    float plan_persistence <- 1.0;
    float intention_persistence <- 1.0;
    
    int personalCommunicationIndex <- 0;
    
    init {
        do add_desire(findTrash);
    }
    
    perceive target: DustBot in: sightDistance {
		do add_desire(predicate: shareInformation, strength: 5.0);
    }
        
    perceive target: Pub where (each.trashAccumulated > 0) in: sightDistance {
        focus id: pubAtLocation var: location;
        ask myself {
            if(has_emotion(joy)) {
                do add_desire(predicate: shareInformation, strength: 5.0);
            }
            do remove_intention(findTrash, false);
        }
    }
    
    rule belief: pubLocation new_desire: hasTrash strength: 2.0;
    rule belief: hasTrash new_desire: bringTrashToRecycle strength: 3.0;
    
    plan randomMove intention: findTrash {
    	do wander;
        target <- one_of(knownPubLocations);
        do goto target: target;
    }
    
    plan chooseClosestPub intention: choosePub instantaneous: true {
    	
        list<point> possiblePubs <- get_beliefs_with_name(pubAtLocation) 
        		collect (point(get_predicate(mental_state (each)).values["location_value"]));
        add possiblePubs[rnd(0,length(possiblePubs)-1)] to: knownPubLocations;
        
        list<point> emptyPubs <- get_beliefs_with_name(emptyPubLocation) 
        		collect (point(get_predicate(mental_state (each)).values["location_value"]));
        possiblePubs <- possiblePubs - emptyPubs;
        
        if(empty(possiblePubs)) {
            do remove_intention(hasTrash, true); 
        }
        else {
            target <- (possiblePubs with_min_of (each distance_to self)).location;
        }
        do remove_intention(choosePub, true);
    }
        
    plan getTrash intention: hasTrash  {
    	
        if(target = nil) {
            do add_subintention(get_current_intention(),choosePub, true);
            do current_intention_on_hold();
        }
        else {
            do goto target: target;
            
            if(target = location)  {
                Pub currentPub<- Pub first_with (target = each.location);
                if(currentPub.trashAccumulated > 0 and trashCurrentlyHeld<trashCapacity) {
                     do add_belief(hasTrash);
                     ask currentPub {
                     	myself.trashCurrentlyHeld <- 
                     			myself.trashCurrentlyHeld + min(myself.trashCapacity, trashAccumulated);
                     	trashAccumulated <- max(0, trashAccumulated - myself.trashCapacity);
                     }     
                    //write self.name + ": I collected trash!";
                } 
//                else if(trashCurrentlyHeld=trashCapacity) {
//               		write self.name + ": My bag is full!";
//                }
                else {
                	do add_belief(new_predicate(emptyPubLocation, ["location_value"::target]));
                }
                target <- nil;
            }
        }    
    }
    
    plan goToRecycleStation intention: bringTrashToRecycle {
        do goto target: festivalRecycleCenter;
        
        if(festivalRecycleCenter.location = location) {
            do remove_belief(hasTrash);
            do remove_intention(bringTrashToRecycle, true);
            //write "BRINGING THIS MUCH TRASH: " + trashCurrentlyHeld;
            festivalRecycleCenter.totalTrashCollected <- 
            		festivalRecycleCenter.totalTrashCollected + trashCurrentlyHeld;
            totalTrashCollected <- totalTrashCollected + trashCurrentlyHeld;
            trashCurrentlyHeld <- 0;
            //write "TOTAL TRASH HOLD: " + festivalRecycleCenter.totalTrashCollected;
        }
    }
    
    plan shareInfrormation intention: shareInformation instantaneous: true {
		list<DustBot> otherDustBots <- list(DustBot);
		
        loop knownPub over: get_beliefs_with_name(pubAtLocation) {
            ask otherDustBots {
                do add_belief(knownPub);
            }
        }
        
        loop knownEmptyPub over: get_beliefs_with_name(emptyPubLocation) {
            ask otherDustBots {
                do add_belief(knownEmptyPub);
            }
        }
        
        personalCommunicationIndex <- personalCommunicationIndex + 1;
        communicationIndex <- communicationIndex + 1;
        do remove_intention(shareInformation, true); 
    }

    aspect default {
        draw circle(trashCurrentlyHeld/3 + 1) color: color border: #black depth: totalTrashCollected;
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
	parameter "Number of DustBots: " var: nbDustBots min: 0 max: 10 
			category: "Number of Movers";
			
	parameter "Minimum Generosity to Invite for Drink: " var: valueForGenerousEnough 
			min: 0.1 max: 1.0 category: "Invitation for Drinks";
	parameter "Chance to Invite for Drink: " var: chanceToInviteSomeoneForDrink 
			min: 0.1 max: 1.0 category: "Invitation for Drinks";
	parameter "Increment of Generosity after Drink Invitation: " var: incrementGenerous 
			min: 0.005 max: 0.1 category: "Invitation for Drinks";
			
	parameter "Change Music Taste Threshold" var: changeMusicTasteThreshold 
			min: 0 max: 100 category: "Reinforcement Learning";		

	output {
		display main_display {
			grid Cell lines: #lightgrey;
			
			species Pub;
			species ConcertHall;
			species PartyLover;
			species ChillPerson;
			species Criminal;
			species DustBot;
			species RecycleStation;
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
				
		display trashChartBDI {
			chart 'Global Trash' type: series {
				loop p over: list(Pub) {
					data p.name value: p.trashAccumulated;
				}
				data 'Communication Index' value: communicationIndex/10 color: #green;
			}
		}
		
		display trashCurrentlyHeldChartBDI {
			chart 'Trash Currently Held' type: series {
				loop element over: list(DustBot) {
					data element.name value: element.trashCurrentlyHeld;
				}
			}
		}
		
		display totalTrashChartBDI {
			chart 'Total Trash Chart' type: series {
				loop element over: list(DustBot) {
					color <- rnd_color(100,255);
					data element.name value: element.totalTrashCollected color: color;
					data element.name+" PCI: "+ string(element.personalCommunicationIndex) 
							value: element.personalCommunicationIndex/10 color: color;
				}
			}
		}
		
		display ConcertHall0MusicTastes {
			chart "ConcertHall0MusicTastes" type: pie {
				ConcertHall ch <- list(ConcertHall)[0];
				
				loop i from: 0 to: length(musicGenres) - 1 {
					data musicGenres[i] value: ch.musicTasteCount[i];
				}
	        }
	    }
	    
		display ConcertHall1MusicTastes {	        
			chart "ConcertHall1MusicTastes" type: pie {
				ConcertHall ch <- list(ConcertHall)[1];
        		
        		loop i from: 0 to: length(musicGenres) - 1 {
					data musicGenres[i] value: ch.musicTasteCount[i];
				}
	        }
		}
	}
}
