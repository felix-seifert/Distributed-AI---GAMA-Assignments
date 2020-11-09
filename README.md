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
