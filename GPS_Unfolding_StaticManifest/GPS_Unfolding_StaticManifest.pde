/* 
 Copyright (2017) by Martin Zaltz Austwick, Sarah Wise, and University College London
 Licensed under the Academic Free License version 3.0
 See the file "LICENSE" for more information
 
 s1 <- read.table("/Users/swise/Desktop/slide1.txt", header=TRUE, sep="\t")
 write.table(merge(s3, ns, by.x="Node", by.y = "V1", sort=FALSE), file="mySlide3.txt", sep="\t")
 
 */

import java.util.List;

import de.fhpotsdam.unfolding.*;
import de.fhpotsdam.unfolding.core.*;
import de.fhpotsdam.unfolding.data.*;
import de.fhpotsdam.unfolding.events.*;
import de.fhpotsdam.unfolding.geo.*;
import de.fhpotsdam.unfolding.marker.*;
import de.fhpotsdam.unfolding.providers.*;
import de.fhpotsdam.unfolding.utils.*;

import de.fhpotsdam.unfolding.geo.MercatorProjection;
import de.fhpotsdam.unfolding.mapdisplay.AbstractMapDisplay;
import de.fhpotsdam.unfolding.mapdisplay.MapDisplayFactory;
import de.fhpotsdam.unfolding.tiles.MBTilesLoaderUtils;

// controlling the visualisation
boolean enable_agents = true;

//
// identifying the data to utilise
//./data/";///
String baseString = "/Users/swise/Projects/FTC/data/GnewtN_251016/GnewtN_";////"/Users/swise/Projects/FTC/data/DetailedSurveyRoutesCSV/"; // prefix for csv files (numbered 0-n)
String baseStringSuffix = "_251016.csv";//"";
int selectOneFile = 1; // -1 to draw all tracks at once, 0+ to draw each track individually
int maxFile = 1;

// world parameters
PVector latLims = new PVector(51.5, 51.6);
PVector lonLims = new PVector(-0.3, 0.05);
float driftLimit = 0.001;

// graphical parameters
float trackAlpha = 50;
float strokoo = 5;
boolean findLimits = true;

int walkingWidth = 20;//15;
int drivingWidth = 12;//7;

//
// the physical world
//
UnfoldingMap map;
MarkerManager mm_agents;

// images
PImage casa, ftc;


// Initialisation

void setup()
{
  size(1200, 800, P3D);
  smooth();
  frameRate(90);

  loadLogos();

  String tilesStr = "jdbc:sqlite:" + sketchPath("./data/tiles/LondonSmokeAndStars2.mbtiles");//LondonDemo_noRed.mbtiles");//

  // set up the UnfoldingMap to hold the data
  map = new UnfoldingMap(this, new MBTilesMapProvider(tilesStr));
  mm_agents = new MarkerManager<Marker>();
  
  // set
  map.zoomToLevel(14);
  map.setZoomRange(12, 17); // prevent zooming too far out
  MapUtils.createDefaultEventDispatcher(this, map);

  if (findLimits)
  {
    latLims = new PVector(90, -90);
    lonLims = new PVector(180, -180);
  }

  // go through the files and read in the driver/vehicle pairs
  for (int f = max(0, selectOneFile); f<=maxFile; f++)
  {      

    // first process the driver
    String filename = baseString + str(f) + "D" + baseStringSuffix;
    readInFileDOTS(filename, palette[f], color(255,255,255,255));
  }

  // add the MarkerManagers to the map itself
  map.addMarkerManager(mm_agents);

  // defining the limits of the window
  lonLims = bufferVals(lonLims, 0.2);
  latLims = bufferVals(latLims, 0.2);
  println(latLims + "\n" + lonLims);

  // set up the map for visualisation
  Location centrePoint = new Location(0.5 * (latLims.x + latLims.y), 
      0.5 * (lonLims.x + lonLims.y));
  map.panTo(centrePoint);
  
  // final settings on the environment
  strokeWeight(strokoo);
  background(255);
  noStroke();
  colorMode(HSB);

  surface.setResizable(true);
  surface.setSize(1200, 800);
}

// read in a CSV tracking movement patterns and store its spatiotemporal path
// in a linked list of PositionRecords
void readInFileDOTS(String filename, color minColor, color maxColor) {

  // open the Driver file and read it into a table
  Table route = loadTable(filename, "header,csv");

  // visualise the names of the columns
  //println((Object[])route.getColumnTitles());

  // extract columns of data from the table
  float [] lats = route.getFloatColumn("LATITUDE");
  float [] lons = route.getFloatColumn("LONGITUDE");    
  String [] modes = route.getStringColumn("Mode");

  // iterate over the records, clean them accordingly, and store them
  for (int i=0; i<lons.length; i++)
  {

    // adjust the map to the limits of the area
    if (findLimits)
    {
      if (i > 0 && abs(lons[i]-lons[i-1])<driftLimit)
      {
        if (lons[i]<lonLims.x) lonLims.x=lons[i];
        if (lons[i]>lonLims.y) lonLims.y=lons[i];
      }
      if (i > 0 && abs(lats[i]-lats[i-1])<driftLimit && lats[i]<89)
      {
        if (lats[i]<latLims.x) latLims.x=lats[i];
        if (lats[i]>latLims.y) latLims.y=lats[i];
      }      
    }

    String mode = modes[i];
    SimplePointMarker sm = new SimplePointMarker(new Location(lats[i], lons[i]));
    sm.setRadius(mode.equals("W") ? walkingWidth : drivingWidth);
    sm.setColor(interpolateColor(((float)i)/lons.length, minColor, maxColor));
    mm_agents.addMarker(sm);
  }

}

// read in a CSV tracking movement patterns and store its spatiotemporal path
// in a linked list of PositionRecords
void readInFile(String filename, String name, boolean traces, color myColor) {

  // open the Driver file and read it into a table
  Table route = loadTable(filename, "header,tsv");

  // visualise the names of the columns
  //println((Object[])route.getColumnTitles());

  // extract columns of data from the table
  float [] lats = route.getFloatColumn("LATITUDE");
  float [] lons = route.getFloatColumn("LONGITUDE");    
  String [] modes = route.getStringColumn("Mode");

  List <Location> locs = new ArrayList<Location>();
  
  String lastMode = modes[0]; // initialise

  // iterate over the records, clean them accordingly, and store them
  for (int i=1; i<lons.length; i++)
  {

    // adjust the map to the limits of the area
    if (findLimits)
    {
      if (abs(lons[i]-lons[i-1])<driftLimit)
      {
        if (lons[i]<lonLims.x) lonLims.x=lons[i];
        if (lons[i]>lonLims.y) lonLims.y=lons[i];
      }
      if (abs(lats[i]-lats[i-1])<driftLimit && lats[i]<89)
      {
        if (lats[i]<latLims.x) latLims.x=lats[i];
        if (lats[i]>latLims.y) latLims.y=lats[i];
      }      
    }

    String mode = modes[i];
    locs.add(new Location(lats[i], lons[i]));
    println(mode);
    println(mode.equals("D"));
    // add new line, depending on what the mode is
    if(!mode.equals(lastMode)){
       lastMode = mode;
       SimpleLinesMarker slm = new SimpleLinesMarker(locs);
       slm.setColor(myColor);
       slm.setStrokeWeight(mode.equals("D") ? walkingWidth : drivingWidth);
       mm_agents.addMarker(slm);
       locs = new ArrayList<Location>();
    }
  }

  if(locs.size() > 1){
    SimpleLinesMarker slm = new SimpleLinesMarker(locs);
    slm.setColor(myColor);
    slm.setStrokeWeight(lastMode.equals("D") ? drivingWidth : walkingWidth);
    mm_agents.addMarker(slm);
    
  }
}

void draw()
{  
  background(0);
  map.draw();
}

// control the visualisation
void keyPressed() {
  if ( key == 'q') { // exit the visualisation
    exit();
  }
  if ( key == 'a'){ // flip the visibility of the agents
    enable_agents = !enable_agents;
    if(enable_agents) mm_agents.enableDrawing();
    else mm_agents.disableDrawing();
  }
}