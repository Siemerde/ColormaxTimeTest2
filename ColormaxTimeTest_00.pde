// ####################################################################################################
// Read me:
// In order to use this program you must install the G4P library by Peter Lager
// To install the G4P Library:
// 1. Go to the menu bar above and click Sketch
// 2. Mouse over Import Library and then click Add Library..., a new window will appear
// 3. In the text box near the top of the new window type G4P
// 4. Select the option with the Name G4P and Author Peter Lauger
// 5. Click Install, it's near the bottom right corner of the new window
// 6. Wait for the library install, this may take several minutes
// 7. You're finished! Close the extra window and have a lovely day
// ####################################################################################################

// TO DO:
// add to oneSecondTimerListener; check if we've hit an interval
// // if we have, add to our open log and create a standalone log
// add functionality to start button
// add functionality to end button
// // make sure we close that open log
// add a timer label to show how many seconds have passed (cuz i'm lazy)
// add a label for when we started

// Imports
import g4p_controls.*;
import java.awt.Toolkit;
import java.util.*;
import java.awt.event.ActionListener;
import java.awt.event.ActionEvent;
import javax.swing.Timer;

// Intervals for taking data in seconds
// This, ideally would be edited via some fort of GUI,
// But this program should aslo be ~1 time use, so I'm not worried about it
// Putting it at the top of the application code will have to do
final int[] colormaxIntervals = {
60,                // 1 minute
120,               // 2 minutes
180,               // 3 minutes
240,               // 4 minutes
300,               // 5 minutes
360,               // 6 minutes
420,               // 7 minutes
480,               // 8 minutes
540,               // 9 minutes
600,               // 10 minutes
1200,              // 20 minutes
1800,              // 30 minutes
2400,              // 40 minutes
3000,              // 50 minutes
3600,              // 60 minutes
7200,              // 2 hours
10800,             // 3 hours
14400,             // 4 hours
18000,             // 5 hours
21600,             // 6 hours
25200,             // 7 hours
28800,             // 8 hours
32400,             // 9 hours
36000,             // 10 hours
39600,             // 11 hours
43200,             // 12 hours
86400,             // 1 day
172800,            // 2 days
259200,            // 3 days
345600,            // 4 days
432000,            // 5 days
432000,            // 6 days
518400             // 7 days
};

// Colormax serial settings
static int cmaxBaudRate = 115200;
char cmaxParity = 'E';
int cmaxDataBits = 7;
float cmaxStopBits = 1.;

// Variables for finding connected colormaxes
// We MUST define how big these arrays are, even if
// the number of connected colormaxes is variable.. so
// we're just gonna make 100 slots, then check for nulls.
final int slots = 100;
boolean colormaxFoundMap[] = new boolean[slots];
Serial ports[] = new Serial[slots];
Serial colormaxPorts[] = new Serial[slots];
String colormaxPortsDroplistStrings[] = new String[slots];
boolean populatingColormaxes = false;

// Timer
Timer oneSecondTimer;
Timer updateTimer;

Colormax colormaxes[] = new Colormax[100];

//****************************************************************************************************
// Setup
//****************************************************************************************************
public void setup() {
  size(500, 570, JAVA2D);
  createGUI();
  customGUI();

  oneSecondTimer = new Timer(1000, oneSecondTimerListener);  // Make a timer that calls oneSecondTimerListener every 1000 milliseconds
  updateTimer = new Timer(750, updateTimerListener);         // Make a timer that calls updateTimerListener every x milliseconds
  //updateTimer.start();
  //oneSecondTimer.start();
  
  int i = 0;
  for (i = 0; i < colormaxes.length; i++) {
    colormaxes[i] = new Colormax("colormax" + i);
  }
  
  populateColormaxes();
  //updateColormaxInfo(colormaxes[listColormaxSelect.getSelectedIndex()]);
}

//****************************************************************************************************
// Draw
//****************************************************************************************************

public void draw() {
  background(230);
  //println("yeet");
}

//****************************************************************************************************
//  Methods
//****************************************************************************************************

// Set boolean array **************************************************
void setBooleanArray(boolean[] inputArray, boolean set) {
  for (int i = 0; i < inputArray.length; i++) {
    colormaxFoundMap[i] = set;
  }
}

// Nullify String arrays **************************************************
void nullifyStringArray(String[] inputArray) {
  for (int i = 0; i < inputArray.length; i++ ) {
    inputArray[i] = null;
  }
}

// Reset Int Array **************************************************
void resetIntArray(int[] inputArray){
  for (int i = 0; i < inputArray.length; i++ ) {
    inputArray[i] = 0;
  }
}

// colormaxPorts Reset **************************************************
void colormaxPortsReset() {
  int i = 0;
  for (i = 0; i < colormaxes.length; i++) {
    colormaxes[i].endSerial();
  }
}

// Update the droplist **************************************************
void updateColormaxDroplist() {
  int i = 0;

  // Clear colormax Droplist
  for (i = 0; i < slots; i++) {
    listColormaxSelect.removeItem(i);
  }

  // Check if we even have colormaxes connected
  // If we do, EZ Clap
  if (colormaxPortsDroplistStrings[0] != null) {
    listColormaxSelect.setItems(colormaxPortsDroplistStrings, 0);
    updateColormaxInfo(colormaxes[listColormaxSelect.getSelectedIndex()]);
  }
  // If we don't, display a message
  else {
    listColormaxSelect.setItems(new String[] {"No Colormaxes Available"}, 0);
  }
}

// Populate Colormaxes **************************************************
void populateColormaxes() {
  int i = 0;
  int j = 0;
  int responseTimeout = 250;
  populatingColormaxes = true;

  //println("resetting stuff");  //for debugging

  // Reset some stuff
  setBooleanArray(colormaxFoundMap, false);
  colormaxPortsReset();
  nullifyStringArray(colormaxPortsDroplistStrings);

  //println("starting population")  // For debugging

  // Populate ports[] with all current serial ports
  // initialize with colormax settings
  for (i = 0; i < Serial.list().length; i++) {
    try {
      ports[i] = new Serial(this, Serial.list()[i], cmaxBaudRate, cmaxParity, cmaxDataBits, cmaxStopBits);
      ports[i].bufferUntil(13);
    }
    catch(Exception e) {
      println(e);
    }
  }

  // Send a value over every connected serial port 
  // and wait for a colormax response (handled in serialEvent())
  // If we don't get a response within the timeout period
  // then we assume there's no colormax and move on
  for (i = 0; i < Serial.list().length; i++) {
    if (ports[i] != null) {
      ports[i].write(13);
      int startMillis = millis();
      while (!colormaxFoundMap[i]) {
        delay(1); // we need to slow the program down for some reason.. leave this here
        if (millis() - startMillis > responseTimeout) {
          println("@@@@@@@@@@", ports[i].port.getPortName(), "response timeout @@@@@@@@@@");
          break;
        }
      }
    }
  }

  // Initialize colormaxPorts[], then populate it
  // with ports that we know have colormaxes attached
  for (i = 0; i < ports.length; i++) {
    if (colormaxFoundMap[i] == true
      && ports[i] != null) {
      colormaxPortsDroplistStrings[j] = ports[i].port.getPortName();
      colormaxes[j].setSerial(ports[i]);
      colormaxPorts[j] = ports[i];
      j++;
    }  
    // If there's no colormax on that port, close it
    // and return that slot to null
    else if (ports[i] != null) {
      ports[i].clear();
      ports[i].stop();
      ports[i] = null;
    }
  }

  // Last thing to do is update the droplist
  updateColormaxDroplist();
  populatingColormaxes = false;
  return;
}

// Update Colormax Info **************************************************
void updateColormaxInfo(Colormax inColormax) {
 if(inColormax != null && inColormax.getSerial() != null) {
   final int commandDelay = 25;
    
   // Each command needs a short delay (at least 25ms) to get a response.
   // And I'm too dumb to figure out how to make an array of methods to call with a for(){} loop
   // No need for so many lines of code, so I've put the delay in-line with each method call
   // like so: inColormax.readCLT();delay(commandDelay);
   inColormax.readData();delay(commandDelay);
   inColormax.readTemperature();delay(commandDelay);
   inColormax.readIlluminationAlgorithm();delay(commandDelay);
   inColormax.readSettings();delay(commandDelay);
   inColormax.readIdentity();delay(commandDelay);
   inColormax.readVersion();delay(commandDelay);
   inColormax.readIlluminationFactor();delay(commandDelay);

   lblRedPercentData.setText(String.format("%.1f", inColormax.getRedPercent() - 0.05) + "%");
   lblGreenPercentData.setText(String.format("%.1f", inColormax.getGreenPercent() - 0.05) + "%");
   lblBluePercentData.setText(String.format("%.1f", inColormax.getBluePercent() - 0.05) + "%");
    
   txtRedGreenBlue.setText(String.format("%.1f", inColormax.getRedPercent() - 0.05));
   txtRedGreenBlue.appendText(" \t" + String.format("%.1f", inColormax.getGreenPercent() - 0.05));
   txtRedGreenBlue.appendText(" \t" + String.format("%.1f", inColormax.getBluePercent() - 0.05));
    
   lblRedHexData.setText(String.valueOf(inColormax.getRed()) + "H");
   lblGreenHexData.setText(String.valueOf(inColormax.getGreen()) + "H");
   lblBlueHexData.setText(String.valueOf(inColormax.getBlue()) + "H");
   lblTemperatureData.setText(String.format("%.2f", inColormax.getTemperature() - 0.005));
   ////lblLEDCurrentData.setText(inColormax.getLedMa());
   lblLEDCurrentData.setText(String.format("%.2f", inColormax.getLedMaFloat() - 0.005));
   lblDACSettingData.setText(inColormax.getLedDac());
   lblLedStabilityData.setText(inColormax.getLedStability());
   lblAveragingData.setText(inColormax.getAveraging());
   lblTriggeringData.setText(inColormax.getTriggering());
   lblOutputDelayData.setText(inColormax.getOutputDelay());
   lblIlluminationData.setText(String.valueOf(inColormax.getIllumination()));
   lblModelData.setText(inColormax.getModel());
   lblFirmwareVersionData.setText(inColormax.getVersion());
   lblSerialNumberData.setText(inColormax.getSerialNumber());
 } else {
   println("no colormax, owo");
 }
}

// TO DO:
// We should really check that the colormax is still connected when we start...
// Start Time Test **************************************************
volatile int timeTestIndex = 0;
volatile Colormax timeTestColormax;
void startTimeTest(final Colormax inColormax){
  counter = 0;                                     // Make sure we reset our seconds counter
  timeTestIndex = 0;                               // Make sure we reset timeTestIndex
  timeTestColormax = inColormax;                   // Set which colormax we're testing
  inColormax.setStatus(inColormax.timeTesting);    // Set status so other functions know what's going on
  oneSecondTimer.start();                          // Let that timer rip
}

//  **************************************************
final int sampleSize = 10;
volatile int redChannel[] = new int[sampleSize];      // For storing red channel readings for later averaging
volatile int greenChannel[] = new int[sampleSize];    // For storing green channel readings for later averaging
volatile int blueChannel[] = new int[sampleSize];     // For storing blue channel readings for later averaging

// We need a way to store the averaged readings for other methods to use
// 0 = red channel readings
// 1 = green channel readings
// 2 = blue channel readings
volatile int averagedReadings[] = new int[3];

volatile int avgReadingsIndex;  // For keeping track of how many readings we have in the averaging arrays (we could technically do this by checking for zeroes or nulls or something, but w/e)

void getAveragedReadings(Colormax inColormax){
  // Make sure we start clean with our arrays; set all their values to 0
  resetIntArray(redChannel);
  resetIntArray(greenChannel);
  resetIntArray(blueChannel);
  resetIntArray(averagedReadings);
  
  avgReadingsIndex = 0;    // Reset the index variable
  
  final int commandDelay = 50;              // Delay in milliseconds required between serial commands (range: 25-infinity)
  for(int i = 0 ; i < sampleSize ; i++){    // Send the !d command enough times to fill the arrays
    inColormax.readData();                  // Ask colormax for RGB readings
    delay(commandDelay);                    // Required delay; Colormax needs time to respond and recoup
  }
}

// Timer Listeners **************************************************
volatile int counter = 0;
ActionListener oneSecondTimerListener = new ActionListener() {
  public void actionPerformed(ActionEvent e) {
    println("yeet");
    final int max = 60;
    int colorIndex = 0;
    counter++;

    // quick fix to make this code work from where it used to be
    Colormax inColormax = colormaxes[listColormaxSelect.getSelectedIndex()];

    //// Get which color is selected
    //for (colorIndex = 0; colorIndex < colorOptions.length; colorIndex++) {
    //  if (colorOptions[colorIndex].isSelected()) {
    //    break;
    //  }
    //}
    
    // Check for negative values real fast
    if (counter < 0) {
      println("@@@@@ timer counter error; non-positive value @@@@@");
    }
    else if(inColormax.getStatus() == inColormax.timeTesting){
      if(counter >= colormaxIntervals[timeTestIndex]){
        timeTestIndex++;
      }
    }
    else if (inColormax.getStatus() == inColormax.calibrating && counter >= max) {
      counter = 0;            // Reset counter
      oneSecondTimer.stop();  // End timer
      println("it is time");  //for debugging

      // Calibrating color
      if(inColormax.getStatus() == inColormax.calibrating) {
        inColormax.writeTempOn();       // Verify Colormax is using TempTable
        delay(100);                     // 100ms delay to make sure colormax gets the command
        inColormax.writeStartAlign();   // Verify Colormax is in AlmProcs
        delay(100);                     // 100ms delay to make sure colormax gets the command
        inColormax.writeAlignColor();   // Tell colormax to take readings
        inColormax.setStatus(inColormax.idle);  // Reset Colormax status
        //btnCalibrateColor.setLocalColorScheme(GCScheme.CYAN_SCHEME); // Set button back to the default color scheme

        // Check if user wants to hear a beep
        //if (chkBeepOnRead.isSelected()) {
        //  Toolkit.getDefaultToolkit().beep();
        //}

        //// Move the radio selection for the user
        //for (int i = 0; i < colorOptions.length; i++) {
        //  if (colorOptions[i].isSelected()) {
        //    try {
        //      colorOptions[++i].setSelected(true);
        //    }
        //    catch(ArrayIndexOutOfBoundsException ex) {
        //      colorOptions[0].setSelected(true);
        //    }
        //    break;
        //  }
        //}
      }
    }
  }
};

volatile boolean checkingLine = false;    // Variable to indicate to serialEvent that we're checking if we have a colormax on the line
volatile boolean colormaxOnLine = false;  // Variable telling us we have one on the line
ActionListener updateTimerListener = new ActionListener() {
  public void actionPerformed(ActionEvent e) {
    if(true) {   // was dependent on GUI element we deleted
      checkingLine = true;
      colormaxOnLine = false;
      colormaxes[listColormaxSelect.getSelectedIndex()].serial.write(13);
      int timeout = 50;
      int startMillis = millis();
      while (!colormaxOnLine) {
        delay(1);
        if (millis() - startMillis > timeout) {
          checkingLine = false;
          return;
        }
      }
      if (colormaxOnLine) {
        updateColormaxInfo(colormaxes[listColormaxSelect.getSelectedIndex()]);
      }
    }
  }
};

// Cancel Align/Retake timers **************************************************
void cancelAlignRetake(Colormax inColormax) {
  // Set UI elements back to normal
  //btnRetakePoint.setLocalColorScheme(GCScheme.CYAN_SCHEME);     // Set button back to the default color scheme
  //btnCalibrateColor.setLocalColorScheme(GCScheme.CYAN_SCHEME);  // Set button back to the default color scheme

  inColormax.setStatus(inColormax.idle);  // Reset Colormax status

  oneSecondTimer.stop();    // Stop the timer
  counter = 0;              // Reset counter
  //retakeReadTT.cancel();  // 
  //alignColorTT.cancel();  //
}

//boolean continuePopup(String message) {


//  return false;
//}



// Get Align Table **************************************************
volatile int point;
volatile Colormax currentColormax;
void getAlignTable(Colormax inColormax) {
  inColormax.setStatus("gettingAlignTable");
  String logName = "AlignTables/" + inColormax.getSerialNumber().substring(12, 16) + "_alignTable";
  inColormax.newLog(logName);
  inColormax.readAlignmentPoint(0);
  int startMillis = millis();
  while(inColormax.getStatus() != "idle"){
    delay(1);
    if(millis() - startMillis > 1000){
      inColormax.setStatus("idle");
      println("@@@@@@@@@@ getAlignTable() timeout @@@@@@@@@@");
      return;
    }
  }
}

// Get Temp Table **************************************************
void getTempTable(Colormax inColormax) {
  inColormax.setStatus("gettingTempTable");
  String logName = "TempTables/" + inColormax.getSerialNumber().substring(12, 16) + "_tempTable";
  inColormax.newLog(logName);
  inColormax.readTempPoint(0);
  int startMillis = millis();
  while(!inColormax.getStatus().contains("idle")){
    delay(1);
    if(millis() - startMillis > 1000){
      inColormax.setStatus("idle");
      inColormax.writeToLog("Timed out");
      inColormax.endLog();
      println("@@@@@@@@@@ getTempTable() timeout @@@@@@@@@@");
      return;
    }
  }
}

// Get UDID **************************************************

// TO DO: ADD CHECK FOR VERSION OVER 011 047
boolean getUDID(Colormax inColormax){
  // To get the UDID, we need to send the !D command
  // To use the !D command, we need to use the !Z command first
  // To use the !Z command, we need the serial number reversed in pairs of two hex digits
  // e.g. inSN == "0123 4567 89AB CDEF", outSN == "EFCD AB89 6745 2301"
  
  final int commandDelay = 50;        // Delay in milliseconds required between serial commands (range: 25-infinity)
  final int responseTimeout = 250;    // Delay for colormax response timeout (range: 25 - infinity)
  String tempSerialNumber = inColormax.getSerialNumber();  // we may not need this
  inColormax.setSerialNumber(null);                        //serialNumber = null so we can check for if we've got an update or not
  inColormax.readIdentity();          // Ask for colormax's serial number - this is to make sure we have the right serial number as it's not updated if a new colormax is connected and its info not grabbed
  
  int startMillis = millis();         // Starting point for response timeout
  while(inColormax.getSerialNumber() == null){
    delay(1);                                             // Required, otherwise this function goes too fast
    if((millis() - startMillis) > responseTimeout){       // Check if we've timed out
      inColormax.setSerialNumber(tempSerialNumber);       // If not, set this back, I guess?
      println("@@@@@@@@@@", inColormax.serial.port.getPortName(),", getUDID serial number response timeout @@@@@@@@@@");  // Print out an error
      return false;                                             // Leave this function!
    }
  }
  
  // Now that we know for sure we have the right serial number
  char[] sn = inColormax.getSerialNumber().toCharArray();  // Make it an array; easier to maniuplate indiviudal characters like this
  char[] sn2 = new char[16];                               // Make a second array to store the deletion code (this will be used to make a string later)
  
  int i;                            // For iterating through sn
  int j = 0;                        // For iterating through sn2
  for(i = (sn.length - 1) ; i > 0 ; i -= 2){     // Start from the end of sn[], make sure we stay above 0, decrement by 2
    sn2[j++] = sn[i-1];             // Increment through sn2[], go half-backwards through sn[] (it's weird, i know)
    sn2[j++] = sn[i];
  }
  
  // We can finally send the !Z and !D commands
  String serialNumberDeletionCode = new String(sn2);              // The !Z command actually deletes the unit's serial number; we need it as a string for our function
  inColormax.writeDeleteSerialNumber(serialNumberDeletionCode);   // Tell the unit to delete its serial number; no worries, we have its serial number stored in the object for later
  delay(commandDelay);                                            // Wait a little while for the unit to do its thing
  inColormax.readUDID();                                          // Send the !D command
  delay(commandDelay);                                            // Wait a little while for the unit to do its thing
  inColormax.writeSerialNumber(inColormax.getSerialNumber());     // Send the !I command to have the unit rewrite its serial number!
  //println(inColormax.getUDID());
  return true;// All done
}

// Delete Serial Number
boolean deleteSerialNumber(Colormax inColormax){
  // To get the UDID, we need to send the !D command
  // To use the !D command, we need to use the !Z command first
  // To use the !Z command, we need the serial number reversed in pairs of two hex digits
  // e.g. inSN == "0123 4567 89AB CDEF", outSN == "EFCD AB89 6745 2301"
  
  final int commandDelay = 50;        // Delay in milliseconds required between serial commands (range: 25-infinity)
  final int responseTimeout = 250;    // Delay for colormax response timeout (range: 25 - infinity)
  String tempSerialNumber = inColormax.getSerialNumber();  // we may not need this
  inColormax.setSerialNumber(null);                        //serialNumber = null so we can check for if we've got an update or not
  inColormax.readIdentity();          // Ask for colormax's serial number - this is to make sure we have the right serial number as it's not updated if a new colormax is connected and its info not grabbed
  
  int startMillis = millis();         // Starting point for response timeout
  while(inColormax.getSerialNumber() == null){
    delay(1);                                             // Required, otherwise this function goes too fast
    if((millis() - startMillis) > responseTimeout){       // Check if we've timed out
      inColormax.setSerialNumber(tempSerialNumber);       // If not, set this back, I guess?
      println("@@@@@@@@@@", inColormax.serial.port.getPortName(),", getUDID serial number response timeout @@@@@@@@@@");  // Print out an error
      return false;                                             // Leave this function!
    }
  }
  
  // Now that we know for sure we have the right serial number
  char[] sn = inColormax.getSerialNumber().toCharArray();  // Make it an array; easier to maniuplate indiviudal characters like this
  char[] sn2 = new char[16];                               // Make a second array to store the deletion code (this will be used to make a string later)
  
  int i;                            // For iterating through sn
  int j = 0;                        // For iterating through sn2
  for(i = (sn.length - 1) ; i > 0 ; i -= 2){     // Start from the end of sn[], make sure we stay above 0, decrement by 2
    sn2[j++] = sn[i-1];             // Increment through sn2[], go half-backwards through sn[] (it's weird, i know)
    sn2[j++] = sn[i];
  }
  
  // We can finally send the !Z and !D commands
  String serialNumberDeletionCode = new String(sn2);              // The !Z command actually deletes the unit's serial number; we need it as a string for our function
  inColormax.writeDeleteSerialNumber(serialNumberDeletionCode);   // Tell the unit to delete its serial number; no worries, we have its serial number stored in the object for later
  return true;
}

// Calculate UDIDcd **************************************************
String calcUDIDcd(Colormax inColormax){
  // The UDIDcd is a strange beast..
  // We need to M xor N where:
  // M = hex values 18, 24, 4, 30, 23, and 12 from the UDID
  // N = The last 7 digits of the unit's serial number in reverse order, converted to a hex value
  
  
  // TO DO: ADD CHECK FOR COLORMAX ALREADY HAVING UDID STORED
  if(inColormax.getUDID() != null || !getUDID(inColormax)){  // Make sure we have the unit's UDID
    return "error";  // We couldn't get the UDID, leave now
  }
  else {     // We got it! Moving on...
    // Let's get M first
    char[] inUDID = inColormax.getUDID().toCharArray();        // Convert the UDID to an array of characters, because it's easier to deal with
    char[] tempM = { inUDID[17], inUDID[23], inUDID[3], inUDID[29], inUDID[22], inUDID[11]  };  // M = hex values 18, 24, 4, 30, 23, and 12 from the UDID
    String M = new String(tempM);                              // Turn that badboi into a string
    //println("M:", M);  // for debugging
    
    // Now lets get N
    char[] inSN = inColormax.getSerialNumber().toCharArray();  // Convert the serial number to an array
    char[] tempN = new char[7];                                // Second array to temporarily hold N
    
    // We need the last 7 digits of inSN in reverse order
    int i = 0;                              // Just need one iterating variable
    for(i = 0 ; i < tempN.length ; i++){    // Start from the beginning, make sure we don't exceed our array length, increment once
      tempN[i] = inSN[inSN.length - (i + 1)];     // Go in reverse, bb
    }
    String N = new String(tempN);           // Chuck that into a string
    N = String.format("%X", Integer.parseInt(N));    // Do some fancy footwork to make that string a hex value
    //println("N:", N);  // for debugging
    
    // Now we just xor those bois together
    String UDIDcd = String.format("%X", ((Integer.parseInt(M, 16)) ^ (Integer.parseInt(N, 16))));
    inColormax.setUDIDcd(UDIDcd);
    //println("UDIDcd:", UDIDcd);  //for debugging
    return UDIDcd;
  }
}

// Transfer Memory
void transferMemory(Colormax inColormax){
  
}

// Key Pressed Event Listener **************************************************
void keyPressed() {
  
}

// Serial Event Listener **************************************************
void serialEvent(Serial inPort) {
  String inString = inPort.readString();
  // TO DO: MAKE FUNCTION TO FIGURE OUT WHICH COLORMAX MESSAGE CAME FROM

  // Print out all serial responses to the text box
  println("Recieved:", inString);  //for debugging
  //txtColormaxResponses.appendText(inString);
  
  // Check if it's a colormax response
  // If it is, and we're looking for colormaxes,
  // update the map
  if (inString.startsWith("?") ) {
    if (populatingColormaxes) {
      for (int i = 0; i < ports.length; i++) {
        if (inPort == ports[i]) {
          println("Colormax on", ports[i].port.getPortName());
          colormaxFoundMap[i] = true;
          break;
        }
      }
    } else if (checkingLine) {
      colormaxOnLine = true;
    }

    return;
  }  

  if (inString.startsWith("!a")) {
    colormaxes[listColormaxSelect.getSelectedIndex()].parseIlluminationSetting(inString);
    return;
  }

  if (inString.startsWith("!d")) {
    colormaxes[listColormaxSelect.getSelectedIndex()].parseData(inString);
    return;
  }
  
  if (inString.startsWith("!D")){
    colormaxes[listColormaxSelect.getSelectedIndex()].parseUDID(inString);
    //txtUDID.setText(colormaxes[listColormaxSelect.getSelectedIndex()].getUDID());
    //inColormax.getSerialNumber().substring(12, 16) + " tempTable";
    String logName = "UDIDs/" + colormaxes[listColormaxSelect.getSelectedIndex()].getSerialNumber() + "_UDID";
    colormaxes[listColormaxSelect.getSelectedIndex()].newLog(logName);
    colormaxes[listColormaxSelect.getSelectedIndex()].writeToLog(colormaxes[listColormaxSelect.getSelectedIndex()].getUDID());
    colormaxes[listColormaxSelect.getSelectedIndex()].endLog();
    return;
  }

  if (inString.startsWith("!g")) {
    colormaxes[listColormaxSelect.getSelectedIndex()].parseIlluminationAlgorithm(inString);
    return;
  }

  if (inString.startsWith("!h")) {
    colormaxes[listColormaxSelect.getSelectedIndex()].parseClt(inString);
    return;
  }

  if (inString.startsWith("!s")) {
    colormaxes[listColormaxSelect.getSelectedIndex()].parseSettings(inString);
    return;
  }

  if (inString.startsWith("!i")) {
    colormaxes[listColormaxSelect.getSelectedIndex()].parseIdentity(inString);
    return;
  }

  if (inString.startsWith("!v")) {
    colormaxes[listColormaxSelect.getSelectedIndex()].parseVersion(inString);
    return;
  }

  
  // Bug found having to do with connecting/disconnecting the Colormax
  // Typically we wind up with some random character in the buffer, and that causes 
  // the string.startsWith() to return false becuase the string actually looks something like "~!N,6,0,00..."
  if (inString.startsWith("!N")) {
    if (inString.startsWith("!N,6")) {
      if (colormaxes[listColormaxSelect.getSelectedIndex()].getStatus() == ("gettingTempTable")) {
        if (inString.contains("!N,6,1")){
          colormaxes[listColormaxSelect.getSelectedIndex()].setStatus("idle");
          colormaxes[listColormaxSelect.getSelectedIndex()].endLog();
        } else {
          colormaxes[listColormaxSelect.getSelectedIndex()].writeToLog(inString);
          int point = Integer.parseInt(inString.substring(7, 9), 16) + 1;    //Integer.parseInt(inClt.substring(3, 7), 16);
          colormaxes[listColormaxSelect.getSelectedIndex()].readTempPoint(point);
        }
      }
    }
  }

  if (inString.startsWith("!O")) {
    if (inString.startsWith("!O,6")) {
      if (colormaxes[listColormaxSelect.getSelectedIndex()].getStatus() == ("gettingAlignTable")) {
        if (inString.startsWith("!O,6,1")){
          colormaxes[listColormaxSelect.getSelectedIndex()].setStatus("idle");
          colormaxes[listColormaxSelect.getSelectedIndex()].endLog();
        } else {
          //println("status check successful");
          colormaxes[listColormaxSelect.getSelectedIndex()].writeToLog(inString);
          int point = Integer.parseInt(inString.substring(7, 9), 16) + 1;    //Integer.parseInt(inClt.substring(3, 7), 16);
          //println("point: ", point);
          colormaxes[listColormaxSelect.getSelectedIndex()].readAlignmentPoint(point);
        }
      }
    }
    if (inString.startsWith("!O,8,0")) {
    }
  }

  if(inString.startsWith("!w")){
    colormaxes[listColormaxSelect.getSelectedIndex()].parseTemperature(inString);
  }

  // @@@@@@@@@@ End of serialEvent() @@@@@@@@@@
}

// Use this method to add additional statements
// to customise the GUI controls
public void customGUI() {
}