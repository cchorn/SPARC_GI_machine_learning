function [location] = getChannelLocation(subject, channelLabel)

    %   DESCRIPTION
    %   ===================================================================
    %   Get the gastric segment for a given channel label
    %
    %   INPUTS
    %   ===================================================================
    %   subject         :  (string) subject name
    %   channelLabel    :  (string) see list of channel Labels in
    %                      experiment_constants or summary objects in MDF
    %
    %   Author: Ameya C. Nanivadekar
    %   email: acnani@gmail.com
    
    summaryObj = mdf.load('subject',subject,'mdf_type','summary');

    if strfind(channelLabel,'paddle')
        chanSplit = strsplit(channelLabel,'paddle');
        if strfind(chanSplit{2},'-')
            idx = str2double(strsplit(chanSplit{2},'-'));
        else
            idx = str2double(chanSplit{2});
        end
        tmp = summaryObj.EGG.paddleLoc(idx);
        location = [tmp{:}];
    else
        location = channelLabel;
    end
end