# TFsigma_Peak_paper
### This is the repository for public release of Matlab code for the TF_sigma_Peak paper.
--- 

## Table of Contents
* [General Information](#general-information)
* [Hand Scoreing TFpeaks](#hand-scoring-tfpeaks)
* [TFpeak Detection](#tfpeak-detection)
* [Multitaper Spectrogram](#multitaper-spectrogram )
* [Artifact Detection](#artifact-detection)
* [Citations](#citations)
* [Status](#status)
<br/>
<br/>

## General Information
The code in this repository is companion to the paper [Sleep spindles comprise a subset of a broader class of electroencephalogram events](https://prerau.bwh.harvard.edu/publications/sleep_2021_spind.pdf). 
<br/>

<img src="https://prerau.bwh.harvard.edu/spindle_view/TFpeaks_gitImage.png" alt="spind"
	 width="500" height="250" />
<br/>
<sup><sub>Dimitrov T, He M, Stickgold R, Prerau MJ. Sleep spindles comprise a subset of a broader class of electroencephalogram events. Sleep. 2021 Apr 15:zsab099. doi: 10.1093/sleep/zsab099. Epub ahead of print. PMID: 33857311.</sup></sub>

<br/>

## Hand Scoring TFpeaks
The hand_scoring_tfpeaks function can be used to manually identify TFsigma peaks on multitaper spectrograms. Running this function on EEG data opens an interface with the data spectrogram, hypnogram, and time-series signal. This interface allows, zooming, colorscale adjustment, TFpeak/event marking (bounding box creation), and saving of the TFpeak/event labels. See the function docstring to explore the hotkeys for further details.

Usage:
```
hand_scoring_tfpeaks(data, Fs, staging)
```

### Hand Scoring TFpeaks Example
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

To use EEG data from an EDF file, load in the data using the blockEdfLoad function (link). 
<br/>

## TFpeak Detection
The TF_peak_detection function can be used to 

Usage:
```
[spindle_table] = TF_peak_detection(EEG, Fs, sleep_stages)

[spindle_table, spectrogram_used, fpeak_proms, fpeak_properties, tpeak_properties, noise_peak_times, lowbw_TFpeaks, fh] = TF_peak_detection(EEG, Fs, sleep_stages, ...
'detection_stages', detection_stages, 'to_plot', to_plot, 'verbose', verbose, 'spindle_freq_range', spindle_freq_range, ...
'extract_porperty', extract_property, 'artifact_detect', artifact_detect, 'peak_freq_range', peak_freq_range, ...
'find_freq_range', find_freq_range, 'in_db', in_db, 'smooth_Hz', smooth_Hz, 'smooth_sec', smooth_sec, ...
'MinPeakDistance_sec', MinPeakDistance_sec, 'detection_method', detection_method, 'bandwidth_cut', bandwidth_cut, ...
'num_clusters', num_clusters, 'threshold_percentile', threshold_percentile, 'MT_freq_max', MT_freq_max, 'MT_taper', MT_taper, ...
'MT_window', MT_window, 'MT_min_NFFT', MT_min_NFFT, 'MT_detrend', MT_detrend)
```

### TFpeak Detection Examples

<br/>

## Multitaper Spectrogram 

<br/>

## Artifact Detection

<br/>

## Citations
The code contained in this repository is companion to the paper:  
> Dimitrov T, He M, Stickgold R, Prerau MJ. Sleep spindles comprise a subset of a broader class of electroencephalogram events. Sleep. 2021 Apr 15:zsab099. doi: 10.1093/sleep/zsab099. Epub ahead of print. PMID: 33857311.

which should be cited for academic use of this code.  
<br/>

## Status 
All implementations are complete and functional but may receive updates occasionally
<br/>

