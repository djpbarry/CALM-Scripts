import ij.IJ;
import ij.ImagePlus;
import ij.measure.ResultsTable;
import ij.plugin.filter.Analyzer;
import fiji.analyze.directionality.Directionality_;
import fiji.analyze.directionality.Directionality_.AnalysisMethod;

ImagePlus imp = IJ.getImage();
if (imp == null) {
    IJ.error("No image for directionality analysis");
    return;
}
Directionality_ da = new Directionality_();
da.setImagePlus(imp);
da.setBinNumber(90);
da.setBinRange(-90, 90);
da.setBuildOrientationMapFlag(false);
da.setDebugFlag(false);
da.setMethod(AnalysisMethod.LOCAL_GRADIENT_ORIENTATION);

da.computeHistograms();

double[] results = da.getFitAnalysis().get(0);

ResultsTable table = da.displayResultsTable();
table.show("Directionality Histogram");

ResultsTable rt = new ResultsTable();
rt.setPrecision(3);
rt.incrementCounter();
rt.addValue("Direction (°)", Math.toDegrees(results[0]));
rt.addValue("Dispersion (°)", Math.toDegrees(results[1]));
rt.addValue("Amount", results[2]);
rt.addValue("Goodness", results[3]);
rt.setLabel(imp.getTitle(), rt.getCounter() - 1);

rt.show("Directionality Analysis of " + imp.getTitle());