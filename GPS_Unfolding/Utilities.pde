// READ IN THE DATA

// read in a CSV tracking movement patterns and store its spatiotemporal path
// in a linked list of PositionRecords
AnimatedPointMarker readInFile(String filename, String name, boolean traces) {

  Table route;
  // open the Driver file and read it into a table
  try{
    route = loadTable(filename, "header");
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
    if (ew[i].equals("W") && lons[i] > 0) lons[i] *=-1;
    if (ns[i].equals("S") && lats[i] > 0) lats[i] *=-1;

    // extract time information
    String [] timeLine = split(time[i], ":");
    int myTime = 3600*int(timeLine[0]) + 60*int(timeLine[1]) + int(timeLine[2]);

    // adjust the map to the limits of the area and time
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
      
      if(myTime > maxTime) maxTime = myTime;
      if(myTime < minTime) minTime = myTime;
    }

    // save the record as a PositionRecord
    PositionRecord pr = new PositionRecord( myTime, new Location(lats[i], lons[i]));
    pr.setPrev(prevRecord);
    prevRecord = pr;
  }

  // Create the marker
  PositionRecord head = getHead(prevRecord);
  return new AnimatedPointMarker(head, name, traces);
  } catch (Exception e){
    return null;    
  }

}

// read in a CSV tracking movement patterns and store its spatiotemporal path
// in a linked list of PositionRecords
void readInFilePoints(String filename, color minColor, color maxColor, MarkerManager manager) throws FileNotFoundException {

  // open the Driver file and read it into a table
  Table route = loadTable(filename, "header,csv");

  // visualise the names of the columns
  //println((Object[])route.getColumnTitles());

  // extract columns of data from the table
  float [] lats = route.getFloatColumn("lat");//"LATITUDE");
  float [] lons = route.getFloatColumn("long");//"LONGITUDE");    
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
    manager.addMarker(sm);
  }

}

// read in a CSV tracking movement patterns and store its spatiotemporal path
// in a linked list of PositionRecords
void readInFileBlinkingPoints(String filename, color openColor, color closedColor, MarkerManager manager) throws FileNotFoundException {

  // open the Driver file and read it into a table
  Table route = loadTable(filename, "header,csv");

  // visualise the names of the columns
  //println((Object[])route.getColumnTitles());
  println(filename);
  // extract columns of data from the table
  float [] lats = route.getFloatColumn("lat");//"LATITUDE");
  float [] lons = route.getFloatColumn("long");//"LONGITUDE");    
  String [] modes = route.getStringColumn("Mode");
//  String [] departures = route.getStringColumn("Leave");
  String [] arrivals = route.getStringColumn("Time");

  int lastTime = 6*3600; // 6am default

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
    
    int myTime = lastTime;
    if((arrivals[i]).length() > 0 && arrivals[i].contains(":")){
      String [] timeLine = split(arrivals[i], ":");
      myTime = 3600*int(timeLine[0]) + 60*(int(timeLine[1]) -1);
//      myTime = 3600*int(timeLine[0]) + 60*int(timeLine[1]);
   }
   else
     myTime = myTime + 1;
    
    // extract time information
    
    PositionRecord myPr = new PositionRecord(myTime, new Location(lats[i], lons[i]));
    BlinkingPointMarker sm = new BlinkingPointMarker(myPr, "");
  //  sm.setRadius(mode.equals("W") ? walkingWidth : drivingWidth);
 //   sm.setColor(interpolateColor(((float)i)/lons.length, openColor, closedColor));
    sm.setStrokeColor(openColor);
    sm.setColor(closedColor);
    manager.addMarker(sm);
    lastTime = myTime;
  }

}

// OTHER

color[] palette = {color(166,206,227), color(31,120,180), 
  color(178,223,138), color(51,160,44), color(251,154,153), 
  color(227,26,28), color(253,191,111), color(255,127,0), 
  color(202,178,214)};

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



// determine whether difference between the given floats exceeds the drift limit
boolean drift(float a, float b)
{
    if(abs(a-b)>driftLimit || abs(a-b)==0) return true;
    else return false;
}

void elClocko()
{
    fill(255);
    stroke(0);
    rect(0,0,80,50);
    fill(0);
    String textor = str(timeIndex/3600) + ":" + nf((timeIndex/60)%60,2,0) + ":" + nf(timeIndex%60,2,0);
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

// return the header of this object
PositionRecord getHead(PositionRecord pr){
   if(pr.prev != null) return getHead(pr.prev);
   else return pr;
}

color interpolateColor(float percent, color c1, color c2){
   float d_r = red(c1) - red(c2);
   float d_g = green(c1) - green(c2);
   float d_b = blue(c1) -  blue(c2);
   float d_a = alpha(c1) - alpha(c2);
   return color(red(c2) + percent * d_r, 
   green(c2) + percent * d_g, 
   blue(c2) + percent * d_b,
   alpha(c2) + percent * d_a);
}