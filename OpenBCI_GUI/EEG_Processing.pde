//import ddf.minim.analysis.*; //for FFT

boolean drawUser = true; //if true... toggles on EEG_Processing_User.draw and toggles off the headplot in Gui_Manager

boolean readyToPlay = false;
boolean channel1ToPlay = false;

class EEG_Processing_User {
  private float fs;          //sampling frequency
  private int nchan;         //number of channels

  int averagePeriod;         //number of data packets to average over [250 = 1 sec]
  boolean[] isTriggered;     //boolean to keep track of when the trigger condition is met
  float[] upperThresholds;   //default uV upper threshold value ... this will automatically change over time
  float[] lowerThresholds;   //default uV lower threshold value ... this will automatically change over time
  float[] tripUpperThresholds;
  float[] tripLowerThresholds;
  float[] averages;          //this will change over time ... used for calculations below
  float[] acceptableLimits;  //uV values above this limit are excluded, as a result of them almost certainly being noise...
  //if writing to a serial port
  float[] outputs;           //value between 0-255 that is the relative position of the current uV average between the rolling lower and upper uV thresholds
  float[] outputsNormalized; //converted to between 0-1

  /**
   * Constructor
   * @param NCHAN number of total channels
   * @param FS sampling frequency used
   */
  EEG_Processing_User(int NCHAN, float FS) {
    nchan = NCHAN;
    fs = FS;
    averagePeriod = 250;
    isTriggered = new boolean[nchan];
    upperThresholds = new float[nchan];
    lowerThresholds = new float[nchan];
    tripUpperThresholds = new float[nchan];
    tripLowerThresholds = new float[nchan];
    averages = new float[nchan];
    acceptableLimits = new float[nchan];
    outputs = new float[nchan];
    outputsNormalized = new float[nchan];

    for (int i = 0; i < isTriggered.length; ++i) isTriggered[i] = false;
    for (int i = 0; i < upperThresholds.length; ++i) upperThresholds[i] = 25.0;
    for (int i = 0; i < lowerThresholds.length; ++i) lowerThresholds[i] = 0.0;
    for (int i = 0; i < tripUpperThresholds.length; ++i) tripUpperThresholds[i] = 0.5;
    for (int i = 0; i < tripUpperThresholds.length; ++i) tripLowerThresholds[i] = 0.15;
    for (int i = 0; i < averages.length; ++i) averages[i] = 0.0;
    for (int i = 0; i < acceptableLimits.length; ++i) acceptableLimits[i] = 0.0;
    for (int i = 0; i < outputs.length; ++i) outputs[i] = 0.0;
    for (int i = 0; i < outputsNormalized.length; ++i) outputsNormalized[i] = 0.0;
  }

  /**
   * The processing routine called by the OpenBCI main program...update this with whatever you'd like to do
   * @param dataNewest   holds raw EEG data that is new since the last call
   * @param dataLong     holds a longer piece of buffered EEG data, of same length as will be plotted on the screen
   * @param dataFiltered this data has been filtered and is ready for plotting on the screen
   * @param fftData      holds the FFT (frequency spectrum) of the latest data
   */
  public void process(float[][] dataNewest, float[][] dataLong, float[][] dataFiltered, FFT[] fftData) {

    /* TIME DOMAIN PROCESSING */

    for (int ichan = 0; ichan < nchan; ++ichan) {
      for (int i = dataFiltered[ichan].length - averagePeriod; i < dataFiltered[ichan].length; ++i) {
        if (dataFiltered[ichan][i] <= acceptableLimits[ichan]) { //prevent BIG spikes from effecting the average
          averages[ichan] += abs(dataFiltered[ichan][i]);         //add value to average ... we will soon divide by # of packets
        } else {
          averages[ichan] += acceptableLimits[ichan];
        }
      }
      averages[ichan] /= float(averagePeriod);

      //single threshold method
      if (averages[ichan] >= upperThresholds[ichan]) upperThresholds[ichan] = averages[ichan];
      if (averages[ichan] <= lowerThresholds[ichan]) lowerThresholds[ichan] = averages[ichan];
      outputsNormalized[ichan] = map(averages[ichan], lowerThresholds[ichan], upperThresholds[ichan], 0, 1);  

      println("normalized output (channel " + ichan + "): " + outputsNormalized[ichan]);

      if (outputsNormalized[ichan] >= tripUpperThresholds[ichan] && !isTriggered[ichan]) {
        println("channel " + ichan + " triggered");
        audioSamples[ichan].trigger();
        isTriggered[ichan] = true;
      }

      if (isTriggered[ichan] && outputsNormalized[ichan] <= tripLowerThresholds[ichan]) {
        isTriggered[ichan] = false;
        println("channel " + ichan + " ready");
      }

      if (upperThresholds[ichan] >= 25.0) {
        // upperThresholds[ichan] -= upperThresholds[ichan] / (frameRate * 5); //have upper threshold creep downwards to keep range tight
        upperThresholds[ichan] *= .97;
      }
      if (lowerThresholds[ichan] <= 15.0) {
        lowerThresholds[ichan] += lowerThresholds[ichan] / (frameRate * 5); //have lower threshold creep upwards to keep range tight
      }
    }

    /* FREQUENCY DOMAIN PROCESSING */

    // float FFT_freq_Hz, FFT_value_uV;
    // for (int ichan = 0; ichan < nchan; ++ichan) {
    //   //loop over each new sample
    //   for (int ibin = 0; ibin < fftBuff[ichan].specSize(); ++ibin) {
    //     FFT_freq_Hz = fftData[ichan].indexToFreq(ibin);
    //     FFT_value_uV = fftData[ichan].getBand(ibin);
    //   }
    // }
  }

  /**
   * Draw function added to render EMG feedback visualizer
   */
  public void draw(){
    // pushStyle();
    //   //circle for outer threshold
    //   noFill();
    //   stroke(0,255,0);
    //   strokeWeight(2);
    //   float scaleFactor = 1.25;
    //   ellipse(3*(width/4), height/4, scaleFactor * upperThreshold, scaleFactor * upperThreshold);

    //   //circle for inner threshold
    //   stroke(0,255,255);
    //   ellipse(3*(width/4), height/4, scaleFactor * lowerThreshold, scaleFactor * lowerThreshold);

    //   //realtime
    //   fill(255,0,0, 125);
    //   noStroke();
    //   ellipse(3*(width/4), height/4, scaleFactor * myAverage, scaleFactor * myAverage);

    //   //draw background bar for mapped uV value indication
    //   fill(0,255,255,125);
    //   rect(7*(width/8), height/8, (width/32), (height/4));

    //   //draw real time bar of actually mapped value
    //   fill(0,255,255);
    //   rect(7*(width/8), 3*(height/8), (width/32), map(outputNormalized, 0, 1, 0, (-1) * (height/4)));
    // popStyle();
  }
}

class EEG_Processing {
  private float fs;  //sample rate
  private int nchan;
  final int N_FILT_CONFIGS = 5;
  FilterConstants[] filtCoeff_bp = new FilterConstants[N_FILT_CONFIGS];
  final int N_NOTCH_CONFIGS = 3;
  FilterConstants[] filtCoeff_notch = new FilterConstants[N_NOTCH_CONFIGS];
  private int currentFilt_ind = 0;
  private int currentNotch_ind = 0;  // set to 0 to default to 60Hz, set to 1 to default to 50Hz
  float data_std_uV[];
  float polarity[];


  EEG_Processing(int NCHAN, float FS) {
    nchan = NCHAN;
    fs = FS;
    data_std_uV = new float[nchan];
    polarity = new float[nchan];


    //check to make sure the sample rate is acceptable and then define the filters
    if (abs(fs-250.0f) < 1.0) {
      defineFilters();
    }
    else {
      println("EEG_Processing: *** ERROR *** Filters can currently only work at 250 Hz");
      defineFilters();  //define the filters anyway just so that the code doesn't bomb
    }
  }

  public float getSampleRateHz() {
    return fs;
  };

  //define filters...assumes sample rate of 250 Hz !!!!!
  private void defineFilters() {
    int n_filt;
    double[] b, a, b2, a2;
    String filt_txt, filt_txt2;
    String short_txt, short_txt2;

    //loop over all of the pre-defined filter types
    n_filt = filtCoeff_notch.length;
    for (int Ifilt=0; Ifilt < n_filt; Ifilt++) {
      switch (Ifilt) {
        case 0:
          //60 Hz notch filter, assumed fs = 250 Hz.  2nd Order Butterworth: b, a = signal.butter(2,[59.0 61.0]/(fs / 2.0), 'bandstop')
          b2 = new double[] { 9.650809863447347e-001, -2.424683201757643e-001, 1.945391494128786e+000, -2.424683201757643e-001, 9.650809863447347e-001 };
          a2 = new double[] { 1.000000000000000e+000, -2.467782611297853e-001, 1.944171784691352e+000, -2.381583792217435e-001, 9.313816821269039e-001  };
          filtCoeff_notch[Ifilt] =  new FilterConstants(b2, a2, "Notch 60Hz", "60Hz");
          break;
        case 1:
          //50 Hz notch filter, assumed fs = 250 Hz.  2nd Order Butterworth: b, a = signal.butter(2,[49.0 51.0]/(fs / 2.0), 'bandstop')
          b2 = new double[] { 0.96508099, -1.19328255,  2.29902305, -1.19328255,  0.96508099 };
          a2 = new double[] { 1.0       , -1.21449348,  2.29780334, -1.17207163,  0.93138168 };
          filtCoeff_notch[Ifilt] =  new FilterConstants(b2, a2, "Notch 50Hz", "50Hz");
          break;
        case 2:
          //no notch filter
          b2 = new double[] { 1.0 };
          a2 = new double[] { 1.0 };
          filtCoeff_notch[Ifilt] =  new FilterConstants(b2, a2, "No Notch", "None");
          break;
      }
    } // end loop over notch filters

    n_filt = filtCoeff_bp.length;
    for (int Ifilt=0;Ifilt<n_filt;Ifilt++) {
      //define bandpass filter
      switch (Ifilt) {
        case 0:
          //butter(2,[1 50]/(250/2));  %bandpass filter
          b = new double[] {
            2.001387256580675e-001, 0.0f, -4.002774513161350e-001, 0.0f, 2.001387256580675e-001
          };
          a = new double[] {
            1.0f, -2.355934631131582e+000, 1.941257088655214e+000, -7.847063755334187e-001, 1.999076052968340e-001
          };
          filt_txt = "Bandpass 1-50Hz";
          short_txt = "1-50 Hz";
          break;
        case 1:
          //butter(2,[7 13]/(250/2));
          b = new double[] {
            5.129268366104263e-003, 0.0f, -1.025853673220853e-002, 0.0f, 5.129268366104263e-003
          };
          a = new double[] {
            1.0f, -3.678895469764040e+000, 5.179700413522124e+000, -3.305801890016702e+000, 8.079495914209149e-001
          };
          filt_txt = "Bandpass 7-13Hz";
          short_txt = "7-13 Hz";
          break;
        case 2:
          //[b,a]=butter(2,[15 50]/(250/2)); %matlab command
          b = new double[] {
            1.173510367246093e-001, 0.0f, -2.347020734492186e-001, 0.0f, 1.173510367246093e-001
          };
          a = new double[] {
            1.0f, -2.137430180172061e+000, 2.038578008108517e+000, -1.070144399200925e+000, 2.946365275879138e-001
          };
          filt_txt = "Bandpass 15-50Hz";
          short_txt = "15-50 Hz";
          break;
        case 3:
          //[b,a]=butter(2,[5 50]/(250/2)); %matlab command
          b = new double[] {
            1.750876436721012e-001, 0.0f, -3.501752873442023e-001, 0.0f, 1.750876436721012e-001
          };
          a = new double[] {
            1.0f, -2.299055356038497e+000, 1.967497759984450e+000, -8.748055564494800e-001, 2.196539839136946e-001
          };
          filt_txt = "Bandpass 5-50Hz";
          short_txt = "5-50 Hz";
          break;
        default:
          //no filtering
          b = new double[] {
            1.0
          };
          a = new double[] {
            1.0
          };
          filt_txt = "No BP Filter";
          short_txt = "No Filter";
      }  //end switch block

      //create the bandpass filter
      filtCoeff_bp[Ifilt] =  new FilterConstants(b, a, filt_txt, short_txt);
    } //end loop over band pass filters
  } //end defineFilters method

  public String getFilterDescription() {
    return filtCoeff_bp[currentFilt_ind].name + ", " + filtCoeff_notch[currentNotch_ind].name;
  }
  public String getShortFilterDescription() {
    return filtCoeff_bp[currentFilt_ind].short_name;
  }
  public String getShortNotchDescription() {
    return filtCoeff_notch[currentNotch_ind].short_name;
  }

  public void incrementFilterConfiguration() {
    //increment the index
    currentFilt_ind++;
    if (currentFilt_ind >= N_FILT_CONFIGS) currentFilt_ind = 0;
  }
  public void incrementNotchConfiguration() {
    //increment the index
    currentNotch_ind++;
    if (currentNotch_ind >= N_NOTCH_CONFIGS) currentNotch_ind = 0;
  }

  /**
   * @param dataNewest   holds raw EEG data that is new since the last call
   * @param dataLong     holds a longer piece of buffered EEG data, of same length as will be plotted on the screen
   * @param dataFiltered put data here that should be plotted on the screen
   * @param fftData      holds the FFT (frequency spectrum) of the latest data 
   */
  public void process(float[][] dataNewest, float[][] dataLong, float[][] dataFiltered, FFT[] fftData) {

    //loop over each EEG channel
    for (int ichan=0;ichan < nchan; ichan++) {

      //filter the data in the time domain
      filterIIR(filtCoeff_notch[currentNotch_ind].b, filtCoeff_notch[currentNotch_ind].a, dataFiltered[ichan]); //notch
      filterIIR(filtCoeff_bp[currentFilt_ind].b, filtCoeff_bp[currentFilt_ind].a, dataFiltered[ichan]); //bandpass

      //compute the standard deviation of the filtered signal...this is for the head plot
      float[] fooData_filt = dataBuffY_filtY_uV[ichan];  //use the filtered data
      fooData_filt = Arrays.copyOfRange(fooData_filt, fooData_filt.length-((int)fs), fooData_filt.length);   //just grab the most recent second of data
      data_std_uV[ichan]=std(fooData_filt); //compute the standard deviation for the whole array "fooData_filt"

    } //close loop over channels

    //find strongest channel
    int refChanInd = findMax(data_std_uV);
    //println("EEG_Processing: strongest chan (one referenced) = " + (refChanInd+1));
    float[] refData_uV = dataBuffY_filtY_uV[refChanInd];  //use the filtered data
    refData_uV = Arrays.copyOfRange(refData_uV, refData_uV.length-((int)fs), refData_uV.length);   //just grab the most recent second of data


    //compute polarity of each channel
    for (int ichan=0; ichan < nchan; ichan++) {
      float[] fooData_filt = dataBuffY_filtY_uV[ichan];  //use the filtered data
      fooData_filt = Arrays.copyOfRange(fooData_filt, fooData_filt.length-((int)fs), fooData_filt.length);   //just grab the most recent second of data
      float dotProd = calcDotProduct(fooData_filt,refData_uV);
      if (dotProd >= 0.0f) {
        polarity[ichan]=1.0;
      } else {
        polarity[ichan]=-1.0;
      }

    }
  }
}
