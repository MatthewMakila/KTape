% Author:   Matthew Makila
% Date:     07/01/22
% Title:    SundayData.m
% Desc:     File to process microSD data for various plotting schemes

% May be a problem in future: 
% https://www.mathworks.com/matlabcentral/answers/801186-how-to-zoom-on-a-figure-with-multiple-axes
% hard to link axes though since datetime vals vs. numeric ones ...

% loaded files from specific drives
FILE_PATH1 = 'C:\Users\matth\Downloads\UCSD\ARMOR\Armor Sunday Test Data\DAQ Data\';
FILE_PATH2 = 'C:\Users\matth\Downloads\UCSD\ARMOR\Armor Sunday Test Data\csv-export.csv';

fileList = extractFiles();
disp("Our data loaded!");
cTable = readtable(FILE_PATH2);
disp("Commerical data loaded!");

% display & begin to select extracted files
fprintf("Files on Disk: \n\n");
for i = 1 : length(fileList)
   disp(fileList{i}); 
end

% prompt for files

prompt = "\nFile request: ";
fileRequest = input(prompt, "s");

% perform data processing on selected files
% add the path to open it directly from drive
myFile = strcat(FILE_PATH1, fileRequest);
% read in file, now it's stored for our use
try
    myTable = readtable(myFile);
catch
    error("Attempting to load non-existent file...")
end

% PERFORM last formatting and plotting
newTable = reformatTable(myTable);
newTable(1,:) = []; % store in temp val later if we need it
newTable.Var1 = string(newTable.Var1);
newTable.Var1 = datetime(newTable.Var1,'InputFormat','HH :mm :ss:SSS');
L = length(newTable.Var2);
Fs = 90; % THIS IS OUR 89-90 SPS

% Grab the diff data for axes.
CDATAName = "CDATA-12";
x1 = newTable.Var1;
y1 = newTable.Var2;
x2 = cTable.DataSet12_Time_s_;
y2 = cTable.DataSet12_Force_N_;

% create first axes (our data)
t = tiledlayout(1,1);
ax1 = axes(t);
p1=plot(ax1, x1, y1, '-r', 'LineWidth', 2);
ylabel('Normalized Impedance (Ohms)'); % every val / nominal val
xlabel('Date-Time');
ax1.XColor = 'r';
ax1.YColor = 'r';
% constrain x vals to line up graphs
xlim([x1(1) x1(length(x1))])

% create second axes (CData)
ax2 = axes(t);
p2=plot(ax2, x2, y2, 'LineWidth', 2);
ax2.XAxisLocation = 'top';
ax2.YAxisLocation = 'right';
ax2.Color = 'none';
ax1.Box = 'off';
ax2.Box = 'off';
ylabel('Force (N)'); % every val / nominal val
xlabel('Time (s)');
x2TF = ~isnan(x2);
x2 = x2(x2TF);
% constrain x vals to line graphs up
xlim([x2(1) x2(length(x2))])

% make legend
legend([p2, p1], {CDATAName, fileRequest})


% File extraction
function myFiles = extractFiles()
    FILE_MARK = "CSV";
    % extract files from D: in a list ...
    rawList = dir('C:\Users\matth\Downloads\UCSD\ARMOR\Armor Sunday Test Data\DAQ Data');
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
function newTable = reformatTable(laMesa)
    scaler = 1/16000; % scale data to ADC volt range
    PotResist = str2double(laMesa.Var1{1}); % resist. of Potentiometer
    timeStamps = {}; % keys
    ratio = []; % blank space ratios list
    blanks = 0;
    % we want normalized data for options 2/3
    nomVal = findNominal(laMesa);
    nomVal = calcZ(nomVal * scaler, PotResist); % put in impedance unit
    
    for i = 2:length(laMesa.Var1) % start @ 2 to skip first row
        % perform scaling and z math
        laMesa.Var2(i) = laMesa.Var2(i) * scaler;
        laMesa.Var2(i) = calcZ(laMesa.Var2(i), PotResist);
        laMesa.Var2(i) = laMesa.Var2(i) / nomVal;
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