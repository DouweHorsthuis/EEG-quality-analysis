% EEGLAB merge sets, and creates .set file
% by Douwe Horsthuis updated on 9/7/2022
% When running it for the first time for any new paradigm:
% if crash says : Error in A_merge_sets (line 38)
%            EEG = pop_biosig([data_path  subject_list{s} '_' filename '_' num2str(bdf_bl) '.bdf']);
% Double check the name you gave, that is where the mistake is
% ------------------------------------------------
clear variables
%% Update this for your computer and the participant you are running
subject_list = {'10400'};% '10260' '10314' '10508' '10520' '10708' '10769' '10846' '10876' '11244' '11576'}; %all the IDs for the indivual particpants
experiment_title='title';
load_path    = '\\data.einsteinmed.org\users\CNL Lab\Data_new\F.A.S.T. Response task\'; %will open individual folders based on subject ID
save_path    = '\\data.einsteinmed.org\users\CNL Lab\Analysis\SFARI\F.A.S.T. Response task\'; %where will you save the data (something like 'C:\data\')
binlist_location='\\data.einsteinmed.org\users\CNL Lab\Analysis\SFARI\F.A.S.T. Response task\';
binlist_name='binlist_fast.txt'; %name of the text file with your bins
rt_binlist = 'binlist_fast_rt.txt'; %name of the reaction time binlist
rt_plot_n=5:8; %which RT bins do you want to plot together (can only plot one group)
plotting_bins=1:4; %the bins that should become ERPs
channels_names={'Cz' 'Pz' 'Cpz' 'Po3' 'Poz' 'Po4' 'o1' 'oz' 'o2'}; %channels that you want erp plots for
time_fq_chn={'Cz' 'pz'}; %only add a channel if you want to do time frequency analysis
colors={'k-' , 'r-', 'g-' 'c-'}; %define colors of your ERPs (1 per bin), add - for solid line add -- for dashed line -. for dotted/dashed : for dotted
downsample_to=256; % what is the sample rate you want to downsample to
lowpass_filter_hz=50; %50hz filter
highpass_filter_hz=0.1; %1hz filter
epoch_time = [-100 500];
baseline_time = [-50 0];
low_fq= 3;
high_fq=40;
%% Questions you need to answer in the command window before starting
prompt = "What is the paradigm specific name for the bdf files (e.g. fast when the whole file is 10000_fast_1.bdf)?: ";
p_name= input(prompt,"s");
prompt = "How many bdf files should be used?: ";
n_bdf= input(prompt);
prompt = "Which channels are bad according to the readme file? write like this: {'fp1' 'o2' 'p1'}, hit enter if none: ";
bad_channels= input(prompt);
prompt = "Is there a readme file? (yes/no): ";
readme_yn= input(prompt,"s");
prompt = "Is there Eye tracking? (yes/no): ";
ET_yn= input(prompt,"s");
prompt = "Do you want a time frequency analysis? (yes/no): ";
tf= input(prompt,"s");
if strcmpi(tf,'yes')
    prompt = "Do you have 1 or 2 conditions? (1/2/more): ";
    tf_cond= input(prompt,"s");
    if ~strcmpi(tf_cond,'1') && ~strcmpi(tf_cond,'2')
        error('you can have a maximum of 2 conditions')
    end
    prompt = "Should the report skip the raw data, Eye tracking, or ERPS? (raw/erp/ET): ";
    raw_erps_et= input(prompt,"s");
    if length(time_fq_chn)>1
        error('You can only do time frequency analysis on 1 channel please choose only one')
    end
else
    raw_erps_et=[];
end
    %% finding location of the script
    file_loc=[fileparts(matlab.desktop.editor.getActiveFilename),filesep];
    addpath(genpath(file_loc));%adding path to your scripts so that the functions are found
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
        [EEG]=readme_to_EEG(EEG,readme_yn,data_path,save_path_indv,subject_list{s});
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
            figure('Renderer', 'painters', 'Position', [10 10 375 225]) %this is just an empty figure
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
            figure('Renderer', 'painters', 'Position', [10 10 375 225])%this is just an empty figure
        elseif length(EEG.bridged)==1
            figure('Renderer', 'painters', 'Position', [10 10 375 225])
            annotation('textbox', [0.1, 0.9, 0.1, 0.1], 'String', ['Only ' EEG.bridged.labels ' was deleted'])
        else
            figure; topoplot([],EEG.bridged, 'style', 'fill',  'electrodes', 'labelpoint', 'chaninfo', EEG.chaninfo);
        end
        if isempty(bridge.Bridged.Labels{1, 1})
            bridge.Bridged.Labels='Nothing is bridged';
        else
            bridge.Bridged.Labels=strjoin(bridge.Bridged.Labels);
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
        if ~isempty(time_fq_chn)
            time_fq_chn_n=zeros(1,length(time_fq_chn));
            for i = 1:length(time_fq_chn)
                for ii=1:length(EEG.chanlocs)
                    if strcmpi(time_fq_chn(i), EEG.chanlocs(ii).labels)
                        time_fq_chn_n(i)=ii;
                    end
                    
                end
            end
        end
        
        
        erp_square=[ceil(sqrt(length(channels_names))) ceil(sqrt(length(channels_names)))]; %for the subplots
        ERP = pop_ploterps( ERP,  plotting_bins, channels , 'AutoYlim', 'on', 'Axsize', [ 0.05 0.08], 'BinNum', 'on', 'Blc', 'pre', 'Box',...
            erp_square, 'ChLabel', 'on', 'FontSizeChan',  10, 'FontSizeLeg',  12, 'FontSizeTicks',  10, 'LegPos', 'bottom', 'Linespec', colors,...
            'LineWidth',  1, 'Maximize', 'on', 'Position', [ 1 1 1 1 ], 'Style', 'Classic', 'Tag', 'ERP_figure',...
            'Transparency',  0, 'xscale', [epoch_time   epoch_time(1):(epoch_time(2)/10):epoch_time(2) ], 'YDir', 'normal' );
        print([save_path_indv subject_list{s} '_erps'], '-dpng' ,'-r300');
        close all
        %% time frequency
        if strcmpi(tf,'yes')
            if strcmpi(tf_cond,'1')
                for i=1:length(EEG.event)
                    if  startsWith(EEG.event(i).binlabel,'B1')
                        bin1=EEG.event(i).binlabel;
                    end
                end
                EEG_1 = pop_selectevent( EEG, 'type',{bin1},'deleteevents','off','deleteepochs','on','invertepochs','off');
                figure();[ersp,powbaseCommon,times,freqs,erspboot,itcboot, tfdata] =  newtimef(EEG_1.data(time_fq_chn_n,:,:),...
                    EEG.pnts,...%frames (uses the total amount of sample points in the data
                    [EEG.xmin EEG.xmax]*1000,... %using the epoch times of the data *1000 to go from s to ms
                    EEG.srate,... %finds the sampling rate in the data
                    [3 7],... % 3 7 seems like a good suggestion, the wavelets should give a good balance between amount of cycles + is suggested by mike x cohen book
                    'freqs', [low_fq high_fq],... %we care for alpha 8-12hz so this should be enough
                    'alpha', 0.05,...%If non-0, compute two-tailed permutation significance probability level. Show non-signif. output values as green.                            {default: 0}
                    'commonbase', 'on',... %this is default, not sure how/why to set the baseline
                    'mcorrect', 'fdr',... %correcting for multiple comparisons not possible when comparing datasets
                    'plotitc' , 'off');%
            elseif strcmpi(tf_cond,'2')
                for i=1:length(EEG.event)
                    if  startsWith(EEG.event(i).binlabel,'B1')
                        bin1=EEG.event(i).binlabel;
                    elseif startsWith(EEG.event(i).binlabel,'B2')
                        bin2=EEG.event(i).binlabel;
                    end
                end
                ersp_title=[ERP.bindescr,strjoin([ERP.bindescr(1) , 'minus', ERP.bindescr(2)])];
                EEG_1 = pop_selectevent( EEG, 'type',{bin1},'deleteevents','off','deleteepochs','on','invertepochs','off');
                EEG_2 = pop_selectevent( EEG, 'type',{bin2},'deleteevents','off','deleteepochs','on','invertepochs','off');
                [ersp,powbaseCommon,times,freqs,erspboot,itcboot, tfdata] =  newtimef({EEG_1.data(time_fq_chn_n,:,:), EEG_2.data(time_fq_chn_n,:,:)},...
                    EEG.pnts,...%frames (uses the total amount of sample points in the data
                    [EEG.xmin EEG.xmax]*1000,... %using the epoch times of the data *1000 to go from s to ms
                    EEG.srate,... %finds the sampling rate in the data
                    [3 7],... % 3 7 seems like a good suggestion, the wavelets should give a good balance between amount of cycles + is suggested by mike x cohen book
                    'freqs', [low_fq high_fq],... %we care for alpha 8-12hz so this should be enough
                    'alpha', 0.05,...%If non-0, compute two-tailed permutation significance probability level. Show non-signif. output values as green.                            {default: 0}
                    'commonbase', 'on',... %this is default, not sure how/why to set the baseline
                    'plotitc' , 'off',...
                    'title', ersp_title);%
                set(gcf,'units','normalized','outerposition',[0 0 0.5 0.4])
            end
            
            save([save_path_indv subject_list{s} '_timef.mat'], 'ersp','powbaseCommon','times','freqs','erspboot','itcboot', 'tfdata')
            print([save_path_indv subject_list{s} '_timef'], '-dpng' ,'-r300');
            close all
        end
        %% Behavioral
        EEG = pop_loadset('filename', [subject_list{s} '_events.set'], 'filepath', save_path_indv);
        EEG  = pop_binlister( EEG , 'BDF', [binlist_location rt_binlist], 'IndexEL',  1, 'SendEL2', 'EEG', 'Voutput', 'EEG' );
        EEG = pop_epochbin( EEG , epoch_time,  baseline_time); %epoch size and baseline size
        ERP = pop_averager( EEG , 'Criterion', 1, 'DSindex',1, 'ExcludeBoundary', 'on', 'SEM', 'on' );
        ERP = pop_savemyerp(ERP, 'erpname', [subject_list{s} '_rt.erp'], 'filename', [subject_list{s} '_rt.erp'], 'filepath', save_path_indv); %saving a.ERP file
        ERP = pop_loaderp( 'filename', [subject_list{s} '_rt.erp'], 'filepath', save_path_indv );
        values = pop_rt2text(ERP, 'eventlist',  1, 'filename', [save_path_indv 'rts.xls'], 'header', 'on',...
            'listformat', 'basic' );
        
        
        participant_information=[string(EEG.subject), EEG.age, EEG.sex, EEG.hearing, EEG.vision, EEG.org_n_bdf, EEG.filter.lowpass_filter_hz(1), EEG.filter.highpass_filter_hz(1),EEG.del_eye_ic,EEG.del_total_ic,strjoin({EEG.del_chan.labels}) ,EEG.deleteddata, bridge.Bridged.Count,bridge.Bridged.Labels, ERP.ntrials.accepted];
        
        %% Reaction times
        rt=readtable([save_path_indv 'rts.xls']); %reading table
        bin_name= rt.Properties.VariableNames;
        for i = 1:length(bin_name) %turning underscores into spaces
            bin_name(i) = strrep(bin_name(i),'_',' ');
        end
        rt=table2array(rt);
        for i=1:size(rt,2) %finding the amount of clicks for each bin & %finding the avg rt
            response_amount(i)=length(rt(~isnan(rt(:,i))));
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
        %creating the text for the reactions
        for i=1:length(bin_name)
            rt_string{i}=strjoin({'RT - Average' , bin_name{i}, num2str(round(response_avg(i))), 'ms'});
            amount_string{i}=strjoin({'Amount' , bin_name{i}, convertStringsToChars(response_amount_final{i})});
        end
        %% eye tracking
        if strcmpi(ET_yn,'yes')
            edf_to_figure(data_path);
            print([save_path_indv subject_list{s} '_eyetr'], '-dpng' ,'-r300');
        end
        close all;
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
        %Deleted channels (topoplot if amount is >1)
        subplot(5,5,3);
        imshow([save_path_indv subject_list{s} '_deleted_channels.png']);
        title('Deleted channels')
        %ERPS
        subplot(5,5,[4:5, 9:10]);
        if strcmpi(raw_erps_et,'erp')
            imshow([save_path_indv subject_list{s} '_timef.png']);
        else
            imshow([save_path_indv subject_list{s} '_erps.png']);
            title('ERPs')
        end
        %information boxes
        annotation('textbox', [0.1, 0.825, 0.1, 0.1], 'String', [EEG.date; EEG.age; EEG.sex; EEG.Hand; EEG.glasses; EEG.Exp;EEG.Externals;EEG.Light; EEG.Screen; EEG.Cap;])
        annotation('textbox', [0.30, 0.825, 0.1, 0.1], 'String', [EEG.vision_info; EEG.vision; EEG.hearing_info; EEG.hz500; EEG.hz1000; EEG.hz2000; EEG.hz4000]);
        annotation('textbox', [0.25, 0.6, 0.1, 0.1], 'String',  EEG.Medication);
        annotation('textbox', [0.1, 0.6, 0.1, 0.1], 'String', [...
            "Lowpass filter: " + EEG.filter.lowpass_filter_hz(1) + "Hz";...
            "Highpass filter: " + EEG.filter.highpass_filter_hz(1) + "Hz";...
            "Data deleted: " + num2str(EEG.deleteddata) + "%";...
            "Amount bad chan: " + string(length(EEG.del_chan));...
            "Amount bridged chan: " + string(length(EEG.bridged))]);
        annotation('textbox', [0.1, 0.1, 0.1, 0.1], 'String',rt_string)
        annotation('textbox', [0.35, 0.1, 0.1, 0.1], 'String',amount_string);
        annotation('textbox', [0.55, 0.1, 0.1, 0.1], 'String',EEG.notes)
        %Bridged channels (topoplot if amount is >1)
        subplot(5,5,8);
        if ~isempty(EEG.bridged)
            imshow([save_path_indv subject_list{s} '_bridged_channels.png']);
            title('Bridged channels')
        else
            title('There are NO bridged channels')
        end
        %Raw data plot
        subplot(5,5, [14:15 19:20]);
        
        if strcmpi(raw_erps_et,'raw')
            imshow([save_path_indv subject_list{s} '_timef.png']);
        else
            imshow([save_path_indv subject_list{s} '_raw_data.png']);
            title('Overview raw data')
        end
        %RT plot
        subplot(5,5,13)
        boxplot([rt_start, rt_middle, rt_end], 'Labels',{'Start', 'Middle', 'End'})
        title('Reaction time, at the start-middle-end')
        xlabel('Moment trials happened in the paradigm')
        ylabel('Reaction time (ms)')
        %ET plot
        subplot(5,5,[11:12,16:17]);
        if strcmpi(raw_erps_et,'ET')
            imshow([save_path_indv subject_list{s} '_timef.png']);
        else
            if strcmpi(ET_yn,'yes')
                
                imshow([save_path_indv subject_list{s} '_eyetr.png'])
                %Deleted IC components
                subplot(5,5,18);
                imshow([save_path_indv subject_list{s} '_Bad_ICs_topos.png']);
                title('Deleted ICs')
            else
                %Deleted IC components
                imshow([save_path_indv subject_list{s} '_Bad_ICs_topos.png']);
                title('Deleted ICs')
            end
        end
        %Final adjustments for the PDF
        sgtitle(['Quality of ' subject_list{s} 's data while doing ' p_name]);
        set(gcf, 'PaperSize', [16 10]);
        print(fig,[save_path_indv subject_list{s} '_data_quality'],'-dpdf') % then print it
        close all
    end