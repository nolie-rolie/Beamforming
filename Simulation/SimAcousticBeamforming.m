% AcousticBeamformingSimulation.m
% Author: Nolan Fey
% 10/20/2020

clc;
clear;
close all;

%% Define a Uniform Linear Array of Microphones

% model omnindirectional microphone, operating range 20 Hz - 20 kHz
microphone = ...
    phased.OmnidirectionalMicrophoneElement('FrequencyRange',[20 20e3]);

nMics = 10;
ula = phased.ULA(nMics,0.05,'Element',microphone); % spacing = 5 cm
c = 343; % speed of sound in air, in m/s

%% Simulate Received Signals

% [angle(deg), elevation(deg)]
ang_dft = [-30; 0];
ang_cleanspeech = [-10; 10];
ang_laughter = [20; 0];

%fs = 8000;
fs = 44100;
collector = phased.WidebandCollector('Sensor',ula,'PropagationSpeed',c,...
    'SampleRate',fs,'NumSubbands',1050,'ModulatedInput', false);

t_duration = 3;  % 3 seconds
t = 0:1/fs:t_duration-1/fs;

% white noise
prevS = rng(2008); % seeds the rng
noisePwr = 1e-4; % noise power

% preallocate
NSampPerFrame = 1050;
NTSample = t_duration*fs;
sigArray = zeros(NTSample,nMics);
voice_dft = zeros(NTSample,1);
voice_cleanspeech = zeros(NTSample,1);
voice_laugh = zeros(NTSample,1);

% set up audio device writer
audioWriter = audioDeviceWriter('SampleRate',fs, ...
        'SupportVariableSizeInput', true);

% checks if device has audio output
isAudioSupported = (length(getAudioDevices(audioWriter))>1);

% dftFileReader = dsp.AudioFileReader('dft_voice_8kHz.wav',...
%     'SamplesPerFrame',NSampPerFrame);
% speechFileReader = dsp.AudioFileReader('cleanspeech_voice_8kHz.wav',...
%     'SamplesPerFrame',NSampPerFrame);
% laughterFileReader = dsp.AudioFileReader('laughter_8kHz.wav',...
%     'SamplesPerFrame',NSampPerFrame);

vanhalenFileReader = dsp.AudioFileReader('van_halen_sample.m4a',...
    'SamplesPerFrame',NSampPerFrame);
obnoxiouslaughFileReader = dsp.AudioFileReader('obnoxious_laugh.m4a',...
    'SamplesPerFrame',NSampPerFrame);
targetFileReader = dsp.AudioFileReader('its_working.m4a',...
    'SamplesPerFrame',NSampPerFrame);


% simulate
for m = 1:NSampPerFrame:NTSample
    sig_idx = m:m+NSampPerFrame-1;
%     x1 = dftFileReader();
%     x2 = speechFileReader();
%     x3 = 2*laughterFileReader(); % 2* makes laughter louder
    x1 = targetFileReader();
    x2 = obnoxiouslaughFileReader();
    x3 = vanhalenFileReader();
    temp = collector([x1 x2 x3],...
        [ang_dft ang_cleanspeech ang_laughter]) + ... % set angles
        sqrt(noisePwr)*randn(NSampPerFrame,nMics); % adds random noise
    if isAudioSupported
        play(audioWriter,0.5*temp(:,2));
    end
    sigArray(sig_idx,:) = temp;
    voice_dft(sig_idx) = x1;
    voice_cleanspeech(sig_idx) = x2;
    voice_laugh(sig_idx) = x3;
end

% plot signal
plot(t,sigArray(:,2));
xlabel('Time (sec)'); ylabel ('Amplitude (V)');
title('Signal Received at Channel 2'); ylim([-3 3]);

%% Process with Time Delay Beamformer

% define steering direction
angSteer = ang_dft;
beamformer = phased.TimeDelayBeamformer('SensorArray',ula,...
    'SampleRate',fs,'Direction',angSteer,'PropagationSpeed',c);
disp(beamformer);

signalsource = dsp.SignalSource('Signal',sigArray,...
    'SamplesPerFrame',NSampPerFrame);

tdbfOut = zeros(NTSample,1);

for m = 1:NSampPerFrame:NTSample
    temp = beamformer(signalsource());
    if isAudioSupported
        play(audioWriter,temp);
    end
    tdbfOut(m:m+NSampPerFrame-1,:) = temp;
end

% plot in new figure window
figure
plot(t,tdbfOut);
xlabel('Time (Sec)'); ylabel ('Amplitude (V)');
title('Time Delay Beamformer Output'); ylim([-3 3]);

% one can measure the speech enhancement by the array gain, which is the 
% ratio of output signal-to-interference-plus-noise ratio (SINR) to input 
% SINR.
ag_tdbf = pow2db(mean((voice_cleanspeech+voice_laugh).^2+noisePwr)/...
    mean((tdbfOut - voice_dft).^2));
disp(['The array gain is ', num2str(ag_tdbf), '.']);












