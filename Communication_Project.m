clc
%% READING AUDIOS
[FirstSignal_original,F1]= audioread('Short_BBCArabic2.wav');
%sound(FirstSignal_original,F1);
[SecondSignal_original,F2]=audioread('Short_FM9090.wav');
%sound(SecondSignal_original,F2);

%Conversion from stereo to mono
FirstSignal_original=FirstSignal_original(:, 1)+FirstSignal_original(:, 2);
SecondSignal_original=SecondSignal_original(:, 1)+SecondSignal_original(:, 2);
%Comparision and pading
if length(FirstSignal_original)>length(SecondSignal_original)
    %In case second audio is shorter, padding occurs on the second audio
    SecondSignal_original(length(FirstSignal_original))=0;
else
    %Otherwise, padding occurs on the first audio
    FirstSignal_original(length(SecondSignal_original))=0;
end


%READ AUDIOS Plots

%N1 = - length(FirstSignal_original)/2 : length(FirstSignal_original)/2 -1;
%f1=figure('Name','First Signal','NumberTitle','off');
%plot(N1*F1/length(FirstSignal_original), abs(fftshift(fft(FirstSignal_original))))
%xlabel('Hz')


%f2=figure('Name','Second Signal','NumberTitle','off');
%plot(N1*F2/length(SecondSignal_original), abs(fftshift(fft(SecondSignal_original))))
%xlabel('Hz')

%% INTERPOLATION
FirstSignal = interp(FirstSignal_original,10);
SecondSignal = interp(SecondSignal_original,10);
Fs=10*F1; %Multiplied by 10 due to interpolation
t=0:1/Fs:((length(FirstSignal)-1)/Fs);


%% MODULATION
%Carriers to carry the signal
Carrier1=cos(2*pi*100000*t);
Carrier2=cos(2*pi*150000*t);

%Multiplying signals by the carriers
AM1=FirstSignal.*Carrier1'; 
AM2=SecondSignal.*Carrier2'; 
%The transmitted signal
AMtotal=AM1+AM2; 

%MODULATION STAGE Plots

%N2=-length(AM1)/2:length(AM1)/2-1;
%f3=figure('Name','First Modulated Signal','NumberTitle','off');
%plot(N2*Fs/length(AM1), abs(fftshift(fft(AM1)))); 
%xlabel('Hz');

N3=-length(AM2)/2:length(AM2)/2-1;
%f4=figure('Name','Second Modulated Signal','NumberTitle','off');
%plotting the second modulated signal
%plot(N3*Fs/length(AM2), abs(fftshift(fft(AM2))));
%xlabel('Hz');

N4=-length(AMtotal)/2:length(AMtotal)/2-1;
f5=figure('Name','Modulated Signal','NumberTitle','off');
plot(N4*Fs/length(AMtotal), abs(fftshift(fft(AMtotal))));
title('Modulated Signal');
xlabel('Hz');


%% RF STAGE
%BandPass filter to allow 100KHz signal
bpFilt1 = designfilt('bandpassfir','FilterOrder',20, ...
    'CutoffFrequency1',90e3,'CutoffFrequency2',110e3, ...
    'SampleRate',Fs);
% Applying bpFilt1 on the modulated message to recover signal one
FD_Signal1=filter(bpFilt1,AMtotal);

%BandPass filter to allow 150KHz signal
bpFilt2 = designfilt('bandpassfir','FilterOrder',20, ...
    'CutoffFrequency1',140e3,'CutoffFrequency2',160e3, ...
    'SampleRate',Fs);
% Applying bpFilt2 on the modulated message to recover signal two
FD_Signal2=filter(bpFilt2,AMtotal);

%TO REMOVE RF FILTER EFFECT
%FD_Signal1=AMtotal;
%FD_Signal2=AMtotal;

%RF STAGE plots
f6=figure('Name','RF messages','NumberTitle','off');
subplot(2,1,1);
plot(N3*Fs/length(FD_Signal1),abs(fftshift(fft(FD_Signal1))));
title('Signal one');
xlabel('Hz');

subplot(2,1,2);
plot(N3*Fs/length(FD_Signal2),abs(fftshift(fft(FD_Signal2))));
title('Signal two');
xlabel('Hz');


%% MIXER STAGE
%IF oscillators
IF=25000;
Osc1=cos(2*pi*(100000+IF)*t);
Osc2=cos(2*pi*(150000+IF)*t);

%Multiplying the signal with the IF oscillators
AM_IF1=FD_Signal1.*Osc1';
AM_IF2=FD_Signal2.*Osc2';


%MIXER STAGE Plots
f7=figure('Name','Mixer messages','NumberTitle','off');
subplot(2,1,1);
plot(N3*Fs/length(FD_Signal1),abs(fftshift(fft(AM_IF1))));
title('Signal one');
xlabel('Hz');

subplot(2,1,2);
plot(N3*Fs/length(FD_Signal2),abs(fftshift(fft(AM_IF2))));
title('Signal two');
xlabel('Hz');


%% IF STAGE
%BandPass filter to allow the signal located at 25KHz
bpFilt3 = designfilt('bandpassfir','FilterOrder',20, ...
    'CutoffFrequency1',15e3,'CutoffFrequency2',35e3, ...
    'SampleRate',Fs);
%Applying bpFilt3 on the message to remove images
IF1= filter(bpFilt3,AM_IF1);
IF2= filter(bpFilt3,AM_IF2);

%IF STAGE Plots
f8=figure('Name','IF messages','NumberTitle','off');
subplot(2,1,1);
plot(N3*Fs/length(FD_Signal1),abs(fftshift(fft(IF1))));
title('Signal one');
xlabel('Hz');

subplot(2,1,2);
plot(N3*Fs/length(FD_Signal2),abs(fftshift(fft(IF2))));
title('Signal two');
xlabel('Hz');


%% BASEBAND STAGE
%Baseband oscillator
BBOsc=cos(2*pi*25000*t); %oscilator with 25k frequency

%1K offset at the receiver
%BBOsc=cos(2*pi*26000*t); %oscilator with 26k frequency

%0.1K offset at the receiver
%BBOsc=cos(2*pi*25100*t); %oscilator with 25.1k frequency

%Multiplying signals by the baseband oscillator
BB_Signal1=IF1.*BBOsc'; 
BB_Signal2=IF2.*BBOsc';

%BASEBAND Plots
%Plotting the messages before applying Low pass filter
f9=figure('Name','Baseband messages','NumberTitle','off');
subplot(2,1,1);
N5 = - length(BB_Signal1)/2 : length(BB_Signal1)/2 -1;
plot(N5*F1/length(BB_Signal1), abs(fftshift(fft(BB_Signal1))))
title('Signal one');
xlabel('Hz');

subplot(2,1,2);
N6 = - length(BB_Signal2)/2 : length(BB_Signal2)/2 -1;
plot(N6*F2/length(BB_Signal2), abs(fftshift(fft(BB_Signal2))))
title('Signal two');
xlabel('Hz');


%% LOW PASS FILTER
%Low pass filter to remove noise
lpFilt = designfilt('lowpassfir','FilterOrder',20, ...
    'CutoffFrequency',10e3, ...
    'SampleRate', Fs);

%Appyling lpFilt on the messages
Signal1=filter(lpFilt,BB_Signal1);
Signal2=filter(lpFilt,BB_Signal2);



%LOW PASS FILTER Plots
f10=figure('Name','Received messages','NumberTitle','off');
subplot(2,1,1);
N1 = - length(Signal1)/2 : length(Signal1)/2 -1;
plot(N1*F1/length(Signal1), abs(fftshift(fft(Signal1))));
title('Signal one');
xlabel('Hz');

subplot(2,1,2);
N2 = - length(Signal2)/2 : length(Signal2)/2 -1;
plot(N2*F2/length(Signal2), abs(fftshift(fft(Signal2))));
title('Signal two');
xlabel('Hz');

%% RECEIVED AUDIOS
%Removing interpolation using downsample
Audio1= downsample(Signal1,10);
Audio2= downsample(Signal2,10);

%sound(10*Audio1,F1);
%pause(20);
%sound(10*Audio2,F2);
