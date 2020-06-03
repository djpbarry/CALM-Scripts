// Dave Barry, Francis Crick Institute
// 2018.04.05
// david.barry@crick.ac.uk

// Performs template matching, then filters detected positives based on signal in a third channel

var title = "Template Matcher";
var image = "";
var template = "";
var threshImage = "";
var threshMethod = "";
var corrThresh = 0.75;

macro "Template Matcher"{
	showDialog();
	
	selectWindow(image);
	n1 = nSlices();
	selectWindow(threshImage);
	if(n1 != nSlices()){
		exit("Bead and cell marker stacks must have same number of slices");
	}
	selectWindow(template);
	if(nSlices() > 1){
		exit("Template image must be a single slice.");
	}
	
	run("TemplateMatching Extensions");
	Ext.runTemplateMatcher(image, template, corrThresh);
	resultTitle = getTitle();
	count = Overlay.size;
	run("To ROI Manager");
	selectWindow(threshImage);
	run("From ROI Manager");
	roiManager("deselect");
	roiManager("delete");
	print("Filtering Rois...");
	thresholds = newArray(nSlices());
	for(s=1;s<=nSlices(); s++){
		setSlice(s);
		setAutoThreshold(threshMethod + " dark");
		getThreshold(thresholds[s-1], upper);
	}
	resetThreshold();
	outputRois = newArray(count);
	index = 0;
	for(i=0; i<count; i++){
		Overlay.activateSelection(i);
		getRawStatistics(area, mean, min, max, std, histogram);
		//print(getSliceNumber() + ": index: "+ i + " mean: "+ mean+" threshold: "+ thresholds[getSliceNumber() - 1]);
		if(mean < thresholds[getSliceNumber() - 1]){
			outputRois[index] = i;
			index++;
		}
	}
	for(i=0; i<index; i++){
		Overlay.removeSelection(outputRois[i] - i);
	}
	run("To ROI Manager");
	close(resultTitle);
	print("Finished");
	
	function showDialog(){
		images = getList("image.titles");
		methods = getList("threshold.methods");
		Dialog.create(title);
		Dialog.addChoice("Specify bead image stack:", images);
		Dialog.addChoice("Specify cell marker image stack:", images);
		Dialog.addChoice("Specify template image:", images);
		Dialog.addChoice("Specify cell threshold method:", methods);
		Dialog.addNumber("Specify correlation threshold:", corrThresh);
		Dialog.show();
		image = Dialog.getChoice();
		threshImage = Dialog.getChoice();
		template = Dialog.getChoice();
		threshMethod = Dialog.getChoice();
		corrThresh = Dialog.getNumber();
	}
}
