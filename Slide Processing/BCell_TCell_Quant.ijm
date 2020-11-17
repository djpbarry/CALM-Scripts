/*
 * david.barry@crick.ac.uk
 * 2020.07.20
 */

inputFile = File.openDialog("Select input file"); 

tCellFilterRadius = 3;
bCellFilterRadius = 6.5;
threshMethods = getList("threshold.methods");
bCellThresh = "Yen";
tCellThresh = "Default";
minBCellZoneSize = 10000;
tCellBufferZoneSize = 12;
CMFDACellFilterRadius = 1.5;
CMFDAProminence = 100;
series = 10;

Dialog.create("T-Cell/B-Cell Quant");
Dialog.addNumber("Image Series", series);
Dialog.addNumber("B Cell Filter Radius", bCellFilterRadius);
Dialog.addChoice("B Cell Threshold Method", threshMethods, bCellThresh);
Dialog.addNumber("Minimum B Cell Zone Size", minBCellZoneSize);
Dialog.addNumber("T Cell Filter Radius", tCellFilterRadius);
Dialog.addChoice("T Cell Threshold Method", threshMethods, tCellThresh);
Dialog.addNumber("T Cell Zone Buffer Size", tCellBufferZoneSize);
Dialog.addNumber("CMFDA B Cell Filter Radius", CMFDACellFilterRadius);
Dialog.addNumber("CMFDA Cell Prominence", CMFDAProminence);
Dialog.addMessage("\n\nAll parameters are specified in microns", 14);
Dialog.show();

series = Dialog.getNumber();
bCellFilterRadius = Dialog.getNumber();
bCellThresh = Dialog.getChoice();
minBCellZoneSize = Dialog.getNumber();
tCellFilterRadius = Dialog.getNumber();
tCellThresh = Dialog.getChoice();
tCellBufferZoneSize = Dialog.getNumber();
CMFDACellFilterRadius = Dialog.getNumber();
CMFDAProminence = Dialog.getNumber();

setBatchMode(true);

print(inputFile);

run("Set Measurements...", "  redirect=None decimal=3");

setBackgroundColor(0);
setForegroundColor(255);

run("Bio-Formats Importer", "open=[" + inputFile + "] specify_range series_" + series + " c_begin_" + series + "=2 c_end_" + series + "=4 c_step_" + series + "=1");

getPixelSize(unit, pixelWidth, pixelHeight);

title = getTitle();

C1 = "C1-" + title;
C2 = "C2-" + title;
C3 = "C3-" + title;

run("Split Channels");

print("Detecting B-Cell Zones...");
selectWindow(C1);
run("Duplicate...", "title=Dup_" + C1);
run("32-bit");
run("Subtract Background...", "rolling=500");
run("Gaussian Blur...", "sigma=" + bCellFilterRadius + " scaled");
setAutoThreshold(bCellThresh);
run("Convert to Mask");
binaryTissue = getTitle();

roiManager("reset");
print("Filtering Objects...");
run("Analyze Particles...", "size=" + minBCellZoneSize + "-Infinity show=Masks exclude");
regions = getTitle();
run("Create Selection");
Roi.setStrokeColor(255,255,255);
roiManager("Add");
roiManager("select", roiManager("count")-1);
roiManager("rename", "B-Cell Zone");
print("Done.");
close(binaryTissue);

print("Detecting T-Cell Zones...");
imageCalculator("Subtract create 32-bit", C3, C2);
print("Filtering...");
run("Gaussian Blur...", "sigma=" + tCellFilterRadius + " scaled");
roiManager("Select", 0);
run("Clear Outside");
print("Thresholding...");
setAutoThreshold(tCellThresh + " dark");
setOption("BlackBackground", false);
run("Convert to Mask");
run("Create Selection");
Roi.setStrokeColor(255,0,0);
roiManager("Add");
roiManager("select", roiManager("count")-1);
roiManager("rename", "T-Cell Zone");	
innerRegions = getTitle();
close(C2);
close(C3);

print("Refining...");
selectWindow(regions);
run("Select None");
run("Options...", "iterations=" + round(tCellBufferZoneSize / pixelWidth) + " count=1 do=Erode");
imageCalculator("AND create", regions, innerRegions);
resultantRegions = getTitle();
imageCalculator("Difference create", resultantRegions, regions);
differenceRegions = getTitle();
run("Create Selection");
Roi.setStrokeColor(0,0,255);
roiManager("Add");
roiManager("select", roiManager("count")-1);
roiManager("rename", "Difference");
close(differenceRegions);
close(regions);
close(innerRegions);
print("Done.");

print("Calculating Distances To/From T-Cell Zone Boundaries...");
selectWindow(resultantRegions);
run("Duplicate...", "title=Dup_" + resultantRegions);
run("Invert");
invertedResultantRegions = getTitle();
run("Chamfer Distance Map", "distances=[Borgefors (3,4)] output=[16 bits] normalize");
rename("OuterDist");
outerDist = getTitle();
close(invertedResultantRegions);

selectWindow(resultantRegions);
run("Chamfer Distance Map", "distances=[Borgefors (3,4)] output=[16 bits] normalize");
rename("InnerDist");
innerDist = getTitle();
close(resultantRegions);
imageCalculator("Subtract create 32-bit", outerDist, innerDist);
finalDistanceMap = getTitle();
close(outerDist);
close(innerDist);
print("Done.");

print("Calculating normalisation constant...");
selectWindow(finalDistanceMap);
roiManager("select", "Difference");
getStatistics(area, normConstant, min, max, std, histogram);
print("Done.");

print("Detecting CMFDA-Lablled B Cells...");
selectWindow(C1);
print("Filtering...");
run("Gaussian Blur...", "sigma=" + CMFDACellFilterRadius + " scaled");
roiManager("Select", 0);
run("Clear Outside");
run("Select None");
print("Local Maxima Detection...");
run("Find Maxima...", "prominence=" + CMFDAProminence + " strict exclude output=[Single Points]");
points = getTitle();
close(C1);
run("Set Measurements...", "mean centroid redirect=[" + finalDistanceMap + "] decimal=3");
selectWindow(points);
print("Analysing and Generating Results...");
run("Analyze Particles...", "size=0-Infinity display add");
headings = split(String.getResultsHeadings);
if(headings.length > 0){
	Table.renameColumn(headings[0], "Distance");
}
close(points);
close(finalDistanceMap);
print("Done.");

print("Displaying Results...");

run("Bio-Formats Importer", "open=[" + inputFile + "] autoscale color_mode=Composite view=Hyperstack series_" + series);

nRois = roiManager("count");
for (i = 3; i < nRois; i++) {
	roiManager("select", i);
	Roi.setStrokeColor(0,255,0);
	roiManager("rename", "Cell_" + (i - 3));
	distance = getResult("Distance", i-3);
	setResult("Normalised Distance", i-3, distance/normConstant);
}

roiManager("deselect");
roiManager("show all without labels");

print("All Done.");

setBatchMode(false);

run("To ROI Manager");
roiManager("deselect");
roiManager("show all without labels");
