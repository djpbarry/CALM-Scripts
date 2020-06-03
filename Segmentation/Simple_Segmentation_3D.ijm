/*
 * Simple 3D segmentation
 * 
 * Requires MorphoLibJ
 * 
 * 2020.06.03 - david.barry@crick.ac.uk
 */

macro "3D Simple Segmentation"{

	scaleFactor=0.25;
	xySigma = 4/scaleFactor;
	zSigma = 2/scaleFactor;
	morphRadiusXY = 10/scaleFactor;
	morphRadiusZ = 5/scaleFactor;
	threshMethod = "Huang";
	allThreshMethods = getList("threshold.methods");
	
	Dialog.create("Simple 3D Segmentation");
	Dialog.addNumber("Scale Factor", scaleFactor);
	Dialog.addNumber("XY Smoothing Radius", xySigma);
	Dialog.addNumber("Z Smoothing Radius", zSigma);
	Dialog.addNumber("XY Binary Filtering Radius", morphRadiusXY);
	Dialog.addNumber("Z Binary Filtering Radius", morphRadiusZ);
	Dialog.addChoice("Thresholding Method", allThreshMethods, threshMethod);
	Dialog.show();
	
	scaleFactor = Dialog.getNumber();
	xySigma = Dialog.getNumber() * scaleFactor;
	zSigma = Dialog.getNumber() * scaleFactor;
	morphRadiusXY = Dialog.getNumber() * scaleFactor;
	morphRadiusZ = Dialog.getNumber() * scaleFactor;
	threshMethod = Dialog.getChoice();

	setBatchMode(true);

	//Duplicate input and convert
	run("Duplicate...", "duplicate");
	input = getTitle();
	run("32-bit");
	
	
	// blur
	print("Filtering...");
	run("Gaussian Blur 3D...", "x="+xySigma+" y="+xySigma+" z="+zSigma);
	
	
	//Scale
	scaled=getTitle() + " Scaled";
	print("Scaling...");
	run("Scale...", "x="+scaleFactor+" y="+scaleFactor+" z="+scaleFactor+" interpolation=Bicubic average process create title=["+scaled+"]");
	close(input);
	
	
	//Threshold
	selectImage(scaled);
	print("Thresholding...");
	setAutoThreshold("Huang stack");
	setOption("BlackBackground", false);
	run("Convert to Mask", "method=Huang background=Light");
	
	
	//Morphological Filtering
	selectImage(scaled);
	print("Filtering...");
	run("Morphological Filters (3D)", "operation=Opening element=Ball x-radius="+morphRadiusXY+" y-radius="+morphRadiusXY+" z-radius="+morphRadiusZ);
	filtered=getTitle();
	close(scaled);
	
	
	//Labelling
	selectImage(filtered);
	print("Labelling...");
	run("Connected Components Labeling", "connectivity=6 type=[16 bits]");
	labelled = getTitle();
	close(filtered);
	
	//Scale
	selectImage(labelled);
	print("Scaling...");
	scaleFactor=1.0/scaleFactor;
	run("Scale...", "x="+scaleFactor+" y="+scaleFactor+" z="+scaleFactor+" interpolation=None process create");
	rename("Labelled Segmentation");
	close(labelled);
	print("Done.");

	setBatchMode(false);
}
