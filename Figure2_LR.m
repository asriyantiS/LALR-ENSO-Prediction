indozy = readtable('ENSO_EvalMetrics_2014_2025.csv');

season_leads = indozy.Lead;
corr_lr      = indozy.acc_LR;
rmse_lr      = indozy.rmse_LR;

err_corr_lr  = indozy.err_acc_LR;
err_rmse_lr  = indozy.err_rmse_LR;

% Chen et al. (2023) – seasonal ENSO skill
jurnal_chen = readtable('Chen_ACC_seasonal.csv');          % ACC
jurnal_chen_rmse = readtable('Chen_RMSE_seasonal.csv'); % RMSE

jurnal_chen.Properties.VariableNames       = {'Seasons','Correlation'};
jurnal_chen_rmse.Properties.VariableNames  = {'Seasons','RMSE'};

corr_chen_season = jurnal_chen.Correlation;
rmse_chen_season = jurnal_chen_rmse.RMSE;

style.IndOzy_LR = struct('Color',[0 0.4470 0.7410],'Marker','o');
style.Chen      = struct('Color',[0.4660 0.6740 0.1880],'Marker','x');

maxLead = 11;
lead_idx = season_leads <= maxLead;

season_leads = season_leads(lead_idx);
corr_lr      = corr_lr(lead_idx);
rmse_lr      = rmse_lr(lead_idx);
err_corr_lr  = err_corr_lr(lead_idx);
err_rmse_lr  = err_rmse_lr(lead_idx);

corr_chen_season = corr_chen_season(1:min(maxLead,numel(corr_chen_season)));
rmse_chen_season = rmse_chen_season(1:min(maxLead,numel(rmse_chen_season)));

%% ================== Plot ACC ==================
figure;

subplot(2,1,1);
errorbar(season_leads, corr_lr, err_corr_lr, '-', ...
    'Color',style.IndOzy_LR.Color, ...
    'Marker',style.IndOzy_LR.Marker, ...
    'LineWidth',1.5); hold on;

plot(1:numel(corr_chen_season), corr_chen_season, '-', ...
    'Color',style.Chen.Color, ...
    'Marker',style.Chen.Marker, ...
    'LineWidth',1.5);

xlabel('Lead Time (Seasons)');
ylabel('ACC');
yline(0.5,'--k');

legend('LALR','Chen et al. (2023)', ...
    'Location','southwest', ...
    'FontSize',8, ...
    'Orientation','horizontal');

xlim([1 maxLead]);
xticks(1:maxLead);
ylim([0 1]);

legend box off;
grid off;

%% ================== Plot RMSE ==================
subplot(2,1,2);

errorbar(season_leads, rmse_lr, err_rmse_lr, '-', ...
    'Color',style.IndOzy_LR.Color, ...
    'Marker',style.IndOzy_LR.Marker, ...
    'LineWidth',1.5); hold on;

plot(1:numel(rmse_chen_season), rmse_chen_season, '-', ...
    'Color',style.Chen.Color, ...
    'Marker',style.Chen.Marker, ...
    'LineWidth',1.5);

xlabel('Lead Time (Seasons)');
ylabel('RMSE (°C)');

xlim([1 maxLead]);
xticks(1:maxLead);
ylim([0 1]);

grid off;

%% ================== Print RMSE Values ==================
fprintf('\n=================================\n');
fprintf('         RMSE COMPARISON\n');
fprintf('=================================\n');

fprintf('\n--- IndOzy–LR RMSE per Lead ---\n');
for i = 1:length(rmse_lr)
    fprintf('Lead %2d : %.4f\n', i, rmse_lr(i));
end

fprintf('\n--- Chen et al. (2023) RMSE per Lead ---\n');
for i = 1:length(rmse_chen_season)
    fprintf('Lead %2d : %.4f\n', i, rmse_chen_season(i));
end

fprintf('\n=================================\n\n');
