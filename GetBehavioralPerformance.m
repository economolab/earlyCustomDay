function output = GetBehavioralPerformance(Data)
if ~isempty(Data.TrialTypes)
    % initialize output variables
		output.Outcomes = zeros(1,Data.nTrials);
		output.PrevProtocolTypes = zeros(1,Data.nTrials);
		output.Early = zeros(1,Data.nTrials);
		output.Autolearn = zeros(1,Data.nTrials);
		output.PrevTrialTypes = zeros(1,Data.nTrials);
		output.Delay = zeros(1,Data.nTrials);
		output.TimeOut = zeros(1,Data.nTrials);
		output.Water = zeros(1,Data.nTrials);
		output.RCT = zeros(1,Data.nTrials);
		for x = 1:Data.nTrials
			if isfield(Data.TrialSettings(x),'GUI') && ~isempty(Data.TrialSettings(x).GUI) && isfield(Data.RawEvents.Trial{x}.States,'Reward') && Data.TrialSettings(x).GUI.ProtocolType>=2
				if ~isnan(Data.RawEvents.Trial{x}.States.Reward(1))
					output.Outcomes(x) = 1;    % correct
				elseif ~isnan(Data.RawEvents.Trial{x}.States.TimeOut(1))
					output.Outcomes(x) = 0;    % error
				elseif ~isnan(Data.RawEvents.Trial{x}.States.NoResponse(1))
					output.Outcomes(x) = 2;    % no response
				else
					output.Outcomes(x) = 3;    % others
				end
				if isfield(Data.RawEvents.Trial{x}.States,'EarlyLickDelay')
					if (isfield(Data.RawEvents.Trial{x}.States,'EarlyLickSample') && ~isnan(Data.RawEvents.Trial{x}.States.EarlyLickSample(1))) || ~isnan(Data.RawEvents.Trial{x}.States.EarlyLickDelay(1))
						output.Early(x) = 1;
					else
						output.Early(x) = 0;
					end
				else
					output.Early(x) = 3;
				end
			else
				output.Outcomes(x) = 3; % others
				output.Early(x) = 3;
			end
			if isfield(Data.TrialSettings(x),'GUI') && ~isempty(Data.TrialSettings(x).GUI) % if Bpod skipped
				output.PrevProtocolTypes(x) = Data.TrialSettings(x).GUI.ProtocolType;
				output.PrevTrialTypes(x) = Data.TrialTypes(x);
				output.Delay(x) = Data.TrialSettings(x).GUI.DelayPeriod;
				output.TimeOut(x) = Data.TrialSettings(x).GUI.TimeOut;
				output.Autolearn(x) = Data.TrialSettings(x).GUI.Autolearn;
                output.Water(x) = Data.TrialSettings(x).GUI.WaterValveTime;
                output.RCT(x) = Data.TrialSettings(x).GUI.ConsumptionPeriod;                
			else
				output.PrevProtocolTypes(x) = PrevProtocolTypes(x-1);
				output.PrevTrialTypes(x) = PrevTrialTypes(x-1);
				output.Autolearn(x) = Autolearn(x-1);
				output.Delay(x) = Delay(x-1);
				output.TimeOut(x) = TimeOut(x-1);
				output.Water(x) = Water(x-1);
				output.RCT(x) = RCT(x-1);
				warning('missing GUI');
				disp(x);
			end
		end
	else
		output.Outcomes = [];
		output.Early = [];
		output.PrevProtocolTypes = [];
		output.PrevTrialTypes = [];
		output.Autolearn = [];
        output.Delay = [];
        output.Water = [];
        output.RCT = [];
	end
end
