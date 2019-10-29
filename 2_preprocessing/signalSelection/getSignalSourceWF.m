function [conditionedWF, fs] = getSignalSourceWF(subject, trialnum, signalType, chanLabel, varargin)
    
    %   DESCRIPTION
    %   ===================================================================
    %   Loads the concatenated and filtered waveform from the corresponding 
    %   MDF object(s) for the specific subject/trial/channel/signal type
    %
    %   INPUTS
    %   ===================================================================
    %   subject     :  (string) name of subejct
    %   trialnum    :  (int) trial number
    %   signalType  :  (string) type of source signal se/bp/CA/PA/bPA/emg
    %   chanLabel   :  (string) array of MDF objects containing a wf field
    %   
    %   OPTIONAL INPUTS
    %   ===================================================================
    %   fs                  : (double) sampling frequency
    %   referenceWf         : (string) reference to use none/CA/PA
    %   artifact_subtract 	: (bool) automate removal of high amplitude artifacts
    %   filter_signal       : (bool) filter and downsample signal
    %   filtQ               : (struct) query to load saved MDF filter
    %   object
    %   
    %   NOTE
    %   ===================================================================
    %   se/bp/CA/PA/bPA/emg signal sources correspond to single ended,
    %   bipolar, Common Average, Paddle Average, bipolar Paddle Average and
    %   intramuscular EMG
    %
    %   Author: Ameya C. Nanivadekar
    %   email: acnani@gmail.com

    varargin = sanitizeVarargin(varargin);
    DEFINE_CONSTANTS
    fs = 2e3;
    referenceWf = 'CA';
    artifact_subtract = false;
    filter_signal = true;
    filtQ = struct('mdf_type','filter','filterType','FIR','fs',10,'fp',0.3);
    END_DEFINE_CONSTANTS

    switch signalType
        case 'se'
            wfObj = mdf.load('subject',subject,'trial',trialnum,'mdf_type','egg','EGGlabel',chanLabel);
        case 'bp'
            wfObj = mdf.load('subject',subject,'trial',trialnum,'mdf_type','bipolarEGG','chanLabel',chanLabel);
        case 'CA'
            wfObj = mdf.load('subject',subject,'trial',trialnum,'mdf_type','CAR');
        case 'PA'
            wfObj = mdf.load('subject',subject,'trial',trialnum,'mdf_type','paddleAvgEGG','chanLabel',chanLabel);
        case 'bPA'
            wfObj = mdf.load('subject',subject,'trial',trialnum,'mdf_type','bipolarPaddleAvgEGG','chanLabel',chanLabel);
        case 'emg'
            wfObj = mdf.load('subject',subject,'trial',trialnum,'mdf_type','emg','EMGlabel',chanLabel);
    end
    % extract WF
    wf = concatenateWF(wfObj);
    if strcmp(signalType, 'emg')
        wf = diff(wf')';
    end
    
    % query reference object and extrsact WF
    if strcmp('none',referenceWf)
        refWF = 0;

    elseif strcmp('CA',referenceWf)
        refObj = mdf.load('subject',subject,'trial',trialnum,'mdf_type','CAR');
        refWF = concatenateWF(refObj);

    elseif strcmp('PA', referenceWf)
        summaryObj = mdf.load('subject',subject,'mdf_type','summary');
        if strcmp(signalType,'se')
            paddleNum = summaryObj.EGG.paddleNum(summaryObj.EGG.label == chanLabel);
            refObj = mdf.load('subject',subject,'trial',trialnum,'mdf_type','paddleAvgEGG','paddleNum',paddleNum);
            refWF = concatenateWF(refObj);

        elseif strcmp(signalType,'bp')
            chanNums = str2double(strsplit(chanLabel{:},'-'));
            paddle1 = summaryObj.EGG.paddleNum(ismember(summaryObj.EGG.label, chanNums(1)));
            paddle2 = summaryObj.EGG.paddleNum(ismember(summaryObj.EGG.label, chanNums(2)));
            refObj1 = mdf.load('subject',subject,'trial',trialnum,'mdf_type','paddleAvgEGG','paddleNum',paddle1);
            refObj2 = mdf.load('subject',subject,'trial',trialnum,'mdf_type','paddleAvgEGG','paddleNum',paddle2);
            refWF = concatenateWF(refObj1) + concatenateWF(refObj2);
        end
    else
        error('invalid reference argument')
    end
    
    % subtract reference
    conditionedWF = wf - refWF;
    wfLen = length(conditionedWF);
    
    if filter_signal
        filterObj = mdf.load(filtQ);
        
        % filtering and artifact rejection
        if artifact_subtract
            artifactThreshMult = 3;
            [conditionedWF, artifactIdx] = templateSubtraction(conditionedWF, fs, artifactThreshMult);
        end
        [b,a] = butter(2,2.5/(fs/2));
        highFiltObj = mdf.load('mdf_type','filter','filterType','FIR','fs',fs,'fp',2.5);
        conditionedWF = filtfilt(highFiltObj.data.FIRfilter.Numerator, 1, conditionedWF);
        conditionedWF = filtfilt(b,a,conditionedWF);

        fs_old = fs;
        fs = 10;
        oldTime = linspace(0,wfLen/fs_old,wfLen);
        newTime = linspace(0,wfLen/fs_old,wfLen/fs_old*fs);
        conditionedWF = interp1(oldTime , conditionedWF, newTime, 'linear')';
        
%         [b1,a1] = butter(2,0.3/(fs/2));
%         conditionedWF = filtfilt(b1,a1, conditionedWF);
        if filterObj.fs == fs
            if strcmp('butterworth', filterObj.filterType)
                conditionedWF = filtfilt([filterObj.md.coeff_b, filterObj.md.coeff_a], conditionedWF);
            elseif strcmp('FIR', filterObj.filterType)
                conditionedWF = filtfilt(filterObj.data.FIRfilter.Numerator, 1, conditionedWF);
            else
                error('invalid filter type')
            end
        else
            error('fs mismatch')
        end
    end
    
end
    
    