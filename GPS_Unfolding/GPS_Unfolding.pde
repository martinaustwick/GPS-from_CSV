/* 
  Copyright (2017) by Martin Zaltz Austwick, Sarah Wise, and University College London
  Licensed under the Academic Free License version 3.0
  See the file "LICENSE" for more information
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

//
// identifying the data to utilise
//
String baseString = ""; // prefix for csv files (numbered 0-n)
int selectOneFile = -1; // -1 to draw all tracks at once, 0+ to draw each track individually
int maxFile = 13;

// world parameters
PVector latLims = new PVector(51.5,51.6);
PVector lonLims = new PVector(-0.3,0.05);

float driftLimit = 0.01;

// time parameters
int startMam = 6*3600+(40*60);
int mamChange = 5;

// graphical parameters
float trackAlpha = 50;
float strokoo = 5;//2;
boolean paused = false;
boolean findLimits = true;

//
// storage for data
//
List<List<Location>> traceRecords = new ArrayList<List<Location>> ();
List<Marker> traces = new ArrayList<Marker>();
List<Marker> pointTraces = new ArrayList<Marker>();

//
// the physical world
//
UnfoldingMap map;


int mamTime;
int timeIndex;


// images
PImage casa, ftc;


// Initialisation

void setup()
{
  size(800, 800, P3D);
  smooth();
  frameRate(90);
  mamTime = startMam;
  
  loadLogos();

  String tilesStr = "jdbc:sqlite:" + sketchPath("./data/tiles/FTC3.mbtiles");
  
  // set up the UnfoldingMap to hold the data
  
  map = new UnfoldingMap(this, new MBTilesMapProvider(tilesStr));
          //new StamenMapProvider.TonerBackground()); //(alternate tilings)
          //new StamenMapProvider.WaterColor());
  map.zoomToLevel(14);
  map.setZoomRange(12, 17); // prevent zooming too far out
  MapUtils.createDefaultEventDispatcher(this, map);
  
  // set up a holder for the lines we define here
  List<Marker> traces = new ArrayList<Marker>();
  List<PositionRecord> myRoutes = new ArrayList<PositionRecord>();
  
  
  if(findLimits)
  {
      latLims = new PVector(90,-90);
      lonLims = new PVector(180,-180);
  }
  
  for(int f = 0; f<=maxFile; f++)
  {      
      //List<Location> traceLocations = new ArrayList<Location>();

      // open the file and read it into a table
      String filename = baseString + str(f) + ".csv";
      Table route = loadTable(filename, "header");

      // visualise the names of the columns
      //println((Object[])route.getColumnTitles());

      // extract columns of data from the table
      float [] lats = route.getFloatColumn("LATITUDE");
      float [] lons = route.getFloatColumn("LONGITUDE");    
      String [] ew = route.getStringColumn("E/W");
      String [] ns = route.getStringColumn("N/S");
      String [] time = route.getStringColumn("LOCAL TIME");

      PositionRecord prevRecord = null;

      // iterate over the records, clean them accordingly, and store them
      for (int i=1; i<lons.length; i++)
      {
        // adjust for east or west
        if (ew[i].equals("W")) lons[i] *=-1;
        if (ns[i].equals("S")) lats[i] *=-1;
        
        if(findLimits)
        {
            if(abs(lons[i]-lons[i-1])<driftLimit)
            {
              if(lons[i]<lonLims.x) lonLims.x=lons[i];
              if(lons[i]>lonLims.y) lonLims.y=lons[i];
            }
            if(abs(lats[i]-lats[i-1])<driftLimit && lats[i]<89)
            {
              if(lats[i]<latLims.x) latLims.x=lats[i];
              if(lats[i]>latLims.y) latLims.y=lats[i];
            }
        }
        
        // extract time information
        String [] timeLine = split(time[i],":");
        int myTime = 3600*int(timeLine[0]) + 60*int(timeLine[1]) + int(timeLine[2]);

        // save the record as a PositionRecord
        PositionRecord pr = new PositionRecord( myTime, new Location(lats[i], lons[i]));
        pr.setPrev(prevRecord);
        prevRecord = pr;
        
        // save the record as a LinesMarker object!
        //traceLocations.add(new Location(lats[i], lons[i]));
      }

      // 
      PositionRecord head = getHead(prevRecord);
      AnimatedPointMarker myRoute = new AnimatedPointMarker(head);
      
//      SimpleLinesMarker myTrace = new SimpleLinesMarker(traceLocations);
//      SimplePointMarker myPoint = new SimplePointMarker(head.position);//traceLocations.get(0));
      myRoute.setColor(color(0,255,255,200));
      myRoute.setStrokeWeight((int)strokoo*2);
      pointTraces.add(myRoute);
/*      traceRecords.add(traceLocations);
      myTrace.setStrokeWeight((int)strokoo);
      myTrace.setColor(color(255,0,0,75));
      myTrace.setStrokeColor(color(255,0,0,100));
//      myTrace.setColor(palette[int(random(palette.length))]);
      traces.add(myTrace);
  */    
  }
  
  
//  map.addMarkers(traces);
  map.addMarkers(pointTraces);
  
  strokeWeight(strokoo);
  background(255);
  noStroke();
  colorMode(HSB);
  
  lonLims = bufferVals(lonLims, 0.2);
  latLims = bufferVals(latLims, 0.2);
  println(latLims + "\n" + lonLims);
  
  Location centrePoint = 
    new Location(0.5 * (latLims.x + latLims.y), 0.5 * (lonLims.x + lonLims.y));
  map.panTo(centrePoint);
  
  //dynamic tweaking of aspect; assume a fixed height for this
  float midLat = 0.5*(latLims.y+latLims.x);
  float dy = (latLims.y-latLims.x);
  float dx = (lonLims.y-lonLims.x);
  int w = int(800*cos(radians(midLat))*dx/dy);
  
//  size(w, 800);
  surface.setResizable(true);
  surface.setSize(800, 800);
  timeIndex = startMam;
}

void draw()
{  
    background(0);
    if(! paused){
            
      
      for(int i = 0; i < pointTraces.size(); i++){
        ((AnimatedPointMarker)pointTraces.get(i)).setToTime(timeIndex);
        /*List <Location> myPointTraces = traceRecords.get(i);
        if(myPointTraces.size() >= timeIndex)
              pointTraces.get(i).setLocation(myPointTraces.get(timeIndex));
              */
      }
      timeIndex += mamChange; 
    }
//  println(traces.size());
   map.draw();
 // currentMap.draw();  
}


void keyPressed() {
    if (key == ' ') {
        paused = !paused;
    }
    if( key== 'r') {
        mamChange *= -1;
    }
}