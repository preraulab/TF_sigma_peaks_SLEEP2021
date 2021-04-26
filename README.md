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
* [References](#references)
<br/>
<br/>

## General Information
The code in this repository is companion to the paper [Sleep spindles comprise a subset of a broader class of electroencephalogram events](https://prerau.bwh.harvard.edu/publications/sleep_2021_spind.pdf). 
<br/>

One of the most prominent waveform patterns observed in the sleep EEG is the spindle, originally observed as waxing-waning 14 Hz oscillatory bursts <sup>1</sup>. Spindles have garnered substantial attention through numerous studies linking spindle activity to memory consolidation and neural plasticity during sleep <sup>2,3</sup>, as wellas recent studies associating deviations in spindle activity and morphology with aging <sup>4</sup>, Alzheimer’s disease <sup>5</sup>, epilepsy <sup>6</sup>, schizophrenia <sup>7</sup>, and autism <sup>8</sup>. Since 1935, spindles have largely been identified by visual inspection, and more recent automated spindle detection methods <sup>9</sup> are built to approximate human scoring rather than trying to identify objective markers of the neurophysiological phenomenon underlying spindles. The problem with this approach is that spindles are easily obfuscated by other frequency activity in the EEG signal, making visual identification exceptionally difficult and highly variable between scorers. Time-frequency analysis is well suited to solve this problem because it can  disambiguate the dynamics of simultaneously occurring time-varying oscillatory activity. The TFpeaks algorithm systematically characterizes spindle activity from first principles using time-frequency phenomenology as the basis of observation, allowing us to move towards a more objective and evidence-based understanding of the underlying activity.

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

