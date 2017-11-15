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
  }
  
  void setColor(color c) {
    myColor = c;
  }

  void setTextColor(color c) {
    textColor = c;
  }

}