function [objArray] = getAllTrialtypeObjects(subject, trialType)
    
    %   DESCRIPTION
    %   ===================================================================
    %   Get all MDF objects for a particular trial type
    %
    %   INPUTS
    %   ===================================================================
    %   subject         :  (string) subject name
    %   trialType       :  (string) see list of trial types in
    %                      experiment_constants or summary objects in MDF
    
    objArray = mdf.load('subject',subject,'mdf_type','trial','trialType',trialType);
end