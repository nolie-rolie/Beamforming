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

nMics = 8;
ula = phased.ULA(nMics,0.05,'Element',microphone); % spacing = 5 cm
c = 343; % speed of sound in air, in m/s

%% Simulate Received Signals

% [angle(deg), elevation(deg)]
ang_target = [-30; 0];
ang_1 = [20; 10];
ang_2 = [-10; 0];

fs = 44100; % adjust sample rate -> 44100 is SR for iPhone voice memos
NSampPerFrame = 1050; % must be a factor of fs
collector = phased.WidebandCollector('Sensor',ula,'PropagationSpeed',c,...
    'SampleRate',fs,'NumSubbands',NSampPerFrame,'ModulatedInput', false);

t_duration = 3;  % 3 seconds
t = 0:1/fs:t_duration-1/fs;

% white noise
prevS = rng(2008); % seeds the rng
noisePwr = 1e-4; % noise power

% preallocate
NTSample = t_duration*fs;
sigArray = zeros(NTSample,nMics);
audio_target = zeros(NTSample,1);
audio_1 = zeros(NTSample,1);
audio_2 = zeros(NTSample,1);

% set up audio device writer
audioWriter = audioDeviceWriter('SampleRate',fs, ...
        'SupportVariableSizeInput', true);

% checks if device has audio output
isAudioSupported = (length(getAudioDevices(audioWriter))>1);

FileReaderTarget = dsp.AudioFileReader('its_working.m4a',...
    'SamplesPerFrame',NSampPerFrame);
FileReader1 = dsp.AudioFileReader('van_halen_sample.m4a',...
    'SamplesPerFrame',NSampPerFrame);
FileReader2 = dsp.AudioFileReader('obnoxious_laugh.m4a',...
    'SamplesPerFrame',NSampPerFrame);



% simulate
for m = 1:NSampPerFrame:NTSample
    sig_idx = m:m+NSampPerFrame-1;
    % multiply by constant to boost signal, i.e. "2*FileReader2()"
    xT = FileReaderTarget(); 
    x1 = FileReader1();
    x2 = FileReader2();
    temp = collector([xT x1 x2],...
        [ang_target ang_1 ang_2]) + ... % set angles
        sqrt(noisePwr)*randn(NSampPerFrame,nMics); % adds random noise
    if isAudioSupported
        play(audioWriter,0.5*temp(:,2));
    end
    sigArray(sig_idx,:) = temp;
    audio_target(sig_idx) = xT;
    audio_1(sig_idx) = x1;
    audio_2(sig_idx) = x2;
end

% plot signal
plot(t,sigArray(:,2));
xlabel('Time (sec)'); ylabel ('Amplitude (V)');
title('Signal Received at Channel 2'); ylim([-3 3]);

%% Process with Time Delay Beamformer

% define steering direction
angSteer = ang_target;
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
ag_tdbf = pow2db(mean((audio_1+audio_2).^2+noisePwr)/...
    mean((tdbfOut - audio_target).^2));
disp(['The array gain is ', num2str(ag_tdbf), '.']);












