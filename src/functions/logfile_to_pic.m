function [EEG]= logfile_to_pic(EEG, readme_yn,data_path, save_path_indv, subject)
% logfile_to_pic reads a logfile if availible, and adds the data to the EEG
% file, if logfile not availibe questions will be prompted to get the same info
% Usage: [EEG] = logfile_to_pic(EEG, readme_yn,data_path, save_path_indv, subject);
% the structuture EEG will have the following added info:  
% EEG.notes=Notes from readme file;
% EEG.vision_info=" Left     Right Both (vision scores)";
% EEG.vision=Vision scores from readme file
% EEG.hearing_info=" Frequency Left Right"; 
% EEG.hz500=Results from readme file 
% EEG.hz1000=Results from readme file
% EEG.hz2000=Results from readme file
% EEG.hz4000=Results from readme file
% EEG.age=Results from readme file
% EEG.sex=Results from readme file
% EEG.date=Results from readme file
% EEG.Hand=Results from readme file
% EEG.hearing=Results from readme file
% EEG.vision=Results from readme file
% EEG.glasses=Results from readme file
% EEG.Medication=Results from readme file
% EEG.Exp=Results from readme file
% EEG.Externals=Results from readme file
% EEG.Light=Results from readme file
% EEG.Screen=Results from readme file
% EEG.Cap=Results from readme file
% *note: when "Results from readme file", logfile_to_pic will either find it in the readme file and use it
% or if it doesn't find it, it will promt for the answer.

data_folder=dir(data_path);
notes=[];date_1=[]; Age=[]; Sex=[]; Handedness=[]; glasses=[]; Medication=[]; Exp=[]; Externals=[]; Light=[]; Screen=[];Cap=[]; pres_version=[];
logfile_1=["this is a string to set it up","this is the second string to set it up","this is the 3rd string to set it up","this is the 4rd string to set it up", "this is the last string to set it up"];
if strcmpi(readme_yn,'yes')
    for log=1:length(data_folder)
        if endsWith( data_folder(log).name , 'README.txt' )
            %logfile_1 = importdata([data_path data_folder(log).name]);
            logfile_1 = fileread([data_path data_folder(log).name]);
        end
    end
    if size(logfile_1)==[1,1]
        sprintf('\n \n \n Readme file is loaded wrong, need manual input \n \n \n')
    else
        if contains(logfile_1,' Presentation V')
            pres_version=extractBetween(logfile_1, '~Run in ', '~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~');
        end
        %  for i=1:length(logfile_1)
        if contains(logfile_1,'Date')
            date_1 = extractBetween(logfile_1,'Date:', 'Gender');
            date_1 = strtrim(date_1); %deleting tabs, then deleting spaces
            date_1=strcat('Date: ',date_1);
        end
        if contains(logfile_1,'Age:')
            Age=extractBetween(logfile_1, 'Age:', 'Hand');
            Age = strtrim(Age);% deleting tabs, then deleting spaces
            Age=strcat('Age: ',Age);
        end
        if contains(logfile_1,'Gender:')
            Sex=extractBetween(logfile_1, 'Gender:', 'Age:');
            Sex = strtrim(Sex);% deleting tabs, then deleting spaces
            Sex = strcat('Sex: ',Sex);
        end
        if contains(logfile_1,'Sex:')
            Sex=extractBetween(logfile_1, 'Sex:', 'Age:');
            Sex = strtrim(Sex);% deleting tabs, then deleting spaces
            Sex = strcat('Sex: ',Sex);
        end
        if contains(logfile_1,'Glasses')
            glasses=extractBetween(logfile_1, 'contacts:', 'Medic');
            glasses = strtrim(glasses);% deleting tabs, then deleting spaces
            glasses=strcat('Glasses or contacts: ',glasses);
        end
        if contains(logfile_1,'Handedness:')
            Handedness=extractBetween(logfile_1, 'Handedness:', 'Tempe');
            Handedness = strtrim(Handedness);% deleting tabs, then deleting spaces
            Handedness=strcat('Handedness: ',Handedness);
        end
        if contains(logfile_1,'Medication:')
            Medication=extractBetween(logfile_1, 'Medication:', 'Height');
            Medication = strtrim(Medication);% deleting tabs, then deleting spaces
            Medication=strcat('Medication: ',Medication);
        end
        if contains(logfile_1,'Exp:')
            Exp=extractBetween(logfile_1, 'Exp:', 'booth');
            Exp = strtrim(Exp);% deleting tabs, then deleting spaces
            Exp=strcat('Experimenter: ',Exp);
        end
        if contains(logfile_1,'Externals:')
            Externals=extractBetween(logfile_1, 'Externals:', '(normal');
            Externals = strtrim(Externals);% deleting tabs, then deleting spaces
            Externals=strcat('Externals: ',Externals);
        end
        if contains(logfile_1,'Light:')
            Light=extractBetween(logfile_1, 'Light:', '(normal');
            Light = strtrim(Light);% deleting tabs, then deleting spaces
            Light=strcat('Light: ',Light);
        end
        if contains(logfile_1,'Screen:')
            Screen=extractBetween(logfile_1, 'Screen:', '(');
            Screen = strtrim(Screen);% deleting tabs, then deleting spaces
            Screen=strcat('Screen distance (cm): ',Screen);
        end
        if contains(logfile_1,'Cap:')
            Cap=extractBetween(logfile_1, 'Cap:', '(color + channels)');
            Cap = strtrim(Cap);% deleting tabs, then deleting spaces
            Cap=strcat('Cap size and #channels : ',Cap);
        end
        if contains(logfile_1,'notes:')
            notes = extractBetween(logfile_1,'notes:', 'Save as');
            notes = strtrim(notes); %deleting tabs, then deleting spaces
            notes=strcat('Notes: ',notes);
        end
        
    end
end

if isempty(pres_version)
    prompt = "What Version of Presentation was used?";
    pres_version= input(prompt,"s"); pres_version=strcat('Presentation Version:',cellstr(pres_version));
end
if isempty(date_1)
    prompt = "Date of data collection (mm/dd/yyyy): ";
    date_1= input(prompt,"s"); date_1=strcat('Date:',cellstr(date_1));
end
if isempty(Age)
    prompt = "Age of participant: ";
    Age= input(prompt,"s"); Age=strcat('Age: ',cellstr(Age));
end
if isempty(Sex)
    prompt = "Sex of participant: ";
    Sex= input(prompt,"s"); Sex=strcat('Gender: ', cellstr(Sex));
end
if isempty(Handedness)
    prompt = "Handedness: ";
    Handedness= input(prompt,"s"); Handedness=strcat('Handedness: ',cellstr(Handedness));
end
if isempty(glasses)
    prompt = "glasses or contacts: ";
    glasses= input(prompt,"s"); glasses=strcat('Glasses or contacts: ', cellstr(glasses));
end
if isempty(Medication)
    prompt = "Medication: ";
    Medication= input(prompt,"s"); Medication=strcat('Medication: ',cellstr(Medication));
end
if isempty(Exp)
    prompt = "Experimenter: ";
    Exp= input(prompt,"s"); Exp=strcat('Experimenter: ',cellstr(Exp));
end
if isempty(Externals)
    prompt = "Externals: ";
    Externals= input(prompt,"s"); Externals=strcat('Externals: ',cellstr(Externals));
end
if isempty(Light)
    prompt = "Light on/off: ";
    Light= input(prompt,"s"); Light=strcat('Light: ',cellstr(Light));
end
if isempty(Screen)
    prompt = "Screen distance (cm): ";
    Screen= input(prompt,"s"); Screen=strcat('Screen distance (cm): ',cellstr(Screen));
end
if isempty(Cap)
    prompt = "Cap size and # channels: ";
    Cap= input(prompt,"s"); Cap=strcat('Cap size and #channels : ',cellstr(Cap));
end
if isempty(notes) || strlength(notes)>500
    prompt = "Please copy past all the text from the Notes here, but make sure there are NO enters->";
    notes= input(prompt,"s"); notes=strcat('Notes: ',cellstr(notes));
end

%%
vision=[];hz500=' 500   Hz:  dB dB ';hz1000=' 1000 Hz:   dB  dB';hz2000=' 2000 Hz:   dB  dB';hz4000=' 4000 Hz:   dB  dB';

if contains(logfile_1,'Hearingtest')
    hz500=extractBetween(logfile_1, '500hz', '1000hz');
    hz500 = strtrim(hz500);% deleting tabs, then deleting spaces
    hz500=strcat('500Hz: ',hz500);
    hz1000=extractBetween(logfile_1, '1000hz', '2000hz');
    hz1000 = strtrim(hz1000);% deleting tabs, then deleting spaces
    hz1000=strcat('1000Hz: ',hz1000);
    hz2000=extractBetween(logfile_1, '2000hz', '4000hz');
    hz2000 = strtrim(hz2000);% deleting tabs, then deleting spaces
    hz2000=strcat('2000Hz: ',hz2000);
    hz4000=extractBetween(logfile_1, '4000hz', 'Vision');
    hz4000 = strtrim(hz4000);% deleting tabs, then deleting spaces
    hz4000=strcat('4000Hz: ',hz4000);
end
if contains(logfile_1,'Vision Test:')
    vision=extractBetween(logfile_1, 'vision test is not done on EEG day)', 'notes:');
    vision = strtrim(vision);% deleting tabs, then deleting spaces
    vision = regexprep(vision, '\t', ' '); vision = regexprep(vision, '  ', ' '); %cell  {' 20/12 20/32 20/14 '}
    vision=string(vision);
end

if isempty(vision) || contains(logfile_1,'20/  20/')
    prompt = "Vision score left eye: ";
    left_eye= input(prompt,"s");
    prompt = "Vision score right eye: ";
    right_eye= input(prompt,"s");
    prompt = "Vision score both eyes: ";
    both_eye= input(prompt,"s");
    vision=strcat(left_eye, " ",right_eye," ",both_eye);
else
    if strcmp(string(hz500), ' 500   Hz:  dB dB ')
        prompt = "500hz hearing test results (left ear/ Right ear): ";
        hz500= input(prompt,"s"); hz500=strcat(' 500   Hz   : ',cellstr(hz500));
    end
    if strcmp(string(hz1000), " 1000 Hz:   dB  dB")
        prompt = "1000hz hearing test results (left ear/ Right ear): ";
        hz1000= input(prompt,"s"); hz1000=strcat(' 1000 Hz   : ',cellstr(hz1000));
    end
    if  strcmp(string(hz2000), " 2000 Hz:   dB  dB")
        prompt = "2000hz hearing test results (left ear/ Right ear): ";
        hz2000= input(prompt,"s"); hz2000=strcat(' 2000 Hz   : ',cellstr(hz2000));
    end
    if strcmp(string(hz4000), " 4000 Hz:   dB  dB")
        prompt = "4000hz hearing test results (left ear/ Right ear): ";
        hz4000= input(prompt,"s"); hz4000=strcat(' 4000 Hz   : ',cellstr(hz4000));
    end
    
    % vision_info= " Left     Right Both (vision scores)";
    % hearing_info= " Frequency Left Right";
    
    
    %figure('Renderer', 'painters', 'Position', [10 10 375 225])
    %annotation('textbox', [0.1, 0.9, 0.1, 0.1], 'String', [vision_info; vision; hearing_info; hz500; hz1000; hz2000; hz4000]);
    %print([save_path_indv subject '_eye_ear'], '-dpng' ,'-r300');
    %close all
end
EEG.notes=notes;
EEG.vision_info=" Left     Right Both (vision scores)";hearing_info= " Frequency Left Right";
EEG.vision=vision; EEG.hearing_info=hearing_info; EEG.hz500=hz500; EEG.hz1000=hz1000; EEG.hz2000=hz2000; EEG.hz4000=hz4000;
EEG.age=Age; EEG.sex=Sex;  EEG.date=date_1; EEG.Hand=Handedness; EEG.hearing=hz1000; EEG.vision=vision;
EEG.glasses=glasses;EEG.Medication=Medication; EEG.Exp=Exp;EEG.Externals=Externals;EEG.Light=Light; EEG.Screen=Screen; EEG.Cap=Cap;
end