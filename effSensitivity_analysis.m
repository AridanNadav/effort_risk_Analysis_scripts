% pe - vas/training analysis
% dynamometer training
    % per cent success

clear
close all

ALLsubjects=[601];
subjects2EXclud= [];
subjects=ALLsubjects(~ismember(ALLsubjects,subjects2EXclud));
forloop=length(subjects);

runs=4;

for subjectIndex = 1:forloop
    allRISKfiles=dir(['RISK1_' num2str(subjects(subjectIndex)) '_effort_sensitivity_*']);
    sizeallRISK=size(allRISKfiles);
    
    if sizeallRISK(1)~=runs
        warning(['subject ' num2str(subjects(subjectIndex)) ' has wrong number of files!!!'])
    else
        for riskRUN=1:runs
            filename=allRISKfiles(riskRUN).name;
            delimiter = '\t';
            startRow = 2;
            
            % Format for each line of text:
            %   column1: double (%f)
            %	column2: double (%f)
            %   column3: double (%f)
            %	column4: double (%f)
            %   column5: double (%f)
            %	column6: double (%f)
            %   column7: double (%f)
            %	column8: double (%f)
            %   column9: categorical (%C)
            % For more information, see the TEXTSCAN documentation.
            formatSpec = '%f%f%f%f%f%f%f%f%C%[^\n\r]';
            
            fileID = fopen(filename,'r');
            
            dataArray = textscan(fileID, formatSpec, 'Delimiter', delimiter, 'TextType', 'string', 'EmptyValue', NaN, 'HeaderLines' ,startRow-1, 'ReturnOnError', false, 'EndOfLine', '\r\n');
            rowSize= length(dataArray{1});
            
            tableStruct(riskRUN).effSen_table = table(dataArray{1:end-1}, 'VariableNames', {'Gain_gain','Gain_Effort_Level','Safe_gain','Safe_Effort_Level','if_sanity','GainisL','onset','RTchoice','choice'});

        end
               
        sub_num=['subject_' num2str(subjects(subjectIndex))];
        AllSubs.(sub_num)=tableStruct.effSen_table;
      
    end
end

%% choice analysis
notSan=~ismember(tableStruct.effSen_table{:,5},1);

for h=1:length(subjects)
    sub_num=['subject_' num2str(subjects(h))];
    AllSubs.(sub_num).('if_sanity')(notSan);
    
    chose_gainR=AllSubs.(sub_num).('GainisL')==0 & AllSubs.(sub_num).('choice')=='RightArrow' & notSan;
    chose_gainL=AllSubs.(sub_num).('GainisL')==1 & AllSubs.(sub_num).('choice')=='LeftArrow' & notSan;
    chose_gain=chose_gainR+chose_gainL;
    
    gain_choice=sum(chose_gain)/sum(notSan);
end

y1 = gain_choice;
[H1]=bar(y1);
set(H1,'BarWidth',0.5);
ax = gca;  %% get handle to current axes
axis([0,2,0,1]);
refline(0,0.5);
title('Proportion of gain options chosen');

%% sanity analysis
San=ismember(tableStruct.effSen_table{:,5},1);

for h=1:length(subjects)
    sub_num=['subject_' num2str(subjects(h))];
    AllSubs.(sub_num).('if_sanity')(San);
    
    san_gainR=AllSubs.(sub_num).('GainisL')==0 & AllSubs.(sub_num).('choice')=='RightArrow' & San;
    san_gainL=AllSubs.(sub_num).('GainisL')==1 & AllSubs.(sub_num).('choice')=='LeftArrow' & San;
    san_gain=san_gainR+san_gainL;
    
    sanCorrect1=(AllSubs.(sub_num).('Gain_Effort_Level')==AllSubs.(sub_num).('Safe_gain')) & san_gain==1;
    sanCorrect2=(AllSubs.(sub_num).('Gain_gain')==AllSubs.(sub_num).('Safe_Effort_Level')) & san_gain==0;
    sanity=sanCorrect1+sanCorrect2;
    
    sanAccuracy=sum(sanity)/sum(San);
end

%% choice by effort/gain

effSen_table = table(dataArray{1:end-1}, 'VariableNames', {'Gain_gain','Gain_Effort_Level','Safe_gain','Safe_Effort_Level','if_sanity','GainisL','onset','RTchoice','choice'});
load('riskTable_choices.mat')

gains=(1:0.5:3);
gainsChoice_proportions=zeros(1,5);
for g=1:length(gains)
    
    gainsChoice_proportions(g)=(sum(riskTable_choices{:,1}==gains(g) & riskTable_choices{:,10}==1))/...
    sum(riskTable_choices{:,1}==gains(g) & riskTable_choices{:,5}~=1);
    
end

efforts=[0.3,0.45,0.6,0.9];
effortsChoice_proportions=zeros(1,5);

for e=1:length(efforts)
    
    effortsChoice_proportions(e)=(sum(riskTable_choices{:,2}==efforts(e) & riskTable_choices{:,10}==1))/...
    sum(riskTable_choices{:,2}==efforts(e));
    
end

%% correlations

% correlation effort vs. choice
a=[riskTable_choices{:,2},riskTable_choices{:,10}];
corrEffortChoice=corrcoef(a,'rows','complete');
corr1=corrEffortChoice(1,2);

% correlation gain vs. choice
b=[riskTable_choices{:,1}-riskTable_choices{:,3},riskTable_choices{:,10}];
corrGainChoice=corrcoef(b,'rows','complete');
corr2=corrGainChoice(1,2);