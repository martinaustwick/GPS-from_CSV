class BlinkingPointMarker extends SimplePointMarker {

  String myName;
  color myColor;
  boolean paused = false;
  int myTime = -1;
  
  int defaultSize = 8;
  float shrinkParameter = 30.;
  int blinkSpeed = 600;

  boolean square = false;

  PFont font;
  float fontSize = 12;
  int space = 6;

  BlinkingPointMarker(PositionRecord start, String name, int time) {
      super(start.position);
      setColor(palette[int(random(palette.length))]);
      setStrokeColor(palette[int(random(palette.length))]);
      myName = name;
      myTime = time;
  }

  /** checks to determine whether the time step is beyond the point of completion
      and the marker is labeled "fulfilled"
  */
  void checkIfUpdated(int mam){
    if(mam > myTime) {
      paused = true;
    }
    else {
      paused = false;
    }
  }

  BlinkingPointMarker(PositionRecord start) {
      this(start, "Blank", -1);
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
           pg.fill(this.highlightStrokeColor);
           radius = defaultSize;
      } else { // it's blinking
           pg.fill(this.strokeColor);
           radius = (timeIndex % blinkSpeed)/shrinkParameter;
      }
      
      if(square) {
        pg.rect(x, y, radius, radius);
      }
      else {
        pg.ellipse((int) x, (int) y, radius, radius);
      }
        
      /*// reenable for text
      if (font != null) {
           pg.textFont(font);
      }
      
      pg.fill(color(0, 0, 0, 255));
      pg.text(myName, Math.round(x + space * 0.75f + strokeWeight / 2), 
          Math.round(y + strokeWeight / 2 - space * 0.75f));
      */
      
      pg.popStyle();
  }
}