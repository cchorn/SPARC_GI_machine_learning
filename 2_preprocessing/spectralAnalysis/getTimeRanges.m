function [baselineT_min, targetT_min] = getTimeRanges(trialObj)

    %   DESCRIPTION
    %   ===================================================================
    %   Extract event timestamps/annotations for balloon, stim, emetine, 
    %   and behavioral trials 
    %
    %   INPUTS
    %   ===================================================================
    %   trialObj   :  (mdfObj) trial object in MDF
    %
    %   Author: Ameya C. Nanivadekar
    %   email: acnani@gmail.com

    if strcmp(trialObj.trialType,'balloon')
        baselineT_min = [0 trialObj.md.params.preInfusion];
        targetT_min = trialObj.md.params.preInfusion + [0 trialObj.md.params.rampUp + trialObj.md.params.hold + trialObj.md.params.rampDown];
    
    elseif strcmp(trialObj.trialType,'stim')
        params = trialObj.md.params;
        baselineT_min = [0, params.prestim_min];
        targetT_min = params.prestim_min + [0, params.stim_min];
        
    elseif strcmp(trialObj.trialType,'emetine')
        baselineT_min  = [0 trialObj.md.annotations.infusionStart_sec/60];
        targetT_min = [trialObj.md.annotations.infusionEnd_sec/60 trialObj.md.annotations.retching_sec(1)/60];

    elseif strcmp(trialObj.trialType,'feeding')
        baselineT_min  = [0 trialObj.md.annotations.foodPresented_min];
        if ischar(trialObj.md.annotations.foodRemoved_min)
            if ismember(trialObj.subject, {'40-18','48-18'})
                targetT_min = trialObj.md.annotations.foodPresented_min + [0, 17];
            else
                targetT_min = trialObj.md.annotations.foodPresented_min + [0, 30];
            end
        else
            targetT_min = [trialObj.md.annotations.foodPresented_min, trialObj.md.annotations.foodRemoved_min];
        end

    elseif strcmp(trialObj.trialType,'emetine_awake')
        baselineT_min  = [0 trialObj.md.annotations.emetineInfusion_startT_min];
        targetT_min = [trialObj.md.annotations.emetineInfusion_endT_min, trialObj.md.annotations.retching_min];
        
    elseif strcmp(trialObj.trialType,'water_awake')
        baselineT_min  = [0 trialObj.md.annotations.waterInfusion_startT_min];
%         if strcmp(trialObj.subject, '40-18')
%             targetT_min = trialObj.md.annotations.waterInfusion_endT_min + [0, 17];
%         else
            targetT_min = trialObj.md.annotations.waterInfusion_endT_min + [0, 30];
%         end

    end
end