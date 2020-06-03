/*
 * Extract and auto-save a slice in a stack
 * 
 * 2020.05.29 - david.barry@crick.ac.uk
 */

macro "Slice Extractor" {

	if(nImages() < 1){
		exit("No images open.");
	}
	
	Stack.getPosition(channel, slice, frame);

	sliceLabel = "" + slice;

	while(lengthOf(sliceLabel) < 3){
		sliceLabel = "0" + sliceLabel;
	}
	
	newTitle = File.nameWithoutExtension() + "_Z" + sliceLabel;
	
	run("Duplicate...", "title=" + newTitle);

	outputPath = File.directory + File.separator + newTitle + ".tiff";

	print("Current slice saved to " + outputPath);
	
	saveAs("Tiff", outputPath);
	
	close();

}