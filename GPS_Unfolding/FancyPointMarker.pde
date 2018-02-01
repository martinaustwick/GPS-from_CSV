// generalised holder for more customisable markers 
public class FancyPointMarker extends SimplePointMarker {
  color textColor = color(215,25,28, 180);
  color myColor = color(215,25,28);
  String myName = "";
  int defaultSize = 10;

  PFont font;
  float fontSize = 14;
  int space = 50;


  public FancyPointMarker(Location l){
      super(l);
      highlightColor = color(0,0,0,0);
      strokeColor = color(0,0,0,0);
      strokeWeight = 0;
  }
  
  void setColor(color c) {
    myColor = c;
    super.setColor(c);
  }

  void setTextColor(color c) {
    textColor = c;
  }

}