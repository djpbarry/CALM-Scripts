// Dave Barry, Francis Crick Institute
// 2018.06.26
// david.barry@crick.ac.uk

// Copies slice label names from one stack to another

macro "Copy Stack Labels"{

	imageList = getList("image.titles");
	
	Dialog.create("Copy Stack Slice Labels");
	Dialog.addChoice("Source:", imageList);
	Dialog.addChoice("Destination:", imageList);
	Dialog.show();
	source = Dialog.getChoice();
	dest = Dialog.getChoice();
	
	selectImage(source);
	N = nSlices();
	
	selectImage(dest);
	if(nSlices() != N){
		exit("Stacks must contain same number of slices.");
	}
	
	for(i = 1; i <= N; i++){
		selectImage(source);
		setSlice(i);
		label = getInfo("slice.label");
		selectImage(dest);
		setSlice(i);
		setMetadata("Label", label);
	}

}