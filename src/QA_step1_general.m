% EEGLAB merge sets, and creates .set file
% by Douwe Horsthuis updated on 8/10/2022
% Specifically for F.A.S.T.
% if crash says : Error in A_merge_sets (line 38)
%            EEG = pop_biosig([data_path  subject_list{s} '_' filename '_' num2str(bdf_bl) '.bdf']);
% Double check the name you gave, that is where the mistake is
% ------------------------------------------------
clear variables
%% Update this for your computer and the participant you are running
subject_list = {'10862'};% '10260' '10314' '10508' '10520' '10708' '10769' '10846' '10876' '11244' '11576'}; %all the IDs for the indivual particpants
load_path    = 'C:\Users\dohorsth\Desktop\SFARI Behav\ASSR\'; %will open individual folders based on subject ID
save_path    = 'C:\Users\dohorsth\Desktop\SFARI Behav\FAST\test\'; %where will you save the data (something like 'C:\data\')
binlist_location='C:\Users\dohorsth\Desktop\SFARI Behav\FAST\script\';
logo_location= 'C:\Users\dohorsth\Documents\GitHub\EEG-quality-analysis\images\';%if you want to add a logo you can add it here if not leave it empty
logo_filename='CNL_logo.jpeg'; %filename + extention (eg.'CNL_logo.jpeg')
binlist_name='binlist_ASSR.txt'; %name of the text file with your bins
rt_binlist = 'binlist_ASSR_resp.txt'; %name of the reaction time binlist
rt_plot_n=1:4; %which RT bins do you want to plot together (can only plot one group)
plotting_bins=1:4; %the bins that should become ERPs
channels_names={'Cz' }; %channels that you want plots for (
colors={'k-' , 'r-' , 'b-' ,'g-' }; %define colors of your ERPs (1 per bin), add - for solid line add -- for dashed line -. for dotted/dashed : for dotted
downsample_to=256; % what is the sample rate you want to downsample to
lowpass_filter_hz=50; %50hz filter
highpass_filter_hz=1; %1hz filter
epoch_time = [-100 500];
baseline_time = [-50 0];
n_bins=4;% enter here the number of bins in your binlist
%% Questions you need to answer in the command window before starting
prompt = "What is the paradigm specific name for the bdf files (e.g. fast when the whole file is 10000_fast_1.bdf)?";
p_name= input(prompt,"s");
prompt = "How many bdf files should be used?";
n_bdf= input(prompt);
prompt = "Which channels are bad according to the readme file? write like this: {'fp1' 'o2' 'p1'}, hit enter if none";
bad_channels= input(prompt);
prompt = "Is there a readme file? (yes/no)";
readme_yn= input(prompt,"s");
prompt = "Is there Eye tracking? (yes/no)";
ET_yn= input(prompt,"s");

if strcmpi(ET_yn,'yes')
prompt = "What is the eye tracking specific name for the EDF files (e.g. FAST when the whole file is 10000_FAST_1.edf)?";
et_name= input(prompt,"s");
end
%% start
for s = 1:length(subject_list)
    fprintf('\n******\nProcessing subject %s\n******\n\n', subject_list{s});
    %% creating the right file names
    if n_bdf==1
        filename     = [p_name '_1']; % if your bdf file has a name besides the ID of the participant (e.g. oddball_paradigm)
        blocks       = 1;
    elseif n_bdf==2
        filename     = p_name; % if your bdf file has a name besides the ID of the participant (e.g. oddball_paradigm)
        blocks       = 2;
    else
        prompt = "You have more than 2bdf files, are you sure you this is correct? (yes/no)";
        correct_yn= input(prompt,"s");
        if strcmp(correct_yn,'yes')
            filename     = p_name; % if your bdf file has a name besides the ID of the participant (e.g. oddball_paradigm)
            blocks       = n_bdf;
        else
            return
        end
    end
    %% clearing everything to be on the save side and restarting EEGLAB
    clear ALLEEG
    eeglab
    close all
    %% setting the right paths and printing it so you can see it
    data_path  = [load_path subject_list{s} '\'];
    save_path_indv  = [save_path subject_list{s} '\'];
    disp([data_path  subject_list{s} '_' filename '.bdf'])
    %% merging data
    if blocks == 1
        %if participants have only 1 block, load only this one file
        disp([data_path  subject_list{s} '_' filename '.bdf'])
        EEG = pop_biosig([data_path  subject_list{s} '_' filename '.bdf']);
    else
        for bdf_bl = 1:blocks
            %if participants have more than one block, load the blocks in a row
            %your files need to have the same name, except for a increasing number at the end (e.g. id#_file_1.bdf id#_file_2)
            EEG = pop_biosig([data_path  subject_list{s} '_' filename '_' num2str(bdf_bl) '.bdf']);
            [ALLEEG, ~] = eeg_store(ALLEEG, EEG, CURRENTSET);
        end
        %since there are more than 1 files, they need to be merged to one big .set file.
        EEG = pop_mergeset( ALLEEG, 1:blocks, 0);
    end
    %% Adding participant information
    %step 1, using either the logfile if it exist, or promting you for data
    [EEG]=logfile_to_pic(EEG,readme_yn,data_path,save_path_indv,subject_list{s});
    %step 2, adding some info from previously promted things
    EEG.subject = subject_list{s}; %subject ID
    EEG.org_n_bdf=n_bdf;
    EEG.filter=table(lowpass_filter_hz,highpass_filter_hz);
    %% making a folder where we are going to save our files
    mkdir(save_path_indv)
    %% downsampling filtering chan location
    EEG = pop_saveset( EEG, 'filename',[subject_list{s} '.set'],'filepath',save_path_indv);
    EEG = pop_resample( EEG, downsample_to);%downsample
    EEG = pop_eegfiltnew(EEG, 'locutoff',highpass_filter_hz);%highpass filter
    EEG = pop_eegfiltnew(EEG, 'hicutoff',lowpass_filter_hz);%lowpass filter
    eeglab_location = fileparts(which('eeglab')); %needed if using a 10-5-cap
    EEG = pop_select( EEG,'nochannel',{'EXG1','EXG2','EXG3','EXG4','EXG5','EXG6','EXG7','EXG8'});
    EEG=pop_chanedit(EEG, 'lookup',[eeglab_location '\plugins\dipfit\standard_BESA\standard-10-5-cap385.elp']); %make sure you put here the location of this file for your computer
    EEG.orgchan=EEG.chanlocs;
    EEG = pop_saveset( EEG, 'filename',[subject_list{s} '_info.set'],'filepath', save_path_indv);
    %% looking for bridged deleting channels
    bridge=eBridge(EEG); %bridged channels
    EEG = pop_select( EEG, 'nochannel',bad_channels);%bad channels
    old_samples=EEG.pnts;
    EEG = pop_clean_rawdata(EEG, 'FlatlineCriterion',5,'ChannelCriterion',0.85,'LineNoiseCriterion',4,'Highpass','off','BurstCriterion',35,'WindowCriterion','off','BurstRejection','on','Distance','Euclidian'); % deletes bad chns and bad periods
    EEG.deleteddata=100-EEG.pnts/old_samples*100;
    EEG = pop_saveset( EEG, 'filename',[subject_list{s} '_auto_exchn.set'],'filepath', save_path_indv);
    disp([num2str(EEG.deleteddata) '% of the data got deleted for this participant']);
    pop_eegplot( EEG, 1, 1, 1);
    print([save_path_indv subject_list{s} '_raw_data'], '-dpng' ,'-r300');
    %% manually deleting extra bad channels
    prompt = 'Delete channels? If yes, input them all as strings inside {}. If none hit enter ';
    bad_chan = input(prompt); %
    if isempty(bad_chan) ~=1
        EEG = pop_select( EEG, 'nochannel',bad_chan);
    end
    print([save_path_indv subject_list{s} '_raw_data'], '-dpng' ,'-r300');
    close all
    EEG = pop_saveset( EEG, 'filename',[subject_list{s} '_exchn.set'],'filepath', save_path_indv);
    %% creating figures with deleted and bridged channels
    labels_all = {EEG.orgchan.labels}.'; %stores all the labels in a new matrix
    labels_good = {EEG.chanlocs.labels}.'; %saves all the channels that are in the excom file
    del_chan=setdiff(labels_all,labels_good);
    EEG.del_chan=[];
    for chan=1:length(del_chan)
        for del=1:length(EEG.orgchan)
            if strcmp(del_chan{chan},EEG.orgchan(del).labels)
                EEG.del_chan = [EEG.del_chan;EEG.orgchan(del)];
            end
        end
    end
    if isempty(EEG.del_chan)
        figure('Renderer', 'painters', 'Position', [10 10 375 225])
        annotation('textbox', [0.1, 0.9, 0.1, 0.1], 'String', 'No Deleted channels')
    elseif length(EEG.del_chan)==1
        figure('Renderer', 'painters', 'Position', [10 10 375 225])
        annotation('textbox', [0.1, 0.9, 0.1, 0.1], 'String', ['Only ' EEG.del_chan.labels ' was deleted'])
    else
        figure; topoplot([],EEG.del_chan, 'style', 'fill',  'electrodes', 'labelpoint', 'chaninfo', EEG.chaninfo);
    end
    print([save_path_indv subject_list{s} '_deleted_channels'], '-dpng' ,'-r300');
    close all
    EEG.bridged=[];
    for chan=1:length(bridge)
        for del=1:length(EEG.orgchan)
            if strcmp(bridge.Bridged.Labels{1, chan}  ,EEG.orgchan(del).labels)
                EEG.bridged = [EEG.bridged;EEG.orgchan(del)];
            end
        end
    end
    if isempty(EEG.bridged)
        figure('Renderer', 'painters', 'Position', [10 10 375 225])
        annotation('textbox', [0.1, 0.9, 0.1, 0.1], 'String', 'No Briged channels')
    elseif length(EEG.bridged)==1
        figure('Renderer', 'painters', 'Position', [10 10 375 225])
        annotation('textbox', [0.1, 0.9, 0.1, 0.1], 'String', ['Only ' EEG.bridged.labels ' was deleted'])
    else
        figure; topoplot([],EEG.bridged, 'style', 'fill',  'electrodes', 'labelpoint', 'chaninfo', EEG.chaninfo);
    end
    print([save_path_indv subject_list{s} '_bridged_channels'], '-dpng' ,'-r300');
    close all
    %% PCA, Channel interpolation, avg ref, ICA, IClabel
    pca = EEG.nbchan-1; %the PCA part of the ICA needs stops the rank-deficiency
    EEG = pop_interp(EEG, EEG.orgchan, 'spherical');%interpolates the data
    EEG = pop_reref( EEG, []);%avg ref
    EEG = eeg_checkset( EEG );
    EEG = pop_runica(EEG, 'extended',1,'interupt','on','pca',pca); %using runica function, with the PCA part
    EEG = eeg_checkset( EEG );
    EEG = pop_saveset( EEG, 'filename',[subject_list{s} '_ica.set'],'filepath', save_path_indv);
    EEG = iclabel(EEG); %does ICLable function
    ICA_components = EEG.etc.ic_classification.ICLabel.classifications ; %creates a new matrix with ICA components
    ICA_components(:,8) = sum(ICA_components(:,[2 3 4 5 6]),2);
    bad_components = find(ICA_components(:,8)>0.80 & ICA_components(:,1)<0.10);
    eye_ic = length(find(ICA_components(:,3)>0.80 & ICA_components(:,1)<0.05));
    EEG.del_eye_ic=length(eye_ic); %will add the amount of eye components deleted for this participant
    EEG.del_total_ic=length(bad_components);%will add the total amount of ic deleted for this participant
    %% Plotting bad components
    if isempty(bad_components)~= 1 %script would stop if people lack bad components
        if ceil(sqrt(length(bad_components))) == 1
            pop_topoplot(EEG, 0, [bad_components bad_components] ,subject_list{s} ,0,'electrodes','on');
        else
            pop_topoplot(EEG, 0, [bad_components] ,subject_list{s},[ceil(sqrt(length(bad_components))) ceil(sqrt(length(bad_components)))] ,0,'electrodes','on');
        end
        title(subject_list{s});
        print([save_path_indv subject_list{s} '_Bad_ICs_topos'], '-dpng' ,'-r300');
        EEG = pop_subcomp( EEG, [bad_components], 0); %excluding the bad components
        close all
    else %instead of only plotting bad components it will plot all components
        figure('Renderer', 'painters', 'Position', [10 10 375 225])
        annotation('textbox', [0.1, 0.9, 0.1, 0.1], 'String', 'There are no eye-components found')
        print([save_path_indv subject '_Bad_ICs_topos'], '-dpng' ,'-r300');
    end
    close all
    EEG = pop_saveset( EEG, 'filename',[subject_list{s} '_excom.set'],'filepath', save_path_indv);
    %% epoching
    % there is something odd in the EEG.event structure where not all triggers are correct.
    for i =1:length(EEG.event)%something odd, where eeg.event is irregular
        if contains(EEG.event(i).type, 'boundary') %skipping the boundary events
            continue
        elseif ~isempty(EEG.event(i).edftype)
            EEG.event(i).type = char(['condition ' num2str(EEG.event(i).edftype)]); %making sure that the edf are fixed first
        else
            new=EEG.event(i).type;
            EEG.event(i).edftype=str2double(new); %fixing edftype
            EEG.event(i).type = char(['condition ' new]); %making sure that it's edf fixed first
        end
    end
    EEG  = pop_creabasiceventlist( EEG , 'AlphanumericCleaning', 'on', 'BoundaryNumeric', { -99 }, 'BoundaryString', { 'boundary' } );
    EEG = eeg_checkset( EEG );
    EEG = pop_saveset( EEG, 'filename',[subject_list{s} '_events.set'],'filepath', save_path_indv);
    EEG  = pop_binlister( EEG , 'BDF', [binlist_location binlist_name], 'IndexEL',  1, 'SendEL2', 'EEG', 'Voutput', 'EEG' );
    EEG = pop_epochbin( EEG , epoch_time,  baseline_time); %epoch size and baseline size
    %deleting bad epochs (need erplab plugin for this)
    EEG= pop_artmwppth( EEG , 'Channel', 1:EEG.nbchan, 'Flag',  1, 'Threshold',  150, 'Twindow', epoch_time, 'Windowsize',  200, 'Windowstep',  200 );% to flag bad epochs
    EEG.deleteddata= EEG.deleteddata+(length(nonzeros(EEG.reject.rejmanual))/(length(EEG.reject.rejmanual)))*100;
    EEG = pop_rejepoch( EEG, [EEG.reject.rejmanual] ,0);%this deletes the flaged epoches
    %creating ERPS and saving files
    ERP = pop_averager( EEG , 'Criterion', 1, 'DSindex',1, 'ExcludeBoundary', 'on', 'SEM', 'on' );
    EEG = pop_saveset( EEG, 'filename',[subject_list{s} '_epoched.set'],'filepath', save_path_indv);
    ERP = pop_savemyerp(ERP, 'erpname', [subject_list{s} '.erp'], 'filename', [subject_list{s} '.erp'], 'filepath', save_path_indv); %saving a.ERP file
    ERP = pop_loaderp( 'filename', [subject_list{s} '.erp'], 'filepath', save_path_indv );
    %channelnames to numbers
    channels=zeros(1,length(channels_names));
    for i = 1:length(channels_names)
        for ii=1:length(EEG.chanlocs)
            if strcmpi(channels_names(i), EEG.chanlocs(ii).labels)
                channels(i)=ii;
            end
        end
    end
    erp_square=[ceil(sqrt(length(channels_names))) floor(sqrt(length(channels_names)))]; %for the subplots
    ERP = pop_ploterps( ERP,  plotting_bins, channels , 'AutoYlim', 'on', 'Axsize', [ 0.05 0.08], 'BinNum', 'on', 'Blc', 'pre', 'Box',...
        erp_square, 'ChLabel', 'on', 'FontSizeChan',  10, 'FontSizeLeg',  12, 'FontSizeTicks',  10, 'LegPos', 'bottom', 'Linespec', colors,...
        'LineWidth',  1, 'Maximize', 'on', 'Position', [ 1 1 1 1 ], 'Style', 'Classic', 'Tag', 'ERP_figure',...
        'Transparency',  0, 'xscale', [epoch_time   epoch_time(1):100:epoch_time(2) ], 'YDir', 'normal' );
    print([save_path_indv subject_list{s} '_erps'], '-dpng' ,'-r300');
    close all
    %% doing the epoching for reaction times now
    EEG = pop_loadset('filename', [subject_list{s} '_events.set'], 'filepath', save_path_indv);
    EEG  = pop_binlister( EEG , 'BDF', [binlist_location rt_binlist], 'IndexEL',  1, 'SendEL2', 'EEG', 'Voutput', 'EEG' );
    EEG = pop_epochbin( EEG , epoch_time,  baseline_time); %epoch size and baseline size
    ERP = pop_averager( EEG , 'Criterion', 1, 'DSindex',1, 'ExcludeBoundary', 'on', 'SEM', 'on' );
    ERP = pop_savemyerp(ERP, 'erpname', [subject_list{s} '_rt.erp'], 'filename', [subject_list{s} '_rt.erp'], 'filepath', save_path_indv); %saving a.ERP file
    ERP = pop_loaderp( 'filename', [subject_list{s} '_rt.erp'], 'filepath', save_path_indv );
    values = pop_rt2text(ERP, 'eventlist',  1, 'filename', [save_path_indv 'rts.xls'], 'header', 'on',...
        'listformat', 'basic' );
    if isempty(bridge.Bridged.Labels{1, 1})
        bridge.Bridged.Labels='Nothing is bridged';
    else
        bridge.Bridged.Labels=strjoin(bridge.Bridged.Labels);
    end
    
    participant_information=[string(EEG.subject), EEG.age, EEG.sex, EEG.hearing, EEG.vision, EEG.org_n_bdf, EEG.filter.lowpass_filter_hz(1), EEG.filter.highpass_filter_hz(1),EEG.del_eye_ic,EEG.del_total_ic,strjoin({EEG.del_chan.labels}) ,EEG.deleteddata, bridge.Bridged.Count,bridge.Bridged.Labels, ERP.ntrials.accepted];
    %% Reaction times
    rt=readtable([save_path_indv 'rts.xls']); %reading table
    rt=table2array(rt)
    for i=1:size(rt,2) %finding the amount of clicks for each bin
        response_amount(i)=length(rt(~isnan(rt(:,i))));
    end
    for i=1:size(rt,2) %finding the avg rt
        response_avg(i)=mean(rt((~isnan(rt(:,i))),i));
    end
    %% deviding RTs into 3 groups across the time of the paradigm (beginning middel end)
    %first 1/3 of all corrects
    rt_start=[];rt_middle=[];rt_end=[];
    for i = rt_plot_n(1):rt_plot_n(end)
        rt_length_s= floor(length(rt((~isnan(rt(:,i))),i))/3);
        rt_length_m= 2*(floor(length(rt((~isnan(rt(:,i))),i))/3));
        rt_length_e= 3*(floor(length(rt((~isnan(rt(:,i))),i))/3));
        rt_start=[rt_start;rt(1:rt_length_s,i)];
        rt_middle=[rt_middle;rt(rt_length_s+1:rt_length_m,i)];
        rt_end=[rt_end;rt(rt_length_m+1:rt_length_e,i)];
    end
    
    % preparing the responses to be printable
    for i=1:length(response_amount)
        if strlength(string(response_amount(i)))==1
            response_amount_final{i}= "00" + string(response_amount(i));
        elseif strlength(string(response_amount(i)))==2
            response_amount_final{i}= "0" + string(response_amount(i));
        end
    end
    %% eye tracking
    if strcmpi(ET_yn,'yes')
    data_folder=dir(data_path);
    %     date_2=datetime('28-Jun-1900 11:24:05');
    %     for i=1:length(data_folder)
    %         if endsWith(data_folder(i).name,'_1.edf')
    %             edf1=Edf2Mat([data_path data_folder(i).name]);
    %         end
    %         if endsWith(data_folder(i).name,'.edf') && date_2<datetime(data_folder(i).date)
    %             date_2=datetime(data_folder(i).date);
    %             edf_2_name=data_folder(i).name;
    %         end
    %     end
    edf_n.x=[]; edf_n.y=[];edf_test=[];edf_x=[]
    for i=1:length(data_folder)
        if endsWith(data_folder(i).name,'.edf')
            edf_temp=Edf2Mat([data_path data_folder(i).name]);
            %edf_test=[edf_test;edf_temp.Samples.posX,edf_temp.Samples.posY];
            %edf_n.x=[edf_n.x;edf_temp.Samples.posX];
            %edf_n.y=[edf_n.y;edf_temp.Samples.posY];
            edf_x=[edf_x;edf_temp];
        end
    end
    
    %     t=table(edf_n.x,edf_n.y);
    %     figure();
    %     heatmap(t,'Var1','Var2');
    %     edf_temp_1=edfmex([data_path data_folder(i).name]);
    %     figure();
    %     print([save_path_indv subject_list{s} '_et_test'],'-dpng' ,'-r300') % then print it
    plotHeatmap(edf_temp);
    
    print([save_path_indv subject_list{s} '_eyetr'], '-dpng' ,'-r300');
    end
    close all;
    %creating the text for the reactions
for i=1:length(ERP.bindescr)
    rt_string{i}=strjoin({'RT - Average' , ERP.bindescr{i}, num2str(response_avg(i)), 'ms'});
    amount_string{i}=strjoin({'Amount' , ERP.bindescr{i}, convertStringsToChars(response_amount_final{i})});
end
    
end
%% creating a group file with all info
%this only needs to be ran for the 1st participant
gr_mat=dir(save_path);
for i=1:length(gr_mat)
    if strcmp(gr_mat(i).name,'group_info.mat') %if it already exist
        colNames = [{'ID', 'Age', 'Sex', 'Hearing test good', 'Vision test good', 'Original amount of BDFs', 'Lowpass filter', 'Highpass filter', 'N deleted Eye ICs', 'N deleted total ICs', 'Deleted Channels', '% data deleted', 'N bridged channels', 'briged channels'} ERP.bindescr]; %adding names for columns [ERP.bindescr] adds all the name of the bins
        group_info_2 = array2table( participant_information,'VariableNames',colNames);
        load([save_path 'Group_info'])
        group_info=[group_info;group_info_2];
        save([save_path 'group_info'],'group_info')
    else %if it doesn't exist, make it
        colNames = [{'ID', 'Age', 'Sex', 'Hearing test good', 'Vision test good', 'Original amount of BDFs', 'Lowpass filter', 'Highpass filter', 'N deleted Eye ICs', 'N deleted total ICs', 'Deleted Channels', '% data deleted', 'N bridged channels', 'briged channels'} ERP.bindescr]; %adding names for columns [ERP.bindescr] adds all the name of the bins
        group_info = array2table( participant_information,'VariableNames',colNames);
        save([save_path 'group_info'],'group_info')
    end
end
%% creating the PDF file with the summary 
fig=figure('units','normalized','outerposition',[0 0 1 1]);
set(gcf,'color',[0.85 0.85 0.85])
%logo
if ~isempty(logo_location)
subplot(5,5,3);
imshow([logo_location logo_filename]);
end
%ERPS
subplot(5,5,[4:5, 9:10]);
imshow([save_path_indv subject_list{s} '_erps.png']);
title('ERPs')
%information boxes
annotation('textbox', [0.1, 0.825, 0.1, 0.1], 'String', [EEG.date; EEG.age; EEG.sex; EEG.Hand; EEG.glasses;EEG.Medication; EEG.Exp;EEG.Externals;EEG.Light; EEG.Screen; EEG.Cap;])
annotation('textbox', [0.30, 0.825, 0.1, 0.1], 'String', [EEG.vision_info; EEG.vision; EEG.hearing_info; EEG.hz500; EEG.hz1000; EEG.hz2000; EEG.hz4000]);
annotation('textbox', [0.1, 0.6, 0.1, 0.1], 'String', [...
    "Lowpass filter: " + EEG.filter.lowpass_filter_hz(1) + "Hz";...
    "Highpass filter: " + EEG.filter.highpass_filter_hz(1) + "Hz";...
    "Data deleted: " + num2str(EEG.deleteddata) + "%";...
    "Amount bad chan: " + string(length(EEG.del_chan));...
    "Amount bridged chan: " + string(length(EEG.bridged))]);
annotation('textbox', [0.1, 0.1, 0.1, 0.1], 'String',rt_string)
annotation('textbox', [0.35, 0.1, 0.1, 0.1], 'String',amount_string);
annotation('textbox', [0.1, 0.15, 0.1, 0.1], 'String',[EEG.notes])
%Deleted channels (topoplot if amount is >1)
subplot(5,5,18);
imshow([save_path_indv subject_list{s} '_deleted_channels.png']);
title('Deleted channels')
%Bridged channels (topoplot if amount is >1)
subplot(5,5,7);
imshow([save_path_indv subject_list{s} '_bridged_channels.png']);
title('Bridged channels')
%Deleted IC components
subplot(5,5,8);
imshow([save_path_indv subject_list{s} '_Bad_ICs_topos.png']);
title('Deleted ICs')
%Raw data plot
subplot(5,5, [14:15 19:20]);
imshow([save_path_indv subject_list{s} '_raw_data.png']);
title('Overview raw data')
%RT plot
subplot(5,5,13)
boxplot([rt_start, rt_middle, rt_end], 'Labels',{'Start', 'Middle', 'End'})
title('Reaction time, at the start-middle-end')
xlabel('Moment trials happened in the paradigm')
ylabel('Reaction time (ms)')
%ET plot
if strcmpi(ET_yn,'yes')
    subplot(5,5,[11:12,16:17]);
    imshow([save_path_indv subject_list{s} '_eyetr.png'])
end
%Final adjustments for the PDF
sgtitle(['Quality of ' subject_list{s} 's data while doing ' p_name]);
set(gcf, 'PaperSize', [16 10]);
print(fig,[save_path_indv subject_list{s} '_data_quality'],'-dpdf') % then print it
close all