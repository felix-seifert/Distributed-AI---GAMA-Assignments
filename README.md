# Memory of agents (small brain)

To define the parameters for the interaction with the peers and the memory:

species Visitor skills: [moving] {
 
	float exploitingMemoryRate <- 0.5;	//how much a Visitor relies on its memory about restarants/bars
	float exploitingMemoryVariation <- 0.1; //Variation (+,-)for each memory change, depending on the use of the memory
	bool allowInteraction <- true; //  set this to false to deny the use of interaction between Visitors
	bool allowMemory <- true; //set this to false to deny the use of the memory
 	list<Stall> locationMemory; //list of the location memories

... }


To visit the available memory for each Visitor:

	reflex visitKnownStall when: targetStall = nil and self.locationMemory != [] and flip(exploitingMemoryRate) and (foodStorage = 0 or drinksStorage = 0) and !(self.witnessedBadBehaviour) and allowMemory{
		self.exploitingMemoryRate <- max(self.exploitingMemoryRate - exploitingMemoryVariation, 0); //modify the rely on the memory for the next choices
		self.targetStall <- self.locationMemory[rnd(length(self.locationMemory) - 1)]; // pick one random location memory as new destination
		//write self.exploitingMemoryRate;
	}
  
  The memory availability won't be a constant value through the time: the more a Visitor uses its memory, the less he'll use it later (and vice versa).
  The Stand will be chosen randomly from the MemoryList.
  
 The memories about the Stand locations can be improved in two ways:
 
 1) Through the interaction with the peers. There's an interactionRate that will limit the possibility of exchanging information (to contain the explosion of knowledge to happen too fast). If a peer is in the range of communicationDistance, an interaction may happen. This attempt will be highlighted in yellow on the icon of the asking Visitor. If an exchange of new information happens, it will highlighted in orange.
 
 	reflex interactWithVisitor when: targetStall = InformationCentre closest_to(self) and flip(interactionRate) and (foodStorage = 0 or drinksStorage = 0) and !(self.witnessedBadBehaviour) and allowInteraction{
		if (Visitor at_distance(communicationDistance) != []){ //interaction between Visitors to exchange missing information about stalls locations

			ask (Visitor closest_to(self)) {
				myself.color <- rgb(252, 186, 3); //the Visitor becomes yellow when interacts with another Visitor
				if (self.locationMemory - myself.locationMemory != []) { //Difference of memory to understand if there's any potential new location learnable
					add (self.locationMemory - myself.locationMemory)[length(self.locationMemory - myself.locationMemory) - 1] to: myself.locationMemory;
					//write myself.name + " got the location of " + string(myself.locationMemory[length(myself.locationMemory) - 1]) + " from " + self.name;
					myself.targetStall <- myself.locationMemory[length(myself.locationMemory) - 1]; //improves the memory parameter for next choices
					//write myself.locationMemory;
					//myself.size <- myself.size + 1;
					myself.color <- rgb(252, 107, 3); //the Visitor becomes orange if it receives a new location
					//draw string(length(Visitor at_distance(communicationDistance))) color: #black;
					//draw polyline([self.location, myself.location]) color: rgb(252, 107, 3);
					self.exploitingMemoryRate <- min(self.exploitingMemoryRate + exploitingMemoryVariation, 1);
					successfulInteractions <- successfulInteractions + 1;
					//write "Successful interactions: " + successfulInteractions;
					//write self.exploitingMemoryRate;
				}
			}
		}
	}
  
  
2) Through the interaction with a new Stand suggested by the last visited Information Centre, that may remain (90% of chances) in the memory of the Visitor:

	reflex interactWithStall when: targetStall != nil and location distance_to(targetStall.location) < 2 and !(self.witnessedBadBehaviour){
		//Interaction with the different stalls (for food/drink)
 
 ...
 
		ask targetStall {
			if(flip(memoryRate) and !(self in myself.locationMemory)) {
				add self to: myself.locationMemory;
				//write myself.name + " will remember the location of " + string(self);
			}
      
 ...}
 
 Even though it has been omitted from the code for simplicity, a variable float forgetRate <- 0.0005 was created to generate a random memory loss in one of the Visitors, in order to balance to an equilibrium point their explosion of knowledge. In any case, the puropose of this challenge is to show how improved are the Visitors' exploring performances thanks to the enhancement of the memory and the interaction between peers. By checking the length of the average locationMemory (where are allocated the location memory slots of each agent) through the time, it is possible to understand how this positively affects the performances of the Visitors exploration (both in term of time and meters walked).
 
 
 ___________________________
 
 
# Removing bad behaving agents
(For simplicity I excluded the code for allowing the Guards to also perform direct supervision and not just by being warned by a Visitor.)

Variables set up:

	float guardRange <- 4.0; //range for checking bad behaviours among other Visitors
	int totalBadBehaving <- 0; //counter of all the bad behaviours
	int totalCaughtBadBehaving <- 0; //counter of deads
	float criminalRate <- 0.003; //every Visitors have a chance of rnd(0, criminalRate)*100% to commit a bad action
	list<Visitor> criminalVisitors <- []; //list of reported Visitors
	bool badBehaviour <- false; //true for Visitors that badly behave
	bool badBehaviourCaught <- false; //true if the Visitor gets caught by another Visitor
	bool visitorDie <- false;

	float badBehaviourRate <- rnd(-criminalRate/4, criminalRate);
	bool witnessedBadBehaviour <- false; //true if a Visitor witnessed the bad behaviour of another Visitor
	list<Visitor> badBehaviourVisitorsOnSight <- [];
	list<Visitor> visitorsOnSight <- [];

	bool goingToInformationCentreToReport <- false; //true if the Agent is ...
	bool goingToGuardToReport <- false; // true if the Agent is ...
	bool goingToBadBehaviourVisitorToReport <- false; //true if the Agent is ...
	
	Stall targetStall <- nil;
	Guard targetGuard <- nil;
	Visitor caughtVisitor <- nil;
	

The first step consist in allowing the Visitors to check around them for peers with the positive flag on badBehaviour,


	reflex discoverBadVisitor when: !(self.witnessedBadBehaviour) { //function to discover badly behaving Visitors around
		if (Visitor at_distance(guardRange) != []){
			self.visitorsOnSight <- Visitor at_distance(guardRange);
 
			loop visitorOnSight over: self.visitorsOnSight{
				
				if((visitorOnSight.badBehaviour = true) and !(visitorOnSight in self.badBehaviourVisitorsOnSight)){
					add visitorOnSight to: self.badBehaviourVisitorsOnSight;
				}
			}
				
			if(self.badBehaviourVisitorsOnSight!=[]){
				
				witnessedBadBehaviour <- true;
				
				goingToInformationCentreToReport <- true;

				caughtVisitor <- self.badBehaviourVisitorsOnSight[0];
				
				//write string(self) + " discovered " + string(self.badBehaviourVisitorsOnSight[0]) + " bad behaving.";					
			
			}
		}
	}


that can randomly result true as follows (when there's an interaction Visitor-Stall):

	if(flip(myself.badBehaviourRate)) {
		myself.badBehaviour <- true;
		myself.color <- rgb(255, 0, 234);
		//write "Bad Behaviour!";
		totalBadBehaving <- totalBadBehaving + 1;
		//write "Total Bad Behaving :" + totalBadBehaving;
	}


If a Visitor is able to catch another Visitor in a criminal action, it will save its ID in the memory. The criminal will have the value badBehavioursCaught turn to positive. The witness will then proceed to the closest Information Centre:

	reflex goToInformationCentreToReport when: goingToInformationCentreToReport = true {
		targetGuard <- nil;
		targetStall <- InformationCentre closest_to(self);
		
		if (location distance_to(targetStall) < 2.0){
			goingToInformationCentreToReport <- false;
			goingToGuardToReport <- true;
			
			if caughtVisitor in criminalVisitors or dead(caughtVisitor) { //if the criminal was already reported, free the Visitor
				
				caughtVisitor <- nil;
				targetGuard <- nil;
				targetStall <- one_of(InformationCentre); //restart from one InformationCentre
				witnessedBadBehaviour <- false;				
				goingToGuardToReport <- false;
				goingToInformationCentreToReport <- false;
				goingToBadBehaviourVisitorToReport <- false;
				badBehaviourVisitorsOnSight <- [];
				
				return;
				
			}
			
			else {
				
				add caughtVisitor to: criminalVisitors;				
			}
			//write string(self) + " reported " + string(caughtVisitor) + " to the information centre.";
			
		}
	}


Once the Visitor arrives at the Information Centre, he will check that the criminal he caught wasn't already been signaled to the Guard - or already been removed from the simulation through the die command; as many Visitors can report the same crime as witnesses.

If the crime wasn't reported before, the Visitor will be put in the direction of one Guard:

	reflex goToGuardToReport when: goingToGuardToReport = true {
		
		targetStall <- nil;
		targetGuard <- one_of(Guard);
		
		if targetGuard.badBehaviourVisitorsOnSight = []{
			if (location distance_to(targetGuard) < communicationDistance){
				
				ask targetGuard {
					self.followWitnessVisitor <- true;
					add myself.caughtVisitor to: self.badBehaviourVisitorsOnSight;
				}
				
				goingToGuardToReport <- false;
				goingToBadBehaviourVisitorToReport <- true;
				//write string(self) + " reported " + string(caughtVisitor) + " to " + string(targetGuard);
			}	
		}
	}

This will make the Guard acknowledges of the criminal identity:

	reflex identifyBadBehaviourVisitor when: (followWitnessVisitor = true and badBehaviourVisitorsOnSight!=[]) { //identify the suspect
 
		ask self.badBehaviourVisitorsOnSight {
			
			self.badBehaviourCaught <- true;
			
			//write string(myself) + " identified " + string(self);
			
			myself.goToBadBehaviourVisitor <- true;
		}
		
		followWitnessVisitor <- false;
	}
	
	
Guard variables set up:

	list<Visitor> badBehaviourVisitorsOnSight <- []; //list of bad behaving Visitors in guardRange
	list<Visitor> visitorsOnSight <- []; //list of all Visitors in guardRange
	bool followWitnessVisitor <- false; //true if the Guard is following a Visitor reporting another Visitor
	bool goToBadBehaviourVisitor <- false; //true if the Guard is headed to capture the criminal


Once located on the map the suspect, the Guard will reach it:

	reflex moveToTarget when: goToBadBehaviourVisitor = true { //get closer to the suspect
		
		if (self distance_to(badBehaviourVisitorsOnSight[0]) > 2.0) {
			do goto target: badBehaviourVisitorsOnSight[0];
		}
		
		else{
			
			//write string(badBehaviourVisitorsOnSight[0]) + " was caught misbehaving by " + string(self);
			goToBadBehaviourVisitor <- false;
			
			ask self.badBehaviourVisitorsOnSight[0] {
				self.visitorDie <- true; //if true, triggers the considered Visitor to leave the simulation
				myself.badBehaviourVisitorsOnSight <- []; //empties the list of criminals and restart
				
			}			
		}
	}
	
Once arrived, he will delete the suspect agent from the simulation and reset its Guard job.

Due to some particular conditions of the Stalls disposition on the map, it may happens that the crime-reporting Visitors will constantly follow the Guard. This is one of the "safe" fix to prevent this problem:

	reflex stopHelpingGuard when: badBehaviourVisitorsOnSight != [] and dead(caughtVisitor) { //Stop following the guard once the arrest is done
		caughtVisitor <- nil;
		targetGuard <- nil;
		targetStall <- one_of(InformationCentre); //Restart from one Information Centre
		witnessedBadBehaviour <- false;
		goingToBadBehaviourVisitorToReport <- false; //true if the Visitor is following the Guard to show the criminal's position
		badBehaviourVisitorsOnSight <- [];
	}
