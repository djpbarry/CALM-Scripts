// Dave Barry, Francis Crick Institute
// 2018.01.17
// david.barry@crick.ac.uk

// Converts all files in a directory to TIFF - there will be one TIFF file per channel per input file.

macro "Wound Quant"{

	woundQ = "Wound Quant";
	woundResults = woundQ + " Results";
	dup = "duplicate";
	run("Text Window...", "name=[" + woundResults + "] width=640 height=480 menu");
	print("[" + woundResults + "]", "Image, Wound Length (" + getInfo("micrometer.abbreviation") + "), Mean Position (" + getInfo("micrometer.abbreviation") + ")\n");
	run("Set Measurements...", "area display redirect=None decimal=0");
	directory = getDirectory("Choose input files");
	IJ.log("Input: " + directory);
	fileList = getFileList(directory);
	IJ.log(fileList.length + " files.");
	
	outputDirectory = getDirectory("Choose output directory");
	IJ.log("Output: " + outputDirectory);

	radius = 1;
	channel = 1;
	threshMethods =  getList("threshold.methods");

	Dialog.create(woundQ);
	Dialog.addChoice("Threshold Method", threshMethods);
	Dialog.addNumber("Filter Radius", radius);
	Dialog.addNumber("Channel to Use", channel);
	Dialog.show();

	threshMethod = Dialog.getChoice();
	radius = Dialog.getNumber();
	channel = Dialog.getNumber();
	
	run("Bio-Formats Macro Extensions");
	setBatchMode(true);
	
	for (i=0; i<fileList.length; i++) {
		file = directory + fileList[i];
		Ext.isThisType(file, thisType);
		if(thisType=="true"){
			IJ.log("\nFile " + file + " is a recognised format - processing.");
			Ext.setId(file);
			Ext.getSeriesCount(sCount);
			Ext.getDimensionOrder(dimOrder);
			IJ.log("Number of series: " + sCount);
	
			for(s=1;s<=sCount;s++){
				run("Bio-Formats Importer", "open=[" + file + "] color_mode=Default rois_import=[ROI manager] specify_range view=Hyperstack stack_order=" + dimOrder + " series_" + s + "c_begin=" + channel + " c_end=" + channel + " c_step=1");
				title = getTitle();
				getPixelSize(unit, pixelWidth, pixelHeight);
				getDimensions(width, height, channels, slices, frames);
				run("Duplicate...", "title=" + dup);
				run("Median...", "radius=" + radius);
				setAutoThreshold(threshMethod + " dark");
				run("Convert to Mask");
				run("Fill Holes");
				run("Analyze Particles...", "size=0-Infinity display add");

				maxArea = -1;
				maxIndex = -1;

				for (n = 0; n < nResults; n++) {
					thisArea = getResult("Area", n);
					if(thisArea > maxArea){
						maxArea = thisArea;
						maxIndex = n;
					}
				}

				selectWindow(title);
				roiManager("select", maxIndex);
				Roi.getCoordinates(xpoints, ypoints);
				
				nPoints = lengthOf(xpoints);
				
				totalDistance = 0;
				totalX = 0;
				count = 0;
				
				for(p = 0; p < nPoints - 1; p++){
					if(xpoints[p] > 0 && xpoints[p + 1] > 0 && xpoints[p] < width - 1 && xpoints[p + 1] < width - 1
					&& ypoints[p] > 0 && ypoints[p + 1] > 0	&& ypoints[p] < height - 1 && ypoints[p + 1] < height - 1){
						totalDistance = totalDistance + measureDistance(xpoints[p], ypoints[p], xpoints[p + 1], ypoints[p + 1]) * pixelWidth;
						totalX = totalX + xpoints[p] * pixelWidth;
						count++;
					}
				}

				Overlay.addSelection;
				Overlay.flatten;
				saveAs("png", outputDirectory + File.separator + title + "_" + woundQ + "_Output.png");
				run("Close");

				print("[" + woundResults + "]", title + ", " + totalDistance + ", " + (totalX / count)  + "\n");
				
				selectWindow("Results");
				run("Close");
					
				roiManager("reset");
				
				close("*");
			}
			Ext.close();
		} else {
			IJ.log("\nFile " + file + " is not a recognised format - skipping.");
		}
	}
	
	selectWindow(woundResults);
	saveAs("text", outputDirectory + File.separator + woundQ + "_results.csv");
	run("Close");
	
	IJ.log("\nFinished");
	showStatus("Finished.");
	setBatchMode(false);
	
	function saveFile(outFile) {
	   run("Bio-Formats Exporter", "save=[" + outFile + "] compression=Uncompressed");
	}

	function measureDistance(x1, y1, x2, y2){
		return sqrt(pow(x2 - x1, 2) + pow(y2 - y1, 2));
	}
}