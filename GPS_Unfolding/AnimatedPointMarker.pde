// An extension to the SimplePointMarker class, which allows the marker to
// contain a series of PositionRecords defining a spatiotemporal record of
// locations. The extended marker can be defined with or without visualising
// a trace of the current "trail" of its movement
class AnimatedPointMarker extends FancyPointMarker implements TimedMarker {

  PositionRecord head;
  SimpleLinesMarker myTail = null;

  boolean square = false;

  // constructor
  AnimatedPointMarker(PositionRecord start, String name, boolean hasTail) {
      super(start.position);
      head = start;
      
      // set some appearance parameters
      color myColor = palette[int(random(palette.length))];
      setColor(myColor);
      setStrokeColor(myColor);
      myName = name;
      
      // add the trace, if appropriate
      if(hasTail){
        myTail = new SimpleLinesMarker();
        myTail.setStrokeWeight((int)strokoo);
        myTail.setColor(color(250, 250,250,70));//250, 250, 70));
      }
  }

  // constructor
  AnimatedPointMarker(PositionRecord start) {
      this(start, "", false);
  }
  
  // constructor
  AnimatedPointMarker(PositionRecord start, color bodyColor, color tailColor){
     this(start, "", true);
     myColor = bodyColor;
     setColor(myColor);
     setStrokeColor(myColor);
     myTail.setColor(tailColor);
  }

  // move the point marker either forward or backward in time to the specified
  // timestep
  void setToTime(int time) {
    
      // if the time is in the future relative to the current position, move forward
      // through the linked list
      while (time >= head.time && head.next != null) {
        if (time < head.next.time) {
            setLocation(head.position);
            return; // it's between this point and the next
        }
        head = head.next; // otherwise keep searching
        
        if(myTail != null)
          myTail.addLocation(head.position.x, head.position.y);
      }

      // otherwise, if the time is in the past relative to the current position,
      // move backward through the linked list
      while (time < head.time && head.prev != null) {
        if(myTail != null)
          myTail.removeLocation(head.position);
          
        if (time > head.prev.time) {
            head = head.prev;
            setLocation(head.position);
            return;
        }
        head = head.prev;
      }

      // Otherwise, it either hasn't started happening or has finished happening!
      // Do nothing!
  }

  // access to the trace tail
  SimpleLinesMarker getTail() { 
      return myTail;
  }

  // Overrides drawing function: adds a label, changes shape, defines colour
  @Override
  public void draw(PGraphics pg, float x, float y) {

      if (isHidden())
           return;

      pg.pushStyle();
      pg.strokeWeight(this.strokeWeight);
      if (isSelected()) {
           pg.stroke(this.highlightStrokeColor);
      } else {
           pg.stroke(this.strokeColor);
      }
      
      pg.fill(myColor);
      // fill in the shape responsibly
      if(square) {
        pg.rect(x, y, radius, radius);
      }
      else {
        pg.ellipse((int) x, (int) y, radius, radius);
      }
        
      if (font != null) {
           pg.textFont(font);
      }
      
      pg.fill(textColor);
      pg.text(myName, Math.round(x + space * 0.75f + strokeWeight / 2), 
          Math.round(y + strokeWeight / 2 - space * 0.75f));

      pg.popStyle();
  }
}