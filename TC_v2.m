%% PARAMETERS
addpath('C:\MAGIC-master');
DIR = 'C:\Users\neuro\Desktop\SIPA_tests';
if exist(DIR,"dir")
    fprintf("directory exists");
else 
    mkdir(DIR)
end 
MAGPRO_WAIT = 0.5;
PULSES_PER_DELAY = 4;
BREAK_TIME = 10;          
FIXED_RMT_PERCENT = 1.2;
TOTAL_BLOCKS = 2;          % total blocks per session
%% PARTICIPANT ID & RMT
PARTICIPANT_ID = input('Enter participant ID: ','s');
RMT = input('Enter RMT (1-100): ');
while ~(isnumeric(RMT) && RMT >=0 && RMT <= 100)
    fprintf('Invalid value. Please enter a number between 0 and 100.\n');
    RMT = input('Enter RMT (0–100): ');
end
fixed_mso = round(RMT*FIXED_RMT_PERCENT);
if fixed_mso > 100
    error('Stimulation intensity exceeds machine limit (>100)');
else 
    display(fixed_mso)
end

%% CONNECT TO MAGVENTURE
port_id = upper(input('Enter Port ID (e.g. COM3): ', 's'));
magventureObject = magventure(port_id);
magventureObject.connect();
magventureObject.arm();
magventureObject.setAmplitude(fixed_mso);
%% LOAD OR INITIALIZE EXPERIMENT DATA
filename = fullfile(DIR, strcat(PARTICIPANT_ID, '_session.mat'));

if isfile(filename)
    load(filename, 'exp_output');
    total_pulse = length(exp_output);
    last_block = max([exp_output.block]);
    next_block = last_block + 1;   
    disp(['Loaded existing session. Starting from block ', num2str(next_block)]);
else
    exp_output = struct();
    total_pulse = 0;
    next_block = 1;
    disp('No previous session found. Starting from block 1.');
end

%% PULSE PARAMETERS
pulse_count = total_pulse;
% trigOutDelay = [0 10 20 30 40 50 60 70 80 90 100];
% trigOutDelay = [40 50 60 70 80 90 100];
trigOutDelay = [40 50 60];
trigInDelay = 0;
chargeDelay = 0;
pause_time = 4;  % seconds between paired pulses

%% BLOCK LOOP
for log_block = next_block : TOTAL_BLOCKS
    display_block = log_block - next_block + 1;
    fprintf('Press any key to start Block %d\n', display_block);
    waitforbuttonpress;
    % Randomise delays for this block
%     randomDelays = trigOutDelay(randperm(length(trigOutDelay)));
    for i = 1:length(randomDelays)
        delay = randomDelays(i);
        fprintf('Firing %d pulses with trigOutDelay = %d ms\n', PULSES_PER_DELAY, delay);
        magventureObject.setTrig_ChargeDelay(trigInDelay, delay, chargeDelay);
        for p = 1:PULSES_PER_DELAY
            pulse_count = pulse_count + 1;
            magventureObject.fire();
            pause(pause_time);
            pulse_exact_time = datetime('now', 'Format', 'HH:mm:ss.SSS');
            fprintf(' Block %d - Delivered Pulse %d\n', display_block, pulse_count);
%             if p == 1
%                 pulse_label = 0;   % burner pulse
%             else
%                 pulse_label = pulse_count;
%             end
            % log pulses
            exp_output(pulse_count).pid     = PARTICIPANT_ID;
            exp_output(pulse_count).block   = log_block;
            exp_output(pulse_count).pulse   = pulse_label;
            exp_output(pulse_count).mso_lvl = fixed_mso;
            exp_output(pulse_count).timing  = pulse_exact_time;
            exp_output(pulse_count).dur     = pause_time ;
        end

        % Break after all pulses for this delay
        pause(BREAK_TIME);
    end

    % break between blocks
    if log_block < TOTAL_BLOCKS
        disp('Taking a break... Press any key to start next block');
        waitforbuttonpress;
    end

    % Save after each block
    save(filename, 'exp_output');
    disp(['Block ', num2str(display_block), ' saved.']);
end

%% DISCONNECT
magventureObject.disarm();
magventureObject.disconnect();
disp('Experiment complete.');
