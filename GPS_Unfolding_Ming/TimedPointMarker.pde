class TimedPointMarker extends SimplePointMarker {

  String myName;
  color myColor;
  boolean activated = false;
  int myTime = -1;

  int defaultSize = 8;
  float shrinkParameter = 30.;
  int blinkSpeed = 600;

  boolean square = false;

  PFont font;
  float fontSize = 12;
  int space = 6;

  TimedPointMarker(PositionRecord start, int time) {
    super(start.position);
    setColor(palette[int(random(palette.length))]);
    setStrokeColor(palette[int(random(palette.length))]);
    myTime = time;
  }

  // checks to determine whether the time step is beyond the point of completion
  // and the marker is labeled "fulfilled"

  void checkIfUpdated(int mam) {
    if (mam >= myTime) {
      activated = true;
    } else {
      activated = false;
    }
  }

  void setColor(color c) {
    myColor = c;
  }
  
  void setName(String n){
    myName = n;
  }

  /* Overrides drawing function to add the label
   */
  @Override
    public void draw(PGraphics pg, float x, float y) {

    if (isHidden())
      return;

    if (!activated) return;

    pg.pushStyle();


    if (square) {
      pg.noFill();
      pg.strokeWeight = 3;
      pg.stroke(this.myColor);
      pg.rect(x, y, radius, radius);
      
    } else {
      pg.noStroke();
      int smallerRadius = (int)(.5 * radius); // no it's not working for some reason - keep getting red circles rather than white
      color newColor = (this.myColor & 0xffffff) | (150 << 24);
      pg.fill(newColor);
      pg.ellipse((int) x, (int) y, smallerRadius, smallerRadius);
      pg.noStroke();
      pg.fill(this.myColor);
      pg.ellipse((int) x, (int) y, radius, radius);
    }
    pg.stroke(color(255,0,0));
    pg.text(myName, (int) x - radius, (int) y - radius);

    pg.popStyle();
  }
}