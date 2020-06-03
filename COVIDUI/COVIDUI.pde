import de.bezier.data.sql.*;
import java.util.*;
import java.util.Date;
PImage earthtex;
PShape globeshape;
PGraphics globetex,globelayer;

import java.text.NumberFormat;
MySQL sql;
ArrayList<Country> countries;
int numcountries=0;
int worldlatestconfirmed=0;
int worldyesterdayconfirmed=0;
int worldlatestdeaths=0;
int worldyesterdaydeaths=0;

int textdepth=-400;
int countrytickerindex=0;
int frameCounter=0;

int reportmode=0;
int transitiontimer=0;
int transitioning=0;
int transitionspeed=20;
int reportduration=10000;

Hashtable<String, Integer> countrylookup;

void setup() {
  sql = new MySQL( this, "localhost", "COVID", "root", "313920" );
  if (!sql.connect()) {
    println("fail");
  }
  countries = new ArrayList<Country>();
  countrylookup = new Hashtable<String, Integer>();
  sql.query( "CALL getrecent" );
  while (sql.next()) {
    countries.add(new Country(sql.getString("country"),sql.getString("iso"),sql.getInt("latestconfirmed"),sql.getInt("yesterdayconfirmed"),sql.getInt("latestdeaths"),sql.getInt("yesterdaydeaths"),sql.getDate("latestdate"),sql.getDate("secondlatestdate")));
    numcountries++;
    worldlatestconfirmed+=sql.getInt("latestconfirmed");  
    worldyesterdayconfirmed+=sql.getInt("yesterdayconfirmed");
    worldlatestdeaths+=sql.getInt("latestdeaths");
    worldyesterdaydeaths+=sql.getInt("yesterdaydeaths");
    countrylookup.put(sql.getString("iso"),numcountries-1);
  }
  
  countries.add(new Country("World","XX",worldlatestconfirmed,worldyesterdayconfirmed,worldlatestdeaths,worldyesterdaydeaths,countries.get(0).latestdate,countries.get(0).secondlatestdate));
  countrylookup.put("XX",numcountries);
  
  size(1920, 1080, P2D);//1,920x1,080
  frameRate(60);
  colorMode(HSB);
  PFont FontLucidaSansDemibold = createFont("Lucida Sans Demibold", 50,true);
  textFont(FontLucidaSansDemibold);
  textAlign(CENTER, CENTER);
  background(0);
  earthtex = loadImage("earth8k.jpg");
  earthtex.resize(width, height);
  globetex = createGraphics(earthtex.width, earthtex.height);
  globetex.beginDraw();
  globetex.image(earthtex,0,0);
  globetex.line(0,0,earthtex.width, earthtex.height);
  globetex.textSize(150);
  globetex.fill(255,0,255);
  globetex.noStroke();
  globetex.text("Clara",earthtex.width/2,earthtex.height/2);
  globetex.fill(0,255,255);
  globetex.text("Liam",earthtex.width/3.0*2.0,earthtex.height/3.0*2.0);
  globetex.endDraw();
  
  globelayer = createGraphics(width, height, P3D);
  globeshape = globelayer.createShape(SPHERE,350);
  globeshape.setStroke(false);
  
  globeshape.setTexture(globetex);
  
  for (Country c : countries) {
    c.loadDailyData();
  }
}

void draw() {
  println(frameRate);
  if (1==frameCount) surface.setLocation(400, 100);
  background(0);
  //image(globetex,0,0);
  textSize(50);
  noStroke();
  fill(0,0,155);
  textAlign(LEFT,TOP);
  text("COVID TV",10,0);


  globelayer.beginDraw();
  globelayer.perspective(PI/4, float(width)/float(height),  (height/2.0) / tan(PI/4/2.0)/10.0, (height/2.0) / tan(PI/4/2.0)*10.0);
  globelayer.pushMatrix();
  globelayer.translate(650, 200,-1000); 
  globelayer.pointLight(255, 255, 255, 600, 0, 800);
  globeshape.rotateY(0.002);
  globelayer.shape(globeshape);
  globelayer.popMatrix();
  globelayer.endDraw();
  image(globelayer,0,0);
  
  textSize(80);
  fill(0,0,255);
  textAlign(RIGHT);
  text(prettyDouble(countries.get(numcountries).currentConfirmed()), 450, 150);
  text(prettyDouble(countries.get(numcountries).currentDeaths()), 450, 230);

  for (int i=countrytickerindex;i<countrytickerindex+14;i++) {
    countries.get(i%numcountries).drawsmall(1500,(i-countrytickerindex)*90-frameCounter,18);
  }
  if (frameCounter>=90) {
    frameCounter=0;
    countrytickerindex=(countrytickerindex+1)%numcountries;
  }
  frameCounter=frameCounter+1;
  
  fill(255,0,255);
  textSize(12);
  textAlign(RIGHT);
  text("confirmed cases",1260,1045);
  text("deaths",1260,1030);
  for (int i=0;i<90;i++){
    stroke(map(i,0,50,40,00),255,255,255);
    point(i+1280,1025);
    stroke(map(i,0,50,150,130),255,255,255);
    point(i+1280,1040);
  }
  countries.get(countrylookup.get("US")).drawsmall(1070,0*90+0,18);
  countries.get(countrylookup.get("GB")).drawsmall(1070,90*1+0,18);
  countries.get(countrylookup.get("IT")).drawsmall(1070,90*2+0,18);
  countries.get(countrylookup.get("BR")).drawsmall(1070,90*3+0,18);
  countries.get(countrylookup.get("FR")).drawsmall(1070,90*4+0,18);
  countries.get(countrylookup.get("ES")).drawsmall(1070,90*5+0,18);
  countries.get(countrylookup.get("DE")).drawsmall(1070,90*6+0,18);
  countries.get(countrylookup.get("SE")).drawsmall(1070,90*7+0,18);
  countries.get(countrylookup.get("KR")).drawsmall(1070,90*8+0,18);
  countries.get(countrylookup.get("SG")).drawsmall(1070,90*9+0,18);
  countries.get(countrylookup.get("ZA")).drawsmall(1070,90*10+0,18);

  //stroke(100,30,255,50);
  //noFill();
  //rect(10,550,1030,510);

  if (reportmode==0) {
    reportPercentageofWorld();
  } else if (reportmode==1) {
    fill(255,0,255,255);
    textSize(20);
    text("1",100,600);
  } else if (reportmode==2) {
    fill(255,0,255,255);
    textSize(20);
    text("2",100,600);
  }
  
  
  if (frameCount%reportduration==0) { // next report
    transitiontimer=transitionspeed;
    transitioning=1;
  }
  if (transitioning==1) {
    transitiontimer=transitiontimer-1;
    fill(255,0,0,map(abs(transitiontimer),0,transitionspeed,255,0));
    noStroke();
    rect(10,550,1030,510);
  }
  if (transitioning==1 && transitiontimer==0) {
    reportmode=(reportmode+1)%3;     //show the next report now
  }
  if (transitioning==1 && transitiontimer==-transitionspeed) {
    transitioning=0;
  }
  
}

void reportPercentageofWorld() {
    noStroke();
    fill(255,0,255,255);
    textSize(18);
    textAlign(LEFT, CENTER);
    text("Total World Population   "+prettyLong(currentWorldPopulation()),110,585);
    fill(55,255,60);
    stroke(55,255,80);
    strokeWeight(1);
    int sizex=155;
    int sizey=85;
    for (int x=0;x<sizex;x++){
      for (int y=0;y<sizey;y++){
        rect(100+x*5,600+y*5,5,5);
      }
    }
    fill(255,255,150);
    stroke(255,255,200);

    long pop=currentWorldPopulation();
    //#blocks for each metric
    float deaths=(float)((sizex*sizey*countries.get(countrylookup.get("XX")).currentDeaths() / (pop/1000000))/1000000);
    int recovered=(int)((sizex*sizey*countries.get(countrylookup.get("XX")).currentRecovered() / (pop/1000000))/1000000);
    int active=4;//(int)((sizex*sizey*countries.get(countrylookup.get("XX")).currentActive() / (pop/1000000))/1000000);
    
    rect(100+(sizex)*5+2, sizey*5+600 - deaths*5, 5,deaths*5); // deaths
    
    fill(55,255,100);
    stroke(55,255,120);
    for (int y=0;y<recovered;y++){
      rect(100+(sizex-1)*5,600+(sizey-1)*5-y*5,5,5); // recovered in bright green
    }
    fill(20,255,150);
    stroke(20,255,200);
    for (int y=0;y<active;y++){
      rect(100+(sizex-1)*5,600+(sizey-1)*5-(recovered-1)*5-y*5,5,5);
    }
    
    // legend
    noStroke();
    fill(255,0,255,255);
    textSize(12);
    text("Active cases",130+(sizex)*5,600+(sizey-1)*5-recovered*5);
    text("Recovered",130+(sizex)*5,600+(sizey-1)*5-recovered*5+25);
    text("Deaths",130+(sizex)*5,600+(sizey-1)*5);
    stroke(255,0,80,255);
    line(130+(sizex)*5-30,600+(sizey-1)*5-recovered*5,130+(sizex)*5,600+(sizey-1)*5-recovered*5);
    line(130+(sizex)*5-30,600+(sizey-1)*5-recovered*5+25,130+(sizex)*5-5,600+(sizey-1)*5-recovered*5+25);
    line(130+(sizex)*5-20,600+(sizey-1)*5+5,130+(sizex)*5-5,600+(sizey-1)*5+5); // deaths line
    fill(55,255,100);
    stroke(55,255,120);
    rect(120,1040,5,5);
    fill(255,0,255,255);
    text("= "+prettyInt((int)((pop)/(sizex*sizey)))+ " people per cell",130,1040);
    
}

double doublemap(double i, double in1, double in2, double out1, double out2) {
  return (i-in1)/(in2-in1)*(out2-out1)+out1;
}

String prettyInt(int i) {
  return NumberFormat.getIntegerInstance().format(i);
}

String prettyLong(Long i) {
  return NumberFormat.getIntegerInstance().format(i);
}


String prettyDouble(double i) {
  return NumberFormat.getIntegerInstance().format((int)i);
}

long currentWorldPopulation() {
    long Births1=59031352L;
    long Deaths1=24782775L;
    Date d1=new Date(2020-1900,6-1,2,20,24,25); // snapshots from Worldometers.info
    long Births2=59038216L;
    long Deaths2=24785657L;
    long Population2=7788691955L;
    Date d2=new Date(2020-1900,6-1,2,20,50,10);
    Date now=new Date();
    float newBirths=1.0*(Births2-Births1)*(now.getTime()-d1.getTime())/(d2.getTime()-d1.getTime())-(Births2-Births1); // births since Date2 up to now
    float newDeaths=1.0*(Deaths2-Deaths1)*(now.getTime()-d1.getTime())/(d2.getTime()-d1.getTime())-(Deaths2-Deaths1); // births since Date2 up to now
    long currentPopulation=Population2+(long)round(newBirths)-(long)round(newDeaths);
    return currentPopulation;
}

class Country {
  String name;
  String iso;
  int latestconfirmed;
  int yesterdayconfirmed;
  int latestdeaths;
  int yesterdaydeaths;
  Date latestdate;
  Date secondlatestdate;
  PImage flag;
  float xpos=0,ypos=0;
  ArrayList<Float> dailydeaths;
  float maxdailydeaths;
  ArrayList<Float> dailyconfirmed;
  float maxdailyconfirmed;
  
  Country (String name_,String iso_, int latestconfirmed_, int yesterdayconfirmed_, int latestdeaths_, int yesterdaydeaths_, Date latestdate_, Date secondlatestdate_) {
    name=name_;
    iso=iso_;
    latestconfirmed=latestconfirmed_;
    yesterdayconfirmed=yesterdayconfirmed_;
    latestdeaths=latestdeaths_;
    yesterdaydeaths=yesterdaydeaths_;
    latestdate=latestdate_;
    secondlatestdate=secondlatestdate_;
    File f = dataFile("flagicons/"+iso+".png");
    if (f.isFile()) {
      flag = loadImage("flagicons/"+iso.toLowerCase()+".png");
    }
  }
  
  double currentConfirmed() {
    return doublemap((new Date()).getTime(),secondlatestdate.getTime(),latestdate.getTime(),yesterdayconfirmed, latestconfirmed);
  }
  
  double currentDeaths() {
    return doublemap((new Date()).getTime(),secondlatestdate.getTime(),latestdate.getTime(),yesterdaydeaths, latestdeaths);
  }
  
  double currentRecovered() {
    return doublemap((new Date()).getTime(),secondlatestdate.getTime(),latestdate.getTime(),yesterdayconfirmed, latestconfirmed);
  }
  
  double currentActive() {
    return currentConfirmed()-currentRecovered();
  }
  
  void loadDailyData() {
    maxdailydeaths=0;
    maxdailyconfirmed=0;
    dailydeaths = new ArrayList<Float>();
    dailyconfirmed = new ArrayList<Float>();
    sql.query( "CALL getdailyforcountry('"+this.iso+"')" );
    while (sql.next()) {
      dailydeaths.add(sql.getFloat("deaths7dave"));
      maxdailydeaths=max(maxdailydeaths,sql.getFloat("deaths7dave"));
      dailyconfirmed.add(sql.getFloat("confirmed7dave"));
      maxdailyconfirmed=max(maxdailyconfirmed,sql.getFloat("confirmed7dave"));
    }
  }
  
  void drawDailyDeaths(float startx,float starty,float graphwidth,float graphheight) {
    stroke(255,255,255);
    if (dailydeaths.size()>1 && maxdailydeaths>0) {
      for (int i=1;i<dailydeaths.size();i++) {
        stroke(map(dailydeaths.get(i),0,maxdailydeaths,40,00),255,255,255);
        line(
          map(i-1,0,dailydeaths.size()-1,startx,startx+graphwidth),
          map(dailydeaths.get(i-1),0,maxdailydeaths,starty+graphheight,starty),
          map(i,0,dailydeaths.size()-1,startx,startx+graphwidth),
          map(dailydeaths.get(i),0,maxdailydeaths,starty+graphheight,starty)
        );
      }
    }
  }
  
  void drawDailyConfirmed(float startx,float starty,float graphwidth,float graphheight) {
    stroke(255,255,255);
    if (dailyconfirmed.size()>1 && maxdailyconfirmed>0) {
      for (int i=1;i<dailyconfirmed.size();i++) {
        stroke(map(dailyconfirmed.get(i),0,maxdailyconfirmed,150,130),255,255,255);
        line(
          map(i-1,0,dailyconfirmed.size()-1,startx,startx+graphwidth),
          map(dailyconfirmed.get(i-1),0,maxdailyconfirmed,starty+graphheight,starty),
          map(i,0,dailyconfirmed.size()-1,startx,startx+graphwidth),
          map(dailyconfirmed.get(i),0,maxdailyconfirmed,starty+graphheight,starty)
        );
      }
    }
  }
  
  void drawsmall(float x, float y, float fontsize) {
    float boxheight=80;
    float boxwidth=400;
    noFill();
    stroke(0,0,55);
    strokeWeight(1);
    //rect(x,y,boxwidth,boxheight);
    line(x,y,x+boxwidth,y);
    textSize(fontsize+3);
    fill(0,0,255);
    textAlign(LEFT);
    text(this.name, x+50+10, y+25);
    noStroke();
    fill(255,0,0,240);
    String confirmed=prettyDouble(this.currentConfirmed());
    String deaths=prettyDouble(this.currentDeaths());
    rect(x+295-confirmed.length()*(10),y+5,confirmed.length()*(10)+120,28);
    textSize(fontsize);
    textAlign(RIGHT);
    fill(0,0,255,200);
    text(confirmed, x+90+215, y+25);
    text(deaths, x+90+315, y+25);
    fill(0,0,100);
    textSize(fontsize-5);
    text("c", x+103+210, y+25);
    text("d", x+103+310, y+25);
    this.flag.resize(50, 0);
    image(this.flag,x,y+5);
    drawDailyDeaths(x,y+50,boxwidth,boxheight-50);
    drawDailyConfirmed(x,y+50,boxwidth,boxheight-50);
  }


  
}
