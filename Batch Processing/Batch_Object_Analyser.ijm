// Dave Barry, Francis Crick Institute
// 2017.11.28
// david.barry@crick.ac.uk

// Performs a basic morphological analysis. Input (greyscale) images should all
// be presented in a single input directory.

macro "Batch Object Analyser"{
	
	directory = getDirectory("Choose input files");
	IJ.log("Input: " + directory);
	fileList = getFileList(directory);
	IJ.log(fileList.length + " files.");
	
	outputDirectory = getDirectory("Choose output directory");
	IJ.log("Output: " + outputDirectory);
	
	run("Bio-Formats Macro Extensions");
	setBatchMode(true);
	run("Set Measurements...", "area shape display redirect=None decimal=3");
	minSize = 0.0;
	file = directory + fileList[0];
	Ext.setId(file);
	Ext.openImagePlus(file);
	getPixelSize(unit, pw,ph);
	minSize = getNumber("Enter minimum object area (" + unit + "): ", minSize);
	for (i=0; i<fileList.length; i++) {
		file = directory + fileList[i];
		IJ.log("\nProcessing " + file);
		Ext.setId(file);
		Ext.openImagePlus(file);
		run("Gaussian Blur...", "sigma=1");
		setAutoThreshold("Intermodes dark");
		setOption("BlackBackground", false);
		run("Convert to Mask");
		run("Options...", "iterations=3 count=1 do=Open");
		run("Analyze Particles...", "size=" + minSize + "-Infinity show=Outlines display exclude include");		
		titles = getList("image.titles");
		for(j=0; j<titles.length; j++){
			if(startsWith(titles[j], "Drawing")){
				selectWindow(titles[j]);
				index = lastIndexOf(titles[j], ".");
				thisTitle = substring(titles[j], 0, index);
				filename = outputDirectory + thisTitle + "_outlines.png";
				IJ.log("Saving " + filename);
				saveAs("PNG", filename);
			}
		}
		close("*");
	}
	
	IJ.log("\nFinished");
	showStatus("Finished.");
	setBatchMode(false);
}