% AcousticDOAEstimation_2.m
% Author: Nolan Fey
% 10/28/2020


clc;
clear;
close all;

%% Define a Uniform Linear Array of Microphones

% model omnindirectional microphone, operating range 20 Hz - 20 kHz
microphone = ...
    phased.OmnidirectionalMicrophoneElement('FrequencyRange',[20 20e3]);

nMics = 8;
ula = phased.ULA(nMics,0.05,'Element',microphone); % spacing = 5 cm
c = 343; % speed of sound in air, in m/s

%% Simulate Received Signals

% [angle(deg), elevation(deg)]
ang_target = [-70; 0];
ang_laugh = [0; 0];
ang_VanHalen = [70; 0];

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

vanhalenFileReader = dsp.AudioFileReader('van_halen_sample.m4a',...
    'SamplesPerFrame',NSampPerFrame);
obnoxiouslaughFileReader = dsp.AudioFileReader('obnoxious_laugh.m4a',...
    'SamplesPerFrame',NSampPerFrame);
targetFileReader = dsp.AudioFileReader('its_working.m4a',...
    'SamplesPerFrame',NSampPerFrame);


% simulate
for m = 1:NSampPerFrame:NTSample
    sig_idx = m:m+NSampPerFrame-1;
    x1 = targetFileReader();
    x2 = obnoxiouslaughFileReader();
    x3 = vanhalenFileReader();
    temp = collector([x1 x2 x3],...
        [ang_target ang_laugh ang_VanHalen]) + ... % set angles
        sqrt(noisePwr)*randn(NSampPerFrame,nMics); % adds random noise
    if isAudioSupported
        play(audioWriter,0.5*temp(:,2));
    end
    sigArray(sig_idx,:) = temp;
    voice_dft(sig_idx) = x1;
    voice_cleanspeech(sig_idx) = x2;
    voice_laugh(sig_idx) = x3;
end

%% Beamscan DOA Estimator

beamformer = phased.TimeDelayBeamformer('SensorArray',ula,...
    'SampleRate',fs,'DirectionSource','Input port','PropagationSpeed',c);

range = -90:90;
size = length(range);

maxLevels = zeros(length(range));

bfOut = zeros();

for iter = 1:size
    
    bfOut = step(beamformer,sigArray,[range(iter); 0]);
    
    maxLevels(iter) = max(bfOut);
    
end


test = 0;
for iter = 1:size
    if(test < maxLevels(iter))
       DOA = range(iter); 
       test = maxLevels(iter);
    end
end

disp(['The direction or arrival was ',num2str(DOA),'.']);

% plot in new figure window
figure
plot(range,maxLevels);
xlabel('Angle (deg)'); ylabel ('Amplitude (V)');
title('Max Level at Each Angle');




