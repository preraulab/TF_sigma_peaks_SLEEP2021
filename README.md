# TF_sigma_peaks_SLEEP2021
### This is the repository for the code referenced in: 
Dimitrov T, He M, Stickgold R, Prerau MJ. [Sleep spindles comprise a subset of a broader class of electroencephalogram events](https://prerau.bwh.harvard.edu/publications/sleep_2021_spind.pdf). Sleep. 2021 Apr 15:zsab099. doi: 10.1093/sleep/zsab099. Epub ahead of print. PMID: 33857311.
--- 

## Table of Contents
* [General Information](#general-information)
* [Hand Scoring TFpeaks](#hand-scoring-tfpeaks)
* [TFσ peak Detection](#tfpeak-detection)
* [Algorithm Description](#algorithm-description)
* [Multitaper Spectrogram](#multitaper-spectrogram )
* [Artifact Detection](#artifact-detection)
* [Citations](#citations)
* [Status](#status)
* [References](#references)
<br/>
<br/>

## General Information
The code in this repository is companion to the paper [Sleep spindles comprise a subset of a broader class of electroencephalogram events](https://prerau.bwh.harvard.edu/publications/sleep_2021_spind.pdf). 
<br/>

One of the most prominent waveform patterns observed in the sleep EEG is the spindle, originally observed as waxing-waning 14 Hz oscillatory bursts <sup>1</sup>. Spindles have garnered substantial attention through numerous studies linking spindle activity to memory consolidation and neural plasticity during sleep <sup>2,3</sup>, as wellas recent studies associating deviations in spindle activity and morphology with aging <sup>4</sup>, Alzheimer’s disease <sup>5</sup>, epilepsy <sup>6</sup>, schizophrenia <sup>7</sup>, and autism <sup>8</sup>. Since 1935, spindles have largely been identified by visual inspection, and more recent automated spindle detection methods <sup>9</sup> are built to approximate human scoring rather than trying to identify objective markers of the neurophysiological phenomenon underlying spindles. The problem with this approach is that spindles are easily obfuscated by other frequency activity in the EEG signal, making visual identification exceptionally difficult and highly variable between scorers. Time-frequency analysis is well suited to solve this problem because it can  disambiguate the dynamics of simultaneously occurring time-varying oscillatory activity. TFpeaks systematically characterizes spindle activity from first principles using time-frequency phenomenology as the basis of observation, allowing us to move towards a more objective and evidence-based understanding of the underlying activity.

<br/>

<img src="https://prerau.bwh.harvard.edu/spindle_view/TFpeaks_gitImage.png" alt="spind"
	 width="500" height="250" />
<br/>
<sup><sub>Dimitrov T, He M, Stickgold R, Prerau MJ. Sleep spindles comprise a subset of a broader class of electroencephalogram events. Sleep. 2021 Apr 15:zsab099. doi: 10.1093/sleep/zsab099. Epub ahead of print. PMID: 33857311.</sup></sub>

<br/>
<br/>


## Hand Scoring TFσ peaks
The hand_scoring_tfpeaks function can be used to manually identify TFσ peaks on multitaper spectrograms. Running this function on EEG data opens an interface with the data spectrogram, hypnogram, and time-series signal. This interface allows, zooming, colorscale adjustment, TFpeak/event marking (bounding box creation), and saving of the TFpeak/event labels. See the function docstring to explore the hotkeys for further details.

Usage:
```
hand_scoring_tfpeaks(data, Fs, staging)
```

### Hand Scoring TFσ peaks Example
The following code shows how to load in test EEG data and run the hand_scoring_tfpeaks function - 
```
load('example_data/example_data.mat')  % loads in example data variables EEG, Fs, night, stage_times, stages, subject_name, t
hand_scoring_tfpeaks(EEG, Fs, staging)
```
The follow interface will appear and TFpeak/event scoring can begin - 
<br/>
<img src="https://prerau.bwh.harvard.edu/spindle_view/TFpeak_handscore_spindles.png" alt="spind"
	 width="500" height="250" />


To save or load labeled TFpeaks/events, select the "Markers" dropdown from the toolbar and click "Save Events" or "Load Events"

<br/>
<br/>



## TFσ peak Detection
The TF_peak_detection function uses multitaper spectrogram to identify time-frequency domain peaks. 

Usage:
```
[spindle_table] = TF_peak_detection(EEG, Fs, sleep_stages)

[spindle_table, spectrogram_used, fpeak_proms, fpeak_properties, tpeak_properties, noise_peak_times, lowbw_TFpeaks, fh] = TF_peak_detection(EEG, Fs, sleep_stages, kwargs)
```

### Parameter Descriptions
* **EEG** - 1D vector of signal data (required)
* **Fs** - sampling frequency of EEG data (Hz) (required)
* **sleep_stages** - n x 2 matrix where the 1st column is the timestamps of sleep stage changes and the 2nd column should be the new sleep stage at that timestamp. The stage coding in column 2 must be - WAKE=5, REM=4, NREM1=3, NREM2=2, NREM3=1, UNDEFINED=0 (required)
<br/>

* **detection stages**: vector of sleep stages in which spindles should be detected. The stage coding is - WAKE=5, REM=4, NREM1=3, NREM2=2, NREM3=1, UNDEFINED=0.  (optional keyword argument - default=[1,2,3])
* **to_plot** - logical to plot hypnoplot, spectrogram, and bounding boxes around detected spindles on the spectrogram (optional keyword argument - default=true).
* **verbose** - logical to output informative text to the Matlab console (optional keywork argument - default=true)
* **spindle_freq_range** -  2 element vector specifying lower and upper frequency bounds in which spindles can be found (optional keywork argument - default=[0, Fs/2])
* **extract_property** - logical  (optional keywork argument - default=false) 
* **artifact_detect** - logical to perform artifact detection on EEG before spindle detection. Note that segments identified as artifacts have their stages changed to WAKE (5). (optional keyword argument - default=true)
* **peak_freq_range** - 2 element vector specifying range of frequencies to look for peak prominence values within (optional keyword argument - default=[9,17])
* **find_freq_range** - 2 element vector (optional keyword argument - default=[max(0, peak_freq_range(1)-spectral_resol), min(Fs/2, peak_freq_range(2)+spectral_resol])
* **in_db** - logical to convert spectrogram from power to dB (optional keyword argument - default=false)
* **smooth_Hz** - double in Hz to specify smoothing of each slice of spectrum before peak finding (optional keyword argument - default=0)
* **smooth_sec** - double in seconds to specify window over which average smoothing of time-domain prominance curve occurs (optional keyword argument - default=0.3)
* **min_peak_distance_sec** - double in seconds to spefify the minimum peak width required for a peak to be detected (optional keywork argument - default=0.3)
* **detection_method** - char specifying the method of separating noise peaks from signal peaks. Options are 'kmeans' and 'threshold' (optional keyword argument - default='kmeans')
* **bandwidth_cut** - (optional keyword argument - default=true)
* **num_clusters** - integer to specify the number of clusters used in kmeans clustering to cluster noise peaks from signal peaks. Note that only the cluster with the highest peak prominance will be selected as signal and the other clusters will be specfied as noise. (optional keyword argument - default=2)
* **threshold_percentile** - double between 0 and 100 specifying the percentile cutoff of candidate TFpeaks prominance values to use in distiguishing between noise and signal TFpeaks. Used only if detection_method is 'threshold'. (optional ketwork argument - default=75)
* **MT_freq_max** - double in Hz specifying the maximum frequency to use when computing the multitaper spectrogram. (optional keyword argument - default=30)
* **MT_taper** - 2 element vector specifying the multitaper spectrogram DPSS taper parameters. The 1st element is the desired time-halfbandwidth product and the 2nd element is the desired number of tapers. (optional keyword argument - default=[2,3])
* **MT_window** - 2 element vector spevifying the multitaper spectrogram time window parameters. The 1st element is the window size in seconds and the 2nd element is the step size in seconds (optional keywork argument - default=[1, 0.005])
* **MT_min_NFFT** - integer specifying the minimum allowable NFFT size, adds zero padding for interpolation. (optional keyword argument - default=2<sup>10</sup>)
* **MT_detrend** - char specifying the method of detrending for each window of data in the multitaper spectrogram calculation. Possible choices are: 'linear', 'constant', and 'off'. (optional keyword argument - default='constant')
* **MT_weighting** - char specifying the method of DPSS taper weighting during the multitaper spectrogram caluclation. Possible choices are: 'unity', 'eigen', and 'adapt'. (optional keyword argument - default='unity')
 
### TFpeak Detection Example
The following code demostrates the usage of TF_peak_detect - 
```
load('example_data') % load the data 

% run the TF_peak_detection wrapper function to detect TF peaks during
% NREM2 sleep, with TF peak central frequencies confined to 10-16Hz
% Note: consider using clims.m to adjust color scale
[ TFpeaks_table, spectrogram_used, fpeak_proms, fpeak_properties, tpeak_properties ] = TF_peak_detection(EEG, Fs, [stage_times', stages'],...
        'to_plot',true, 'spindle_freq_range',[10,16], 'detection_stages',[2]);
```
Running the code should produce the following plot showing the data segment hypnogram, spectrogram, and bounding boxes indicating TFpeaks - 

<img src="https://prerau.bwh.harvard.edu/spindle_view/TFpeak_paper_example.png" alt="spind"
	 width="500" height="250" />
<br/>
<br/>


## Algorithm Desctiption

<br/>
<br/>

## Multitaper Spectrogram 
The multitaper_spectrogram_release function is used by TF_peak_detection to break down the EEG signal into the time-frequency domain. More information on the multitaper spectrogram and the latest release of the function can be found [here](https://github.com/preraulab/multitaper_toolbox)

<br/>
<br/>


## Artifact Detection
The EEG_detect_time_domain_artifacts function is used to detect artifacts in the EEG signal data before TFpeak detection is run. 

Usage:
```
[artifacts] = EEG_detect_time_domain_artifacts(data, Fs)

[artifacts, hf_artifacts, bb_artifacts, high_detrend, broad_detrend] = EEG_detect_time_domain_artifacts(data, Fs, method, hf_crit, hf_pass, bb_crit, bb_pass, smooth_duration, verbose, histogram_plot)
```
### Parameter Descriptions
* **data** - 1 x <number of samples> vector - time series data (required)
* **Fs** - double - sampling frequency in Hz (required)
* **method** - char 'std' to use iterative method (default) or a strict threshold on 'MAD',defined as K*MEDIAN(ABS(A-MEDIAN(A)))
* **hf_crit** - double - high frequency criterion - number of stds/MAD above the mean to remove (default: 4)
* **hf_pass** - double - high frequency pass band - frequency for high pass filter in Hz (default: 25 Hz)
* **bb_crit** - double - broadband criterion - number of stds/MAD above the mean to remove (default: 4)
* **bb_pass** - double - broadband pass band - frequency for high pass filter in Hz (default: .1 Hz)
* **smooth_duration** - double - time (in seconds) to smooth the time series (default: 2 seconds)
* **verbose** - logical - verbose output (default: false)
* **histogram_plot** - logical - plot histograms for debugging (default: false)


<br/>
<br/>


## Citations
The code contained in this repository is companion to the paper:  
> Dimitrov T, He M, Stickgold R, Prerau MJ. Sleep spindles comprise a subset of a broader class of electroencephalogram events. Sleep. 2021 Apr 15:zsab099. doi: 10.1093/sleep/zsab099. Epub ahead of print. PMID: 33857311.

which should be cited for academic use of this code.  

<br/>
<br/>


## Status 
All implementations are complete and functional but may receive updates occasionally

<br/>
<br/>


## References
1. Loomis AL, Harvey EN, Hobart GA. Cerebral states during sleep, as studied by human brain potentials. J Exp Psychol. 1937;21(2):127
2. Diekelmann S, Born J. The memory function of sleep. Nat Rev Neurosci. 2010;11(2):114-126. 
3. Fogel SM, Smith CT. The function of the sleep spindle: a physiological index of intelligence and a mechanism for sleep-dependent memory consolidation. Neurosci Biobehav Rev. 2011;35(5):1154-1165.
4. Helfrich RF, Mander BA, Jagust WJ, Knight RT, Walker MP. Old brains come uncoupled in sleep: slow wave-spindle synchrony, brain atrophy, and forgetting. Neuron. 2018;97(1):221-230.
5. Gorgoni M, Lauri G, Truglia I, et al. Parietal fast sleep spindle density decrease in Alzheimer’s disease and amnesic mild cognitive impairment. Neural Plast. 2016;2016.
6.  Myatchin I, Lagae L. Sleep spindle abnormalities in children with generalized spike-wave discharges. Pediatr Neurol. 2007;36(2):106-111.
7.  Manoach DS, Pan JQ, Purcell SM, Stickgold R. Reduced sleep spindles in schizophrenia: a treatable endophenotype that links risk genes to impaired cognition? Biol Psychiatry. 2016;80(8):599-608.
8.  Limoges E, Mottron L, Bolduc C, Berthiaume C, Godbout R. Atypical sleep architecture and the autism phenotype. Brain. 2005;128(5):1049-1061.
9.  Warby SC, Wendt SL, Welinder P, et al. Sleep-spindle detection: crowdsourcing and evaluating performance of experts, non-experts and automated methods. Nat Methods. 2014;11(4):385.

