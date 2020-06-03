// Dave Barry, Francis Crick Institute
// 2018.01.17
// david.barry@crick.ac.uk

// Converts all files in a directory to TIFF - there will be one TIFF file per channel per input file.

macro "Coloc Quant"{

	colocQuant = "Coloc Quant";
	directory = getDirectory("Choose input files");
	
	outputDirectory = getDirectory("Choose output directory");
	IJ.log("Output: " + outputDirectory);

	minNucSize = 3;
	minCellSize = 100;
	threshMethod = "Huang";
	threshMethods =  getList("threshold.methods");

	Dialog.create(colocQuant);
	Dialog.addChoice("Threshold Method", threshMethods, threshMethod);
	Dialog.addNumber("Minimum Nuclear Size", minNucSize);
	Dialog.addNumber("Minimum Cell Size", minCellSize);
	Dialog.show();

	threshMethod = Dialog.getChoice();
	minNucSize = Dialog.getNumber();
	minCellSize = Dialog.getNumber();
	
	setBatchMode(true);

	processFolder(directory);
	
	IJ.log("\nFinished");
	showStatus("Finished.");
	setBatchMode(false);
	
	function processFolder(input) {
		IJ.log("Analysing " + input);
		fileList = getFileList(input);
		IJ.log(fileList.length + " files found.");
		fileList = Array.sort(fileList);
		for (i = 0; i < fileList.length; i++) {
			if(File.isDirectory(input + File.separator + fileList[i])){
				processFolder(input + File.separator + fileList[i]);
			}
			run("Bio-Formats Macro Extensions");
			file = input + fileList[i];
			Ext.isThisType(file, thisType);
			if(thisType=="true"){
				IJ.log("\nFile " + file + " is a recognised format - processing.");
				Ext.setId(file);
				Ext.getSeriesCount(sCount);
				IJ.log("Number of series: " + sCount);
				
				for(s=0;s<sCount;s++){
					Ext.setSeries(s);
					IJ.log("Analysing series " + s);
					Ext.getSizeC(sizeC);
					IJ.log("Number of channels: " + sizeC);
					if(sizeC > 2){
						Ext.openImagePlus(file);
						title = getTitle();
						run("Split Channels");
						imageTitles = getList("image.titles");
						Array.sort(imageTitles);
						
						imageCalculator("Add create 32-bit", imageTitles[1], imageTitles[2]);
						channel2Plus3 = getTitle();
						run("Gaussian Blur...", "sigma=2");
						setAutoThreshold(threshMethod + " dark");
						run("Convert to Mask");
						
						selectWindow(imageTitles[0]);
						run("Gaussian Blur...", "sigma=2");
						setAutoThreshold(threshMethod + " dark");
						run("Convert to Mask");
						run("Options...", "iterations=" + minNucSize + " count=1 black do=Open");
						run("Voronoi");
						setThreshold(1, 255);
						run("Convert to Mask");
						
						imageCalculator("Subtract create", channel2Plus3, imageTitles[0]);
						regionImage = getTitle();
					
						run("Analyze Particles...", "size=" + minCellSize + "-Infinity exclude include add");
						cellCount = roiManager("count");
						selectWindow(imageTitles[1]);
					
						for(r = 0; r < cellCount; r++){
							roiManager("select", r);
							run("CALM Macro Extensions");
							Ext.runImageCorrelation(imageTitles[1], imageTitles[2], title + "_Cell_" + r);
							run("Bio-Formats Macro Extensions");
						}
						close("*");
						Ext.openImagePlus(file);
						run("Make Composite");
						run("Stack to RGB");
						roiManager("show all with labels");
						run("Flatten");
						saveAs("png", outputDirectory + File.separator + title + "_" + colocQuant + "_Output.png");
						roiManager("reset");
						close("*");
					} else {
						IJ.log("\nFile " + file + " does not have a sufficient number of channels - skipping.");
					}
				}
				Ext.close();
			} else {
				IJ.log("\nFile " + file + " is not a recognised format - skipping.");
			}
		}
	}
}