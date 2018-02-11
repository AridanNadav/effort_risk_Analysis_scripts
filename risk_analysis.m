clear
close all

ALLsubjects=[601];
subjects2EXclud= [];
subjects=ALLsubjects(~ismember(ALLsubjects,subjects2EXclud));
forloop=length(subjects);

runs=4;

for subjectIndex = 1:forloop;
    allRISKfiles=dir(['RISK1_' num2str(subjects(subjectIndex)) '_risk_*']); % risk files
    sizeallRISK=size(allRISKfiles);
    
    if sizeallRISK(1)~=runs % subjects must have exactly 4 files
        warning(['subject ' num2str(subjects(subjectIndex)) ' has wrong number of files!!!'])
    else
        for riskRUN=1:runs;            
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
            %   column7: categorical (%C)
            % For more information, see the TEXTSCAN documentation.
            formatSpec = '%f%f%f%f%f%f%C%[^\n\r]';
            
            fileID = fopen(filename,'r');
            
            dataArray = textscan(fileID, formatSpec, 'Delimiter', delimiter, 'TextType', 'string', 'EmptyValue', NaN, 'HeaderLines' ,startRow-1, 'ReturnOnError', false, 'EndOfLine', '\r\n');
            rowSize= length(dataArray{1});
            
            tableStruct(riskRUN).riskTable = table(dataArray{1:end-1}, 'VariableNames', {'Effort_Risk','Effort_Level','if_sanity','RiskisL','onset','RTchoice','choice'});
            % separate tables for each risk file (4)
        end
        joinStruct1=outerjoin(tableStruct(1).riskTable,tableStruct(2).riskTable,'MergeKeys',true);
        joinStruct2=outerjoin(tableStruct(3).riskTable,tableStruct(4).riskTable,'MergeKeys',true);
        joinStruct3=outerjoin(joinStruct1,joinStruct2,'MergeKeys',true);

        sub_num=['subject_' num2str(subjects(subjectIndex))];
        AllSubs.(sub_num)=joinStruct3;
    end
end

%% sanity accuracy
sanity_effort=[38,62];
san_vec=ismember(joinStruct3{:,2},sanity_effort); % 16 sanity tests

for h=1:length(subjects);
    sub_num=['subject_' num2str(subjects(h))];
    AllSubs.(sub_num).('if_sanity')(san_vec);
    
    san_riskR=AllSubs.(sub_num).('RiskisL')==0 & AllSubs.(sub_num).('choice')=='RightArrow' & san_vec;
    san_riskL=AllSubs.(sub_num).('RiskisL')==1 & AllSubs.(sub_num).('choice')=='LeftArrow' & san_vec;
    san_risk=san_riskR+san_riskL;
    
    sanity=AllSubs.(sub_num).('if_sanity')(san_vec); % only sanity tests
    sanityChoices=san_risk(san_vec); % only sanity choices
    
    sanAnalysis=sanity==sanityChoices;
    sanAccuracy=sum(sanAnalysis)/16;
end

%% choice analysis
notSan_vec=~ismember(joinStruct3{:,2},sanity_effort);

for h=1:length(subjects);
    sub_num=['subject_' num2str(subjects(h))];
    AllSubs.(sub_num).('if_sanity')(notSan_vec);
    
    chose_riskR=AllSubs.(sub_num).('RiskisL')==0 & AllSubs.(sub_num).('choice')=='RightArrow' & notSan_vec;
    chose_riskL=AllSubs.(sub_num).('RiskisL')==1 & AllSubs.(sub_num).('choice')=='LeftArrow' & notSan_vec;
    chose_risk=chose_riskR+chose_riskL;
    
    risk_choice=sum(chose_risk)/200;
    
    fprintf(['Subject ' num2str(subjects(subjectIndex)) ' proportion of risk choice=' num2str(risk_choice)])
    
    if risk_choice<0.5
        fprintf(['\nSubject ' num2str(subjects(subjectIndex)) ' is risk-averse\n'])
    else
        fprintf(['\nSubject ' num2str(subjects(subjectIndex)) ' is risk-seeking\n'])
    end
end

y1 = risk_choice;
y2 = sanAccuracy;
[AX,H1,H2] = plotyy(1, y1, 1.5, y2, 'bar', 'bar');
set(H1,'BarWidth',0.5);
set(H2,'BarWidth',0.25);
ax = gca;  %% get handle to current axes
axis([0,3,0,1])
ax.XTick = [1,2];
ax.XTickLabel = {'risk sensitivity','sanity accuracy'};
ax.YTick =  [0,0.5,1];
refline(0,0.5);
title('risk sensitivity and sanity accuracy');

set(get(AX(1),'Ylabel'),'String','proportion of risk option chosen') 
set(get(AX(2),'Ylabel'),'String','sanity accuracy') 

%% 
% correlation 1
a=[joinStruct3{:,1},joinStruct3{:,6}];
corrRiskChoice=corrcoef(a,'rows','complete');
corr1=corrRiskChoice(1,2);

graph1=scatter(a(:,1),a(:,2));
title('reaction time vs. risk')
xlabel('risk') % x-axis label
ylabel('reaction time (s)') % y-axis label
axis([5,30,0,2])

% correlation 2
b=[joinStruct3{:,2},joinStruct3{:,6}];
corrRT_effort=corrcoef(b,'rows','complete');
corr2=corrRT_effort(1,2);

graph2=scatter(b(:,1),b(:,2));
title('reaction time vs. effort level');
xlabel('effort level'); % x-axis label
ylabel('reaction time (s)'); % y-axis label
axis([30,70,0,2]);

%%
% effort risk vs. risk sensitivity = -0.07
a2t=array2table(chose_risk);
c=[joinStruct3{:,1},a2t{:,1}];
corrRiskChoice=corrcoef(c);
corr3=corrRiskChoice(1,2);

[A B C]=mnrfit(c(:,2),c(:,1));

title('risk level vs. risk sensitivity');
xlabel('risk'); % x-axis label
ylabel('chose risk'); % y-axis label
axis([0,30,0,1.5]);
ax=gca;
ax.XTick = [0:3:30];
ax.YTick =  [0,0.5,1,1.5];