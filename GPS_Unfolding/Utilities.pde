color[] palette = {color(166,206,227, 100), color(31,120,180, 100), 
  color(178,223,138, 100), color(51,160,44, 100), color(251,154,153, 100), 
  color(227,26,28, 100), color(253,191,111, 100), color(255,127,0, 100), 
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

// return the header of this object
PositionRecord getHead(PositionRecord pr){
   if(pr.prev != null) return getHead(pr.prev);
   else return pr;
}