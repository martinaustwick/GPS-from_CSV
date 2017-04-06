class BlinkingPointMarker extends SimplePointMarker {

  String myName;
  color myColor;
  boolean paused = false;
  int myTime = -1;
  
  int defaultSize = 4;
  float shrinkParameter = 70.;
  int blinkSpeed = 2400;

  boolean square = false;

  PFont font;
  float fontSize = 12;
  int space = 6;

  BlinkingPointMarker(PositionRecord start, String name) {
      super(start.position);
  //    setColor(palette[int(random(palette.length))]);
  //    setStrokeColor(color(0,0,0,50));//palette[int(random(palette.length))]);
      myName = name;
      myTime = start.time;
  }

  // checks to determine whether the time step is beyond the point of completion
  // and the marker is labeled "fulfilled"
  
  void checkIfUpdated(int mam){
    if(mam > myTime) {
      paused = true;
    }
    else {
      paused = false;
    }
  }

  BlinkingPointMarker(PositionRecord start) {
      this(start, "");
  }

  void setColor(color c){
    myColor = c; 
  }

  /* Overrides drawing function to add the label
  */
  @Override
  public void draw(PGraphics pg, float x, float y) {

      if (isHidden())
           return;

      pg.pushStyle();
      pg.strokeWeight(this.strokeWeight);

      if (isSelected() || paused) { // it's not blinking
           pg.fill(myColor);
           radius = defaultSize;
      } else { // it's blinking
           pg.fill(this.strokeColor);
           radius = ((timeIndex % blinkSpeed) - .5 * blinkSpeed)/shrinkParameter;
      }
      
      if(square) {
        pg.rect(x, y, radius, radius);
      }
      else {
        pg.ellipse((int) x, (int) y, radius, radius);
      }

      if (paused) {
        if (font != null) {
             pg.textFont(font);
        }
        pg.fill(color(0, 0, 0, 100));
        pg.text(myName, Math.round(x + space * 0.75f + strokeWeight / 2), 
          Math.round(y + strokeWeight / 2 - space * 0.75f));
      }
      
      pg.popStyle();
  }
}