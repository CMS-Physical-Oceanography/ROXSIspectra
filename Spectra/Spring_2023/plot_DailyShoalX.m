%% plot_DailyShoalX.m
%
% Noah Clark        3/14/24
%
% Purpose: % Purpose: Calculate the observed and theoretical shoaling coefficients at
%          each hour and determine the EWM for each hour in the sea and 
%          swell bands. Then average the hours per day. This is done for
%          all spotter buoys and ADCPs at Asilomar.
%
% ------------------------------------------------------------------------
% ------------------------------------------------------------------------


%% Preliminaries

clc;clear;

    % Spotter Buoy Data
load('WBvariables.mat','XSee','Xdepth','Xtime')
h = Xdepth;
See = XSee;
See{1} = See{1}(2:end,:);
See{2} = See{2}(2:end,:);
See{3} = See{3}(2:end,:);

    % ADCP Data
load('SM&ADCP_All.mat','ADCP')
TdayADCP = datetime(2022,6,25):datetime(2022,7,19);
ADCP.time = ADCP.time(66:666); % June 25 - July 19
ADCP.X05.See = ADCP.X05.See(2:end,66:666); % take out the times to fit with data from spotters
ADCP.X11.See = ADCP.X11.See(2:end,66:666);
ADCP.X05.depth = ADCP.X05.depth(66:666);
ADCP.X11.depth = ADCP.X11.depth(66:666);

ADCP.freq = ADCP.freq(2:end);

    % Define Variables
ff = 0.0098:0.0098:(0.0098*128);
ff = ff';
TT = 1./ff;
ffa = ff(1:35); %for adcp
TTa = 1./ffa; %for adcp

Tday = datetime(2022,6,16):datetime(2022,7,19);

    % Interpolate ADCP Sees to spotter frequencies
ADCP.X05.See = interp1(ADCP.freq',ADCP.X05.See,ff');
ADCP.X05.See = ADCP.X05.See(1:35,:);
ADCP.X11.See = interp1(ADCP.freq',ADCP.X11.See,ff');
ADCP.X11.See = ADCP.X11.See(1:35,:);


%% Calculate GROUP SPEED

% WAVELENGTH and PHASE SPEED

        % X01, X03, and X04
for i = 1:832
    for j = 1:128
        [L{1}(j,i),~] = LDR(TT(j),h{1}(i)); %wavelength
        [L{2}(j,i),~] = LDR(TT(j),h{2}(i)); %wavelength
        [L{3}(j,i),~] = LDR(TT(j),h{3}(i)); %wavelength
    end

    c{1}(:,i) = L{1}(:,i)./TT; %phase speed
    c{2}(:,i) = L{2}(:,i)./TT; %phase speed
    c{3}(:,i) = L{3}(:,i)./TT; %phase speed

    for j = 1:128
        Cg{1}(j,i) = (c{1}(j,i)/2).*(1+((4*pi*h{1}(i))/L{1}(j,i))./...
            sinh((4*pi*h{1}(i))/L{1}(j,i)));
        Cg{2}(j,i) = (c{2}(j,i)/2).*(1+((4*pi*h{2}(i))/L{2}(j,i))./...
            sinh((4*pi*h{2}(i))/L{2}(j,i)));
        Cg{3}(j,i) = (c{3}(j,i)/2).*(1+((4*pi*h{3}(i))/L{3}(j,i))./...
            sinh((4*pi*h{3}(i))/L{3}(j,i)));
    end
end

        % X05 and X11
for i = 1:601
    for j = 1:35
        [L{4}(j,i),~] = LDR(TTa(j),ADCP.X05.depth(i)); %wavelength
        [L{5}(j,i),~] = LDR(TTa(j),ADCP.X11.depth(i)); %wavelength
    end
    
    c{4}(:,i) = L{4}(:,i)./TTa; %phase speed
    c{5}(:,i) = L{5}(:,i)./TTa; %phase speed
    
    for j = 1:35
        Cg{4}(j,i) = (c{4}(j,i)/2).*(1+((4*pi*ADCP.X05.depth(i))/L{4}(j,i))./...
            sinh((4*pi*ADCP.X05.depth(i))/L{4}(j,i)));
        Cg{5}(j,i) = (c{5}(j,i)/2).*(1+((4*pi*ADCP.X11.depth(i))/L{5}(j,i))./...
            sinh((4*pi*ADCP.X11.depth(i))/L{5}(j,i)));
    end
end


%% Calculate Observed and Theoretical Shoaling Coeffs per hour

% THEORETICAL
Ks_T{1} = sqrt(Cg{1}./Cg{2});
Ks_T{2} = sqrt(Cg{2}./Cg{3});
Ks_T{3} = sqrt(Cg{3}(1:35,217:817)./Cg{4});
Ks_T{4} = sqrt(Cg{4}./Cg{5});

% OBSERVED
Ks_O{1} = See{2}./See{1};
Ks_O{2} = See{3}./See{2};
Ks_O{3} = ADCP.X05.See./See{3}(1:35,217:817);
Ks_O{4} = ADCP.X11.See./ADCP.X05.See;


%% Determine EWM for each hour in Sea and Swell
% from here find the EWM for each hour in the sea and swell and then find
% the average of those per day 

See{2}(:,173) = 0; % replace NaNs with 0s so below calculation can be performed

% Average Sees between buoys
ASee{1} = (See{1}(1:35,:) + See{2}(1:35,:))./2;
ASee{1}(173) = NaN;
ASee{2} = (See{2}(1:35,:) + See{3}(1:35,:))./2;
ASee{2}(173) = NaN;
ASee{3} = (See{3}(1:35,217:817) + ADCP.X05.See(1:35,:))./2;
ASee{4} = (ADCP.X05.See(1:35,:) + ADCP.X11.See(1:35,:))./2;

for j = 1:4
    
    if j == 1 || j == 2 % X01 to X03 & X03 to X04
        N = 832;
    else %X04 to X05 & X05 to X11
        N = 601;
    end
    
    for i = 1:N
            % Sea
        m0Sea = trapz(ff(9:24),ASee{j}(9:24,i),1);
        m1SeaT = trapz(ff(9:24),ASee{j}(9:24,i).*Ks_T{j}(9:24,i));
        m1SeaO = trapz(ff(9:24),ASee{j}(9:24,i).*Ks_O{j}(9:24,i));
        EWM_KsT_Sea{j}(i) = m1SeaT./m0Sea;
        EWM_KsO_Sea{j}(i) = m1SeaO./m0Sea;
            % Swell
        m0Swell = trapz(ff(4:9),ASee{j}(4:9,i),1);
        m1SwellT = trapz(ff(4:9),ASee{j}(4:9,i).*Ks_T{j}(4:9,i));
        m1SwellO = trapz(ff(4:9),ASee{j}(4:9,i).*Ks_O{j}(4:9,i));
        EWM_KsT_Swell{j}(i) = m1SwellT./m0Swell;
        EWM_KsO_Swell{j}(i) = m1SwellO./m0Swell;
    end
end


%% Average Per Day

for j = 1:4
    if j == 1 || j == 2 % X01 to X03 & X03 to X04
        N = 34;
    else % X04 to X05 & X05 to X11
        N = 25;
    end
    
    for i = 1:N
        EWM_DD_KsT_Sea{j}(i) = nanmean(EWM_KsT_Sea{j}(i*24-23:i*24));
        EWM_DD_KsO_Sea{j}(i) = nanmean(EWM_KsO_Sea{j}(i*24-23:i*24));
        
        EWM_DD_KsT_Swell{j}(i) = nanmean(EWM_KsT_Swell{j}(i*24-23:i*24));
        EWM_DD_KsO_Swell{j}(i) = nanmean(EWM_KsO_Swell{j}(i*24-23:i*24));
    end
end


%% Determine the means of the EWMs
% averages done for the observations

    % Sea
for i = 1:4
    Avg_KsO_Sea{i} = nanmean(EWM_DD_KsO_Sea{i});
end

    % Swell
for i = 1:4
    Avg_KsO_Swell{i} = nanmean(EWM_DD_KsO_Swell{i});
end


%% Plotting

figure(1);clf;

    % SWELL
subplot(1,2,1)
plot(Tday,EWM_DD_KsO_Swell{1},'bx','MarkerSize',10)
hold on; grid on;
plot(Tday,EWM_DD_KsO_Swell{2},'mx','MarkerSize',10)
plot(TdayADCP,EWM_DD_KsO_Swell{3},'gx','MarkerSize',10)
plot(TdayADCP,EWM_DD_KsO_Swell{4},'rx','MarkerSize',10)

plot(Tday,EWM_DD_KsT_Swell{1},'b-')
plot(Tday,EWM_DD_KsT_Swell{2},'m-')
plot(TdayADCP,EWM_DD_KsT_Swell{3},'g-')
plot(TdayADCP,EWM_DD_KsT_Swell{4},'r-')

title('Asilomar: Swell Shoaling Coefficients','fontsize',17)
legend('X01 - X03 (AVG=0.948)','X03 - X04 (AVG=1.055)',...
    'X04 - X05 (AVG=0.934)','X05 - X11 (AVG=0.353)','fontsize',10,...
    'location','northeast')
xlabel('Date','fontsize',15)
ylabel('K_s','fontsize',15)
ylim([0 1.6])
xlim([datetime(2022,6,15) datetime(2022,7,20)])


    % SEA
subplot(1,2,2)
plot(Tday,EWM_DD_KsO_Sea{1},'bx','MarkerSize',10)
hold on; grid on;
plot(Tday,EWM_DD_KsO_Sea{2},'mx','MarkerSize',10)
plot(TdayADCP,EWM_DD_KsO_Sea{3},'gx','MarkerSize',10)
plot(TdayADCP,EWM_DD_KsO_Sea{4},'rx','MarkerSize',10)

plot(Tday,EWM_DD_KsT_Sea{1},'b-')
plot(Tday,EWM_DD_KsT_Sea{2},'m-')
plot(TdayADCP,EWM_DD_KsT_Sea{3},'g-')
plot(TdayADCP,EWM_DD_KsT_Sea{4},'r-')

title('Asilomar: Sea Shoaling Coefficients','fontsize',17)
legend('X01 - X03 (AVG=0.974)','X03 - X04 (AVG=0.980)',...
    'X04 - X05 (AVG=1.113)','X05 - X11 (AVG=0.065)','fontsize',10,...
    'location','northeast')
xlabel('Date','fontsize',15)
ylim([0 1.6])
xlim([datetime(2022,6,15) datetime(2022,7,20)])


%% Plot  Overall Time Averaged Spectrums

figure(2);clf;
plot(ff,mean(See{1},2),'b')
hold on; grid on;
plot(ff,nanmean(See{2},2),'m')
plot(ff,mean(See{3},2),'g') % the average energy at B04 is lower than that at X11 during time X11 was recording
plot(ffa,mean(ADCP.X05.See,2),'r')
plot(ffa,mean(ADCP.X11.See,2),'c')

load('SM&ADCP_All.mat','ADCP') %original ADCP Data
plot(ADCP.freq(2:end),nanmean(ADCP.X05.See(2:end,66:666),2),'r','LineWidth',2)
plot(ADCP.freq(2:end),nanmean(ADCP.X11.See(2:end,66:666),2),'c','LineWidth',2)

xline(0.0882,'--k')
xlim([0,0.25])
title('Asilomar Time Averaged Spectrums')
xlabel('f')
ylabel('E')
legend('X01','X03','X04','X05','X11','og X05','og X11')



%% Clean Up

clear i j ffa m0Sea m0Swell m1SeaO m1Seat m1SwellO m1SwellT N













