% Author:   Matthew Makila
% Date:     07/01/22
% Title:    KTape_DataProcessing.m
% Desc:     File to process microSD data for various plotting schemes

% Based on option, we'll have different graphing scheme
myOption = menu();

% we want to find out how to open a specific file from a specific drive
FILE_PATH1 = 'D:\';

fileList = extractFiles(FILE_PATH1);

% display & begin to select extracted files
fprintf("Files on Disk: \n\n");
for i = 1 : length(fileList)
   disp(fileList{i}); 
end
prompt = "\nFile requests (enter 'stop' when finished) : ";
fileRequest = input(prompt, "s");
hold on;

% perform data processing on selected files
while (fileRequest ~= "stop")
    % add the path to open it directly from drive
    myFile = strcat(FILE_PATH1, fileRequest);
    % read in file, now it's stored for our use
    try
        headers = readtable(myFile,'readvariablenames',true,'preservevariablename',true, 'Range', '1:2');
        trueDate = headers.Properties.VariableNames{2};
        myTable = readtable(myFile);
    catch
        error("Attempting to load non-existent file...")
    end
    
    % PERFORM last formatting and plotting
    if (myOption == 4)
        newTable = rawReformatTable(myTable);
    else
        newTable = reformatTable(myTable, myOption);
    end
    newTable(1,:) = []; % store in temp val later if we need it
    newTable.Var1 = string(newTable.Var1);
    newTable.Var1 = datetime(newTable.Var1,'InputFormat','HH :mm :ss:SSS');
    newTable.Var1.Format = 'dd-MMM-yyyy HH:mm:ss:SSS';
    
    % Fix datetime to date of test, not today's date 
    
    trueDatetime = trueDate(1: length(trueDate) / 2);
    trueDatetime = str2double(split(trueDatetime, '/'));
    newTable.Var1.Year = trueDatetime(3);
    newTable.Var1.Month = trueDatetime(1);
    newTable.Var1.Day = trueDatetime(2);
    
    % FFT settings
    L = length(newTable.Var2);
    Fs = 90; % THIS IS OUR 89-90 SPS
    
    % pick plotting options.
    switch (myOption)
        case 1
            plot(newTable.Var1, newTable.Var2, 'DisplayName', fileRequest, 'LineWidth', 2);
            ylabel('Impedance (Ohms)'); % impedance in Ohms
            xlabel('Time');
        case 2
            plot(newTable.Var1, newTable.Var2, 'DisplayName', fileRequest, 'LineWidth', 2);
            ylabel('Normalized Impedance'); % every val / nominal val
            xlabel('Time');
        case 3
            % compute FFT of normalized table data
            if (mod(L,2) == 1) % if odd len, chop one data point (not signif overall)
               newTable(1,:) = [];
               L = L - 1;
            end
            hold on;
            % mean shift to 0
            newTable.Var2 = newTable.Var2 - mean(newTable.Var2(:));
            Y = fft(newTable.Var2);
            % Calc two-sided PSD, get the one-sided PSD
            P2 = abs(Y/L);
            P1 = P2(1:L/2+1);
            P1(2:end-1) = 2*P1(2:end-1);
            % def. frequency and plot single-sided PSD
            f = Fs*(0:(L/2))/L;
            plot(f,P1, 'DisplayName', fileRequest, 'LineWidth', 2); 
            %set(gca, 'XScale', 'log') % force it to be logarithmic
            title('Single-Sided Amplitude Spectrum of Norm. Impedance (t)');
            xlabel('f (Hz)');
            ylabel('|P1(f)|');
            hold off;
        case 4
            % compute raw ADC vs. timestamps
            plot(newTable.Var1, newTable.Var2, 'DisplayName', fileRequest, 'LineWidth', 2);
            ylabel('ADC Voltage');
            xlabel('Time');
        otherwise
            disp("No valid option selected!");
    end
    legend
    
    % Ask them for file save option
    saveData(newTable, fileRequest, trueDatetime);
    
    % reprompt for more files
    fileRequest = input(prompt, "s");
end
hold off;

% function to save specific file data
function saveData(T, fname, truedate)
    % the help: https://www.mathworks.com/help/matlab/ref/timerange.html
    % allows for user to specify intervals out of bounds but not cause 
    % errors or add extraneous data
    FILE_MARK = ".CSV";
    fname = erase(fname, FILE_MARK);
    qstn = "\Save table data? (y/n) : ";
    saveChoice = input(qstn, "s");
    if saveChoice == "y" || saveChoice == "yes"
        % allow user choice on what parts of table to save
        qstn2 = "\Enter start interval (HH :mm :ss): ";
        qstn3 = "\Enter ending interval (HH :mm :ss): ";
        interval = input("\Import whole table ('all') or press 'enter' for custom interval: ", "s");
        if interval ~= "all"
            cont = "y"; % run at least once
            while cont == "y" || cont == "yes"
                % extract the interval they want (can go as deep as ms)
                % convert int to datetime to pull out of timetable
                interval = datetime(input(qstn2, "s"), 'InputFormat', 'HH :mm :ss');
                interval2 = datetime(input(qstn3, "s"), 'InputFormat', 'HH :mm :ss');
                % make sure the intervals include the TRUE date
                interval.Day = truedate(2); interval.Month = truedate(1); interval.Year = truedate(3);
                interval2.Day = truedate(2); interval2.Month = truedate(1); interval2.Year = truedate(3);
                interval.Format = 'dd-MMM-yyyy HH:mm:ss:SSS';
                interval2.Format = 'dd-MMM-yyyy HH:mm:ss:SSS';

                S = timerange(interval, interval2);
                % convert to timetable basically same as initial table, so good
                TT = table2timetable(T);
                T2 = TT(S,:);
                fname = input("Input a filename: ", "s");
                writetimetable(T2, strcat(fname,'.xlsx'));
                cont = input("Continue? (y/n) ", "s");
            end
        else
            % extract entire table
            writetable(T, strcat(fname,'FA.xlsx'));
        end
    end
end

% File extraction
function myFiles = extractFiles(path)
    FILE_MARK = "CSV";
    % extract files from D: in a list ...
    rawList = dir(path);
    rawListArray = size(rawList);
    numFiles = rawListArray(1);

    % loop to extract files 
    myFiles = {};
    for i = 1:numFiles
        % take a file out ONLY if it's .csv
        fileName = rawList(i).name;
        TF = contains(fileName, FILE_MARK);
        if (TF)
            myFiles = [myFiles, fileName];
        end
    end
end

% menu options
% a funct. because we might need to loop through menus
function menuOption = menu()
    prompt = ['\n Menu Options:\n\n  1. Impedance Calculations\n  ', ...
        '2. Normalized Impedance Calculations\n  ', ...
        '3. FFT Calculations\n  ', '4. Raw ADC Plots\n  '];
    menuOption = input(prompt);
end

% find nominal value of table (raw val)
function nominalVal = findNominal(table)
    % for now, we'll base nom. val. on first 2 seconds of data
    nomRange = 150; % about 2 sec of data points ...
    total = 0;
    count = 0;
    for i = 2:nomRange
        total = total + table.Var2(i);
        count = count + 1;
    end
    nominalVal = total / count; % to be converted to impedance
end

% function to reformat data (edit table)
function newTable = reformatTable(laMesa, menuOp)
    scaler = 1/16000; % scale data to ADC volt range
    PotResist = str2double(laMesa.Var1{1}); % resist. of Potentiometer
    timeStamps = {}; % keys
    ratio = []; % blank space ratios list
    blanks = 0;
    % we want normalized data for options 2/3
    if (menuOp == 2 || menuOp == 3) % find nom val before crunching data
        nomVal = findNominal(laMesa);
        nomVal = calcZ(nomVal * scaler, PotResist); % put in impedance unit
    end
    
    for i = 2:length(laMesa.Var1) % start @ 2 to skip first row
        % perform scaling and z math
        laMesa.Var2(i) = laMesa.Var2(i) * scaler;
        laMesa.Var2(i) = calcZ(laMesa.Var2(i), PotResist);
        if (menuOp == 2 || menuOp == 3)    % op 2/3, nominal calculation
            laMesa.Var2(i) = laMesa.Var2(i) / nomVal;
        end
        if (laMesa.Var1{i}) % add to array of original time stamps
            timeStamps = [timeStamps, laMesa.Var1{i}];
            if blanks > 0 % we have blank spaces to fill ...
                % disp(blanks);
                newRatio = 1 / blanks; % typically 0.0114
                ratio = [ratio, newRatio];                
                blanks = 0; % reset, count next timestamp's blanks
            end    
        %else % it's a blank space    
        end
        blanks = blanks + 1;
    end
    % TAKE CARE OF LAST TIMESTAMP
    newRatio = 1 / blanks;
    ratio = [ratio, newRatio];
    
    % NEW LOOP, fill in table now using the map
    specialIDX = 0;
    multiplier = 1;
    for i = 2:length(laMesa.Var1) % start @ 2 to skip first row
        if (laMesa.Var1{i})
            % update vals to next timeStamp and ratio
            specialIDX = specialIDX + 1;
            currentTime = timeStamps{specialIDX};
            currentRatio = ratio(specialIDX);
            multiplier = 1;
        else
            endBit = currentRatio * multiplier;
            old = "000";
            endBit = string(endBit);
            endBit = eraseBetween(endBit, 1, 2);
            laMesa.Var1{i} = strrep(currentTime, old, endBit);
            multiplier = multiplier + 1;
        end
    end
    newTable = laMesa;
end

% function to reformat data (edit table)
function newTable = rawReformatTable(laMesa)
    timeStamps = {}; % keys
    ratio = []; % blank space ratios list
    blanks = 0;
    
    for i = 2:length(laMesa.Var1) % start @ 2 to skip first row
        if (laMesa.Var1{i}) % add to array of original time stamps
            timeStamps = [timeStamps, laMesa.Var1{i}];
            if blanks > 0 % we have blank spaces to fill ...
                % disp(blanks);
                newRatio = 1 / blanks; % typically 0.0114
                ratio = [ratio, newRatio];                
                blanks = 0; % reset, count next timestamp's blanks
            end    
        %else % it's a blank space    
        end
        blanks = blanks + 1;
    end
    % TAKE CARE OF LAST TIMESTAMP
    newRatio = 1 / blanks;
    ratio = [ratio, newRatio];
    
    % NEW LOOP, fill in table now using the map
    specialIDX = 0;
    multiplier = 1;
    for i = 2:length(laMesa.Var1) % start @ 2 to skip first row
        if (laMesa.Var1{i})
            % update vals to next timeStamp and ratio
            specialIDX = specialIDX + 1;
            currentTime = timeStamps{specialIDX};
            currentRatio = ratio(specialIDX);
            multiplier = 1;
        else
            endBit = currentRatio * multiplier;
            old = "000";
            endBit = string(endBit);
            endBit = eraseBetween(endBit, 1, 2);
            laMesa.Var1{i} = strrep(currentTime, old, endBit);
            multiplier = multiplier + 1;
        end
    end
    newTable = laMesa;
end

% Impedance calculator
function z = calcZ(deltaV, R_p)
    R_p = ((256 - R_p) / 256) * 10^6; % resist. in MegaOhms
    V_DD = 3; % Approx. 3V supplied voltage
    z = (R_p * (V_DD - 2 * deltaV)) / (V_DD + 2 * deltaV); %derived z eq.
end