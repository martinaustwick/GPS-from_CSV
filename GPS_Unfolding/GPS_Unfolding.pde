/* 
  Copyright (2017) by Martin Zaltz Austwick, Sarah Wise, and University College London
  Licensed under the Academic Free License version 3.0
  See the file "LICENSE" for more information
*/

// imports to include Unfolding library
import de.fhpotsdam.unfolding.*;
import de.fhpotsdam.unfolding.geo.*;
import de.fhpotsdam.unfolding.utils.*;
import de.fhpotsdam.unfolding.providers.*;
import de.fhpotsdam.unfolding.data.*;
import de.fhpotsdam.unfolding.marker.*;
import java.util.List;


// handling the data

String baseString = ""; // prefix for csv files (numbered 0-n)
int selectOneFile = -1; // -1 to draw all tracks at once, 0+ to draw each track individually
int maxFile = 13;

//
// the physical world
//
UnfoldingMap map;

// world parameters
PVector latLims = new PVector(51.5,51.6);
PVector lonLims = new PVector(-0.3,0.05);
//PVector latLims = new PVector(51, 53);
//PVector lonLims = new PVector(-1,1);

float driftLimit = 0.01;

// storage for data
int count = 0;
ArrayList<float []>allLats, allLons, mams;
ArrayList<Integer> currentTimeIndex;

// time parameters
int startMam = 6*3600+(40*60);
int mamChange = 5;
int mamTime;

// graphical parameters
float trackAlpha = 50;
float strokoo = 2;

// visualising the output
boolean vidoCapture = false;
boolean drawAll = true;
boolean findLimits = true;

// images
PImage casa, ftc;
color[] palette = {color(166,206,227, 100), color(31,120,180, 100), color(178,223,138, 100), color(51,160,44, 100), color(251,154,153, 100), color(227,26,28, 100), color(253,191,111, 100), color(255,127,0, 100), color(202,178,214)};

/* Initialisation
*/
void setup()
{
  size(800, 800);
  smooth();
  frameRate(90);
  mamTime = startMam;
  
  loadLogos();
  
  // set up the UnfoldingMap to hold the data
  map = new UnfoldingMap(this, new StamenMapProvider.WaterColor());//TonerBackground());
  map.zoomToLevel(14);
  map.setZoomRange(9, 17); // prevent zooming too far out
  MapUtils.createDefaultEventDispatcher(this, map);
  
  // set up a holder for the lines we define here
  List<Marker> traces = new ArrayList<Marker>();
  
  allLats = new ArrayList<float[]>();
  allLons = new ArrayList<float[]>();
  mams = new ArrayList<float[]>();
  currentTimeIndex =  new ArrayList<Integer>();
  
  if(findLimits)
  {
      latLims = new PVector(90,-90);
      lonLims = new PVector(180,-180);
  }
  
  for(int f = 0; f<=maxFile; f++)
  {
      currentTimeIndex.add(1);
      
      List<Location> traceLocations = new ArrayList<Location>();

      
      String filename = baseString + str(f) + ".csv";
      Table route = loadTable(filename, "header");
      //println((Object[])route.getColumnTitles());
      float [] lats = route.getFloatColumn("LATITUDE");
      float [] lons = route.getFloatColumn("LONGITUDE");
          
    
      
      String [] ew = route.getStringColumn("E/W");
      for (int i=1; i<lons.length; i++)
      {
        if (ew[i].equals("W")) lons[i] *=-1;
        
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
        traceLocations.add(new Location(lats[i], lons[i]));
      }
//      
      //timings
      String [] time = route.getStringColumn("LOCAL TIME");
      //println(time[0]);
      float [] mam = new float[time.length];
      for (int i=0; i<time.length; i++)
      {
         String [] timeLine = split(time[i],":");
         //println(timeLine);
         mam[i] = 3600*float(timeLine[0]) + 60*float(timeLine[1]) + float(timeLine[2]);
      }
      mams.add(mam);
      allLats.add(lats);
      allLons.add(lons);
      
      SimpleLinesMarker myTrace = new SimpleLinesMarker(traceLocations);
      myTrace.setStrokeWeight((int)strokoo);
      myTrace.setColor(palette[int(random(palette.length))]);
      traces.add(myTrace);
  }
  
  count = 1;
  strokeWeight(strokoo);
  
  //you might need to add this in again
  //if(selectOneFile>-1)  background(255);
  //else background(255);
  
  map.addMarkers(traces);
  
  background(255);
  noStroke();
  colorMode(HSB);
  
  lonLims = bufferVals(lonLims, 0.2);
  latLims = bufferVals(latLims, 0.2);
  println(latLims);
  println(lonLims);
  
  Location centrePoint = 
    new Location(0.5 * (latLims.x + latLims.y), 0.5 * (lonLims.x + lonLims.y));
  map.panTo(centrePoint);
  
  //dynamic tweaking of aspect; assume a fixed height for this
  float midLat = 0.5*(latLims.y+latLims.x);
  float dy = (latLims.y-latLims.x);
  float dx = (lonLims.y-lonLims.x);
  int w = int(800*cos(radians(midLat))*dx/dy);
  
  size(w, 800);
//  surface.setResizable(true);
//  surface.setSize(w, 800);
}

PVector bufferVals(PVector maxmin, float percentageBuffer)
{
    float meanVec = 0.5*(maxmin.y + maxmin.x);
    float demiBreadth = 0.5*(maxmin.y - maxmin.x);
    demiBreadth*=(1.0+percentageBuffer);
    return new PVector(meanVec-demiBreadth, meanVec+demiBreadth);
}

void setLimits(float[] ons, float[] ats)
{
   latLims = new PVector(90,-90);
   lonLims = new PVector(180,-180);
   for(int i = 1; i<ons.length; i++)
   {
        if(abs(ons[i]-ons[i-1])<driftLimit)
        {
          if(ons[i]<lonLims.x) lonLims.x=ons[i];
          if(ons[i]>lonLims.y) lonLims.y=ons[i];
        }
        if(abs(ats[i]-ats[i-1])<driftLimit && ats[i]<89)
        {
          if(ats[i]<latLims.x) latLims.x=ats[i];
          if(ats[i]>latLims.y) latLims.y=ats[i];
        }
   }
   
   lonLims = bufferVals(lonLims, 0.2);
   latLims = bufferVals(latLims, 0.2);
}

void draw()
{
  //println(frameRate);
   map.draw(); 
/*  if(drawAll)
  {
      for(int f = 0; f<allLats.size(); f++)
      {
          if((selectOneFile>-1 && f==selectOneFile) || selectOneFile<0)
          {
              float [] lats = allLats.get(f);
              float [] lons = allLons.get(f);
              if(selectOneFile>-1)
              {
                  if(findLimits) setLimits(lons, lats);
                  background(255);
              }
              
              
              for(int c = 1; c<lats.length; c++)
              {
                  float x1 = map(lons[c-1], lonLims.x,   lonLims.y, 0, width);
                  float y1 = map(lats[c-1], latLims.x,   latLims.y, height, 0);
                  float x2 = map(lons[c], lonLims.x,   lonLims.y, 0, width);
                  float y2 = map(lats[c], latLims.x,   latLims.y, height, 0);
                  stroke(f*255.0/maxFile, 255, 200, trackAlpha);
                  //ellipse(x, y, 7, 7);
                  if(!drift(lats[c],lats[c-1])&&(!drift(lons[c],lons[c-1]))) line(x1,y1,x2,y2);
              }
              
              
          }
          
      }
      drawLogos();
      
      if(selectOneFile>-1 && selectOneFile<=maxFile)
      {
        fill(0);
        //text(lonLims.x + " " + latLims.y, 0,20);
        //text(lonLims.y + " " + latLims.x,width-150, height-20);
        saveFrame("stillz/Track" + str(selectOneFile) + ".jpg");
        selectOneFile++;
      }
      else
      {
          
          saveFrame("stillz/AllTrac.jpg");
          noLoop();
      }
      
      //noLoop();
  }
  else //animate tracks
  {
      //iterate through each file
      for(int f = 0; f<maxFile; f++)
      {
        //if meets selected file, or doesn't select
        if((selectOneFile>-1 && f==selectOneFile) || selectOneFile<0)
        {
          float [] lats = allLats.get(f);
          float [] lons = allLons.get(f);
          //int c = timeAfter(mamTime, mams.get(f),f);
          
          ArrayList<Integer> indices = timesAfter(mamTime, mams.get(f),f);
          
          if(indices.size()>0)
          {
          
              for(int c:indices)
              {
                if(c<lats.length && c>0)
                {
                    float x1 = map(lons[c-1], lonLims.x,   lonLims.y, 0, width);
                    float y1 = map(lats[c-1], latLims.x,   latLims.y, height, 0);
                    float x2 = map(lons[c], lonLims.x,   lonLims.y, 0, width);
                    float y2 = map(lats[c], latLims.x,   latLims.y, height, 0);
                    stroke(f*255.0/maxFile, 255, 200, trackAlpha);
                    //ellipse(x, y, 7, 7);
                    if(!drift(lats[c],lats[c-1])&&(!drift(lons[c],lons[c-1]))) line(x1,y1,x2,y2);
                    
                    currentTimeIndex.set(f, c);
                }
               
              }
          }
        }
      }
      elClocko();
      drawLogos();
  }

  //count = (count+1);
  mamTime+=mamChange;
  //if(count>=lats.length) noLoop();
  
  if(vidoCapture) saveFrame("vidoImages/######.png");
  if(mamTime>3600*24) {
    mamTime=0;
    
    //for(int j = 0; j<currentTimeIndex.size();j++)
    //{
    //    currentTimeIndex.set(j, currentTimeIndex.get(j)+1);
    //}
    noLoop();
  }
  */
}

boolean drift(float a, float b)
{
    //lat jump of one degree
    //float limit = 0.1;
    if(abs(a-b)>driftLimit || abs(a-b)==0) return true;
    else return false;
}

int timeAfter(int mamTimeIn, float [] mamTimes, int fileNumber)
{
    /*
        get the index of the time index AFTER the current time
    */
    int postIndex = -1;
    for(int i = currentTimeIndex.get(fileNumber); i<mamTimes.length; i++)
    {
        //if(mamTimeIn>mamTimes[i-1]){
          if((mamTimeIn<mamTimes[i]))
          {
              if(mamTimeIn>=mamTimes[i-1]) 
              {
                  //println(mamTimeIn + " " + mamTimes[i-1] + " " + mamTimes[i] + " " +i);
                  //&&(mamTimeIn>mamTimes[i-1])
                  postIndex = i;
                  i = mamTimes.length;
              }
              //if(postIndex>-1) println(postIndex);
          }
        //}
    }
    //this is some hackery
    //if(mamTimeIn>mamTimes[mamTimes.length-1])
    //{
    //    postIndex = mamTimes.length;
    //}
    return postIndex;
}

ArrayList<Integer> timesAfter(int mamTimeIn, float [] mamTimes, int fileNumber)
{
    /*
        get the index of the time index AFTER the current time
    */
    ArrayList<Integer> postIndices = new ArrayList<Integer>();
    for(int i = 1; i<mamTimes.length; i++)
    {
        //if(mamTimeIn>mamTimes[i-1]){
          if((mamTimeIn<mamTimes[i]))
          {
              if(mamTimeIn>=mamTimes[i-1]) 
              {
                  postIndices.add(i);
              }
              //if(postIndex>-1) println(postIndex);
          }
        //}
    }
    //this is some hackery
    //if(mamTimeIn>mamTimes[mamTimes.length-1])
    //{
    //    postIndex = mamTimes.length;
    //}
    return postIndices;
}

void elClocko()
{
    fill(255);
    stroke(0);
    rect(0,0,80,50);
    fill(0);
    String textor = str(mamTime/3600) + ":" + nf((mamTime/60)%60,2,0) + ":" + nf(mamTime%60,2,0);
    text(textor, 20,30);
}

void loadLogos()
{
//    casa = loadImage("logos/casa_logo.jpg");
//    casa.resize(90,120);
//    ftc = loadImage("logos/ftc.png");
//   ftc.resize(200,120);
}

void drawLogos()
{
//    image(casa, 10, height-casa.height-10);
//    image(ftc, 30+casa.width, height-ftc.height-10);
}
