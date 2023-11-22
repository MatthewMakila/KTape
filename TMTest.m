% Author:   Matthew Makila
% Date:     07/25/22
% Title:    TMTest.m
% Desc:     File to process 8-channel data for various plotting schemes

% loaded files from specific drives
FILE_PATH1 = 'C:\Users\matth\Downloads\UCSD\ARMOR\TMTestData.xlsx';
T = readtable(FILE_PATH1);

% for loop to plot each col (V) against last col (time)
Tcols = {};
for i = 1:length(T.Properties.VariableNames)
   colName = T.Properties.VariableNames{i};
   Tcols = [Tcols, colName];
end

x = T.(Tcols{end});
hold on;
for i = 1:length(Tcols) - 1 % exclude last col of time
    T = convertTable(T, Tcols); % make resistance val
    plot(x, T.(Tcols{i}), 'DisplayName', strcat('DATA CHANNEL_', num2str(i)));
end
% constrain graph to x limits of data
xlim([x(1) x(length(x))])

hold off;
% make legend
legend

% writetable(T,'exampleT.csv'); 

%{

-----------------------------------------------------------------------

%}
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

function newTable = convertTable(T, Cols)
    for i = 1:length(T.Properties.VariableNames) - 1
        for j = 1:length(T.(Cols{i}))
            %T.(Cols{i})(j) = resistConvert(T.(Cols{i})(j));
        end
    end
    newTable = T;
end

% find resistance in volt. divide circuit
function r1 = resistConvert(vout)
    % voltage divider equation, use arbitrary resist. val
    r2 = 220; 
    vin = 3;
    r1 = (vout * r2) / (vin - vout);
end

% Impedance calculator
function z = calcZ(deltaV, R_p)
    R_p = ((256 - R_p) / 256) * 10^6; % resist. in MegaOhms
    V_DD = 3; % Approx. 3V supplied voltage
    z = (R_p * (V_DD - 2 * deltaV)) / (V_DD + 2 * deltaV); %derived z eq.
end