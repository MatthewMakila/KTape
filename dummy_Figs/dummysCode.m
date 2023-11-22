% work for dummies 1 & 2 (Lucas & JJ)

myFile = 'C:\Users\matth\Downloads\Trial08.csv';

% read in file, now it's stored for our use
myTable = readtable(myFile);
myTable(1:2,:) = []; % get rid of extraneous rows

hold on;
constTime = 8/960;
channel1 = [];
channel2 = [];
channel3 = [];
channel4 = [];
channel5 = [];
channel6 = [];
channel7 = [];

avg1 = 0;
avg2 = 0;
avg3 = 0;
avg4 = 0;
avg5 = 0;
avg6 = 0;
avg7 = 0;

for i = 1:length(myTable.Var2)
    avg1 = avg1 + myTable.GenericAnalog_1_ElectricPotential(i);
    avg2 = avg2 + myTable.Var4(i);
    avg3 = avg3 + myTable.Var5(i);
    avg4 = avg4 + myTable.Var6(i);
    avg5 = avg5 + myTable.Var7(i);
    avg6 = avg6 + myTable.Var8(i);
    avg7 = avg7 + myTable.Var9(i);

    if myTable.Var2(i) == 7
        % dump avg
        channel1 = [channel1, avg1/7];
        channel2 = [channel2, avg2/7];
        channel3 = [channel3, avg3/7];
        channel4 = [channel4, avg4/7];
        channel5 = [channel5, avg5/7];
        channel6 = [channel6, avg6/7];
        channel7 = [channel7, avg7/7];
        avg1 = 0;
        avg2 = 0;
        avg3 = 0;
        avg4 = 0;
        avg5 = 0;
        avg6 = 0;
        avg7 = 0;
    end
end

V = uint32(1):uint32(6159);


subplot(7,1,1);
plot(V, channel1, 'LineWidth', 2);
title('Left Neck');
ylabel('V');
subplot(7,1,2);
plot(V, channel2, 'LineWidth', 2);
title('Right Neck');
ylabel('V');

subplot(7,1,3);
plot(V, channel3, 'LineWidth', 2);
title('Mid Abdomen');
ylabel('V');

subplot(7,1,4);
plot(V, channel4, 'LineWidth', 2);
title('Lower Right Back');
ylabel('V');

subplot(7,1,5);
plot(V, channel5, 'LineWidth', 2);
title('Lower Left Back');
ylabel('V');

subplot(7,1,6);
plot(V, channel6, 'LineWidth', 2);
title('Lower Right Abdomen');
ylabel('V');

subplot(7,1,7);
plot(V, channel7, 'LineWidth', 2);
title('Lower Left Abdomen');
ylabel('V');
xlabel('Time');


