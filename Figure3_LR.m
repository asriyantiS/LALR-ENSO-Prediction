P = readtable('DATA_OBSERVED_TERBARU_LR.csv'); 

lastObsIdx = find(~isnan(P.Observed), 1, 'last');

obsVals    = P.Observed(1:lastObsIdx);
obsSeasons = P.Seasons(1:lastObsIdx);

lrVals      = P.Proyeksi_LR(lastObsIdx+1:end);
projSeasons = P.Seasons(lastObsIdx+1:end);

rmse_1_11 = [0.0808, 0.1931, 0.3371, ...
             0.4511, 0.5487, 0.6357, ...
             0.7076, 0.7688, 0.8151, ...
             0.8454, 0.8627];

lrVals_1_11       = lrVals(1:11);
projSeasons_1_11  = projSeasons(1:11);

I = readtable('Data_IRI_TERBARU.csv');
iriDyn   = I.Average_Dynamical(lastObsIdx+1:end);
iriStat  = I.Average_Statistical(lastObsIdx+1:end);
iriSeasons = I.Seasons(lastObsIdx+1:end);

figure; hold on; box on;

plot(1:numel(obsVals), obsVals, 'k-o', 'LineWidth',1.5, ...
    'MarkerFaceColor','k', 'DisplayName','Observed');

x_lr = numel(obsVals) + (1:numel(lrVals_1_11));
errorbar(x_lr, lrVals_1_11, rmse_1_11, '^-', ...
    'Color',[0 0.4470 0.7410], 'LineWidth',1.5, ...
    'MarkerFaceColor',[0 0.4470 0.7410], ...
    'DisplayName','LALR');

% --- IRI Dynamical ---
x_dyn = numel(obsVals) + (1:numel(iriDyn));
plot(x_dyn, iriDyn, 'o-', 'Color',[1 0.4 0], 'LineWidth',1.5, ...
    'MarkerFaceColor',[1 0.6 0.3], 'DisplayName','IRI Dynamical');

% --- IRI Statistical ---
x_stat = numel(obsVals) + (1:numel(iriStat));
plot(x_stat, iriStat, 's-', 'Color',[0.2 0.6 0.2], 'LineWidth',1.5, ...
    'MarkerFaceColor',[0.4 0.8 0.4], 'DisplayName','IRI Statistical');

allSeasons = [obsSeasons ; projSeasons_1_11];

xticks(1:length(allSeasons));
xticklabels(allSeasons);

xtickangle(45);

xlabel('Seasons 2025 - 2026');
ylabel('Niño 3.4 SST anomaly (°C)');
ylim([-1.5 1]);
yticks(-2:0.5:2);

legend('Location','best','Orientation','horizontal');
legend boxoff;

yline(0.5, '--k', 'HandleVisibility','off');
yline(-0.5, '--k', 'HandleVisibility','off');

grid off;
