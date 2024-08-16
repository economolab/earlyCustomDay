function earlyCustomDay
% This protocol is a starting point for a tactile 2AFC task.
% Written by Nuo Li, 7/2016.
% Updated by Tim Wang 6/2018
% Updated by Juna Luis Ugarte Nunez, 7/2024
% SETUP
% You will need:
% - A Bpod MouseBox (or equivalent) configured with 3 ports.
% > Port#1: Left lickport connected to left valve, left lick detector, and
% trigger 1 for WAV trigger
% for 
% > Port#2: Right lickport connected to right valve, right lick detector, and
% trigger 2 for WAV trigger
% > Port#3: Trigger 3 for WAV trigger (cue)
% A Zaber motor is also connect to a pre-defined COM port so that the lickport can be moved automatically as part of the training program

	global BpodSystem S;
	
	%% Define parameters
	
    MaxTrials = 9999;
	RewardsForLastNTrials = 40; % THIS IS THE PERIOD OVER WHICH ADVANCEMENT PARAMETERS ARE DETERMINED
	
     %There is an 'autowater' mode where free rewards are given to encourage licking at the better. Smaller rewards are given in this mode, 
     %  but if a mouse licks correct, more water is dispensed.
    AutoWaterScale = 0.6; 

	S = BpodSystem.ProtocolSettings; %Load settings chosen in launch manager into current workspace as a struct called S

	if isempty(fieldnames(S))  % If settings file was an empty struct, populate struct with default settings
		S.GUI.WaterValveTime = 0.035;	  % in sec SET-UP SPECIFIC
		S.GUI.SamplePeriod = 0.65;		  % in sec
		S.GUI.DelayPeriod = 0.3;		  % in sec
		S.GUI.AnswerPeriod = 8;		  % in sec
		S.GUI.ConsumptionPeriod = 1.5;	  % in sec
		S.GUI.StopLickingPeriod = 1.5;	  % in sec
		S.GUI.TimeOut = 0.1;			  % in sec

		S.ProtocolHistory = [];	  % [protocol#, n_trials_on_this_protocol, performance]
	end
	
	% Initialize parameter GUI plugin
	%BpodParameterGUI('init', S);

% 	% sync the protocol selections
% 	p = cellfun(@(x) strcmp(x,'ProtocolType'),BpodSystem.GUIData.ParameterGUI.ParamNames);
% 	set(BpodSystem.GUIHandles.ParameterGUI.Params(p),'callback',{@manualChangeProtocol, S});
% 	p = cellfun(@(x) strcmp(x,'Autolearn'),BpodSystem.GUIData.ParameterGUI.ParamNames);
% 	set(BpodSystem.GUIHandles.ParameterGUI.Params(p),'callback',{@manualChangeAutolearn, S})
% 	if ~isempty(S.ProtocolHistory)% start each day on autolearn
% 		S.ProtocolHistory(end+1,:) = [S.GUI.ProtocolType 1 0];
% 		S.GUI.Autolearn = 1;
% 		mySet('Autolearn',S.GUI.Autolearn,'Value');	
%     end
	

	%% Initialize plots
	BpodSystem.ProtocolFigures.YesNoPerfOutcomePlotFig = figure('Position', [400 400 1400 200],'Name','Outcome plot','NumberTitle','off','MenuBar','none','Resize','off');
	BpodSystem.GUIHandles.YesNoPerfOutcomePlot = axes('Position', [.1 .3 .75 .6]);
	uicontrol('Style','text','String','nTrials','Position',[10 150 40 20]);
	BpodSystem.GUIHandles.DisplayNTrials = uicontrol('Style','edit','string','100','Position',[10 130 40 20]);
	myYesNoPerfOutcomePlot(BpodSystem.GUIHandles.YesNoPerfOutcomePlot,BpodSystem.GUIHandles.DisplayNTrials,'init',1);
	
	% Pause the protocol before starting
	BpodSystem.Status.Pause = 1;
	HandlePauseCondition;

	%% Main Trial Loop
	for currentTrial = 1:MaxTrials
		%S = BpodParameterGUI('sync', S); % Sync parameters with BpodParameterGUI plugin

		try
			S.GaveFreeReward;
		catch
			S.GaveFreeReward=[0 0 0];
		end
		
		%############ automated training ###################
		% get training parameters based on past performance
		% need to program in the parameter changes here
% 		autoChangeProtocol();
		%############ automated training ###################

		% select trials here
		%disp(['Starting trial ',num2str(currentTrial)]);
		%TrialTypes(currentTrial) = trialSelection();		%0's (right) or 1's (left)

        % Defining Output states for valves and Go Cue
		LeftWaterOutput = {'ValveState',2^0};
		RightWaterOutput = {'ValveState',2^1};
        CueOutput = {'BNCState',1};
		
		% Build simple State Matrix for day2 flexibility
		sma = NewStateMatrix(); % Assemble state matrix

        %State for lick initialization
        sma = AddState(sma, 'Name', 'WaitForLick', 'Timer', 600,...
            'StateChangeConditions', {'Tup', 'exit', 'Port1In', 'LickLeft1', 'Port2In', 'LickRight1'},...
            'OutputActions', CueOutput); 
        
        % Make more Lick States
        reqLickStates = 3;   %How many times until animal gets reward
        LstateLeft = {[], [], LeftWaterOutput};
        LstateRight = {[], [], RightWaterOutput};
        allowedWait = 5;   %In seconds
        consumptionPeriod = 1;
        for adS = 1: reqLickStates 
        
            if adS == reqLickStates
                sma = AddState(sma, 'Name', ['LickLeft' num2str(adS)], 'Timer', 0.044,...
                    'StateChangeConditions', {'Tup', 'RewardConsumption'},...
                    'OutputActions', LstateLeft{1,adS});
                sma = AddState(sma, 'Name', ['LickRight' num2str(adS)], 'Timer', 0.044,...
                    'StateChangeConditions', {'Tup', 'RewardConsumption'},...
                    'OutputActions', LstateRight{1,adS});
            
            else
                sma = AddState(sma, 'Name', ['LickLeft' num2str(adS)], 'Timer', allowedWait,...
                    'StateChangeConditions', {'Tup', 'Pause', 'Port1In', ['LickLeft' num2str(adS + 1)]},...
                    'OutputActions', LstateLeft{1,adS});
                sma = AddState(sma, 'Name', ['LickRight' num2str(adS)], 'Timer', allowedWait,...
                    'StateChangeConditions', {'Tup', 'Pause', 'Port2In', ['LickRight' num2str(adS + 1)]},...
                    'OutputActions', LstateRight{1,adS});

            end
        end
        
        sma = AddState(sma, 'Name', 'RewardConsumption', 'Timer', consumptionPeriod,...
            'StateChangeConditions', {'Tup', 'Pause'},...
            'OutputActions', []); % reward consumption
        
        sma = AddState(sma, 'Name', 'Pause', 'Timer', 0.6,...
            'StateChangeConditions', {'Tup', 'exit'},...
            'OutputActions', []);


        SendStateMatrix(sma);
		try
			RawEvents = RunStateMachine();		 % this step takes a long time and variable (seem to wait for GUI to update, which takes a long time)
			bad = 0;
		catch ME
			warning('RunStateMatrix error!!!'); % TW: The Bpod USB communication error fails here.
			bad = 1;
		end

		if bad == 0 && ~isempty(fieldnames(RawEvents)) % If trial data was returned
			BpodSystem.Data = AddTrialEvents(BpodSystem.Data,RawEvents); % Computes trial events from raw data

            try
                BP = GetBehavioralPerformance(BpodSystem.Data);
                myYesNoPerfOutcomePlot(BpodSystem.GUIHandles.YesNoPerfOutcomePlot, BpodSystem.GUIHandles.DisplayNTrials, 'update', BpodSystem.Data.nTrials+1, TrialTypes, BP.Outcomes, BP.Early, BP.Autolearn);
                %get % rewarded is past RewardsForLastNTrials trials (can probably be combined with outcomes above)
                Rewards = 0;
                for x = max([1 BpodSystem.Data.nTrials-(RewardsForLastNTrials-1)]):BpodSystem.Data.nTrials
                    if BpodSystem.Data.TrialSettings(x).GUI.ProtocolType==S.GUI.ProtocolType && isfield(BpodSystem.Data.RawEvents.Trial{x}.States,'Reward')
                        if isfield(BpodSystem.Data.RawEvents.Trial{x}.States,'LickLeft') || isfield(BpodSystem.Data.RawEvents.Trial{x}.States, 'LickRight')
                            %if ~isnan(BpodSystem.Data.RawEvents.Trial{x}.States.Reward(1))
                            if ~isnan(BpodSystem.Data.RawEvents.Trial{x}.States.LickLeft(1)) || ~isnan(BpodSystem.Data.RawEvents.Trial{x}.States.LickRight(1))
                                Rewards = Rewards + 1;
                            end
                        end
                    end
                end
                S.ProtocolHistory(end,3) = Rewards / RewardsForLastNTrials;
                recent = Rewards / min(RewardsForLastNTrials, max(1, BpodSystem.Data.nTrials));
            catch ME
                warning('Data save error!!!');
                bad = 1;
            end
			if bad==0
				SaveBpodSessionData(); % Saves the field BpodSystem.Data to the current data file
				BpodSystem.ProtocolSettings = S;
				SaveBpodProtocolSettings();
			end
        end

		HandlePauseCondition; % Checks to see if the protocol is paused. If so, waits until user resumes.
		if BpodSystem.Status.BeingUsed == 0
			return
		end
	end
    end
