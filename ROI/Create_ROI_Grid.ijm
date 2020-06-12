/*
 * Create an ROI grid in the ROI Manager
 * 
 * 2020.06.10 david.barry@crick.ac.uk
 */

gridSizeMicrons = 50;

getPixelSize(unit, pixelWidth, pixelHeight);

gridSizeMicrons = getNumber("Specify grid size in microns:", gridSizeMicrons);

gridSizePix = gridSizeMicrons / pixelWidth;

getDimensions(width, height, channels, slices, frames);

for (y = 0; y < height; y+=gridSizePix) {
	for (x = 0; x < width; x+=gridSizePix){
		makeRectangle(x, y, gridSizePix, gridSizePix);
		roiManager("add");
	}
}

roiManager("show all without labels");
