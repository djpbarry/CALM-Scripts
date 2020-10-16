/*
 * david.barry@crick.ac.uk
 * 2020.07.20
 */

inputFile = File.openDialog("Select input file"); 

tCellFilterRadius = 10;
bCellFilterRadius = 20;
threshMethods = getList("threshold.methods");
bCellThresh = "Default";
tCellThresh = "Default";
minBCellZoneSize = 10000;
tCellBufferZoneSize = 20;
CMFDACellFilterRadius = 2;
CMFDAProminence = 100;
series = 13;

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

title = getTitle();

C1 = "C1-" + title;
C2 = "C2-" + title;
C3 = "C3-" + title;

print("Averaging channels...");
run("Split Channels");
imageCalculator("Average create 32-bit", C1, C2);
result = getTitle();
imageCalculator("Average create 32-bit", result, C3);
tissue = getTitle();
close(result);
close(C3);
print("Done.");

print("Detecting B-Cell Zones...");
selectWindow(tissue);
print("Filtering...");
run("Gaussian Blur...", "sigma=20");
print("Thresholding...");
setAutoThreshold("Default");
setOption("BlackBackground", false);
run("Convert to Mask");
binaryTissue = getTitle();

roiManager("reset");
print("Filtering Objects...");
run("Analyze Particles...", "size=10000-Infinity show=Masks exclude");
close(binaryTissue);
print("Filling Holes...");
run("Fill Holes");
regions = getTitle();
run("Create Selection");
roiManager("Add");
print("Done.");

print("Detecting T-Cell Zones...");
selectWindow(C2);
print("Filtering...");
run("Gaussian Blur...", "sigma=10");
roiManager("Select", 0);
run("Clear Outside");
print("Thresholding...");
setAutoThreshold("Default dark");
setOption("BlackBackground", false);
run("Convert to Mask");
run("Create Selection");
roiManager("Add");
innerRegions = getTitle();

print("Refining...");
selectWindow(regions);
run("Select None");
run("Options...", "iterations=20 count=1 do=Erode");
imageCalculator("AND create", regions, innerRegions);
resultantRegions = getTitle();
close(regions);
close(innerRegions);
print("Done.");

print("Calculating Distances To/From T-Cell Zone Boundaries...");
run("Duplicate...", " ");
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

print("Detecting CMFDA-Lablled B Cells...");
selectWindow(C1);
print("Filtering...");
run("Gaussian Blur...", "sigma=2");
roiManager("Select", 0);
run("Clear Outside");
run("Select None");
print("Local Maxima Detection...");
run("Find Maxima...", "prominence=100 strict exclude output=[Single Points]");
points = getTitle();
close(C1);
run("Set Measurements...", "mean centroid redirect=[" + finalDistanceMap + "] decimal=3");
selectWindow(points);
print("Analysing and Generating Results...");
run("Analyze Particles...", "size=0-Infinity display add");
close(points);
close(finalDistanceMap);
print("Done.");

print("Displaying Results...");

run("Bio-Formats Importer", "open=[" + inputFile + "] autoscale color_mode=Composite view=Hyperstack series_" + series);

nRois = roiManager("count");
roiManager("select", 0);
Roi.setStrokeColor(255,255,255);
roiManager("rename", "B-Cell Zone");	
roiManager("select", 1);
Roi.setStrokeColor(255,0,0);
roiManager("rename", "T-Cell Zone");	
for (i = 2; i < nRois; i++) {
	roiManager("select", i);
	Roi.setStrokeColor(0,255,0);
	roiManager("rename", "Cell_" + (i - 2));	
}

roiManager("deselect");
roiManager("show all without labels");

print("All Done.");

setBatchMode(false);

run("To ROI Manager");
roiManager("deselect");
roiManager("show all without labels");
