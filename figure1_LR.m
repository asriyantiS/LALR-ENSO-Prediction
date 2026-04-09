clear; close all; clc;

filename    = 'enso_seasons_revisi.csv';  
p           = 44;                     
nLeads      = 11;                  
trainRatio  = 0.7;                     

T = readtable(filename);
season_labels = T.Season;
seasonal      = T.Observed;
nSeasons      = length(seasonal);

years = str2double(extractAfter(season_labels,'-'));

muX        = mean(seasonal);
sigmaX     = std(seasonal);
seasonal_z = (seasonal - muX) ./ sigmaX;

numSamples = length(seasonal_z) - p;
X = zeros(numSamples,p);
Y = zeros(numSamples,1);

for i = 1:numSamples
    X(i,:) = seasonal_z(i:i+p-1);
    Y(i)   = seasonal_z(i+p);
end

%% ---------- Data Split (70:30) ----------
N        = size(X,1);
idxSplit = floor(trainRatio * N);

X_train  = X(1:idxSplit,:);
Y_train  = Y(1:idxSplit);
X_test   = X(idxSplit+1:end,:);
Y_test   = Y(idxSplit+1:end);

rng(42,'twister');   % reproducibility
mdl_LR = fitlm(X_train, Y_train);

%% ---------- Hindcast ----------
Ypred_LR_hind = NaN(length(seasonal),1);

for t = p+1:length(seasonal)
    x_input = seasonal_z(t-p:t-1)';
    Ypred_LR_hind(t) = predict(mdl_LR, x_input) * sigmaX + muX;
end

%% ---------- Forecast ----------
X_input = seasonal_z(end-p+1:end)';
Ypred_LR_future = zeros(nLeads,1);

labels_all = ["JFM","FMA","MAM","AMJ","MJJ","JJA", ...
              "JAS","ASO","SON","OND","NDJ","DJF"];

last_label = extractBefore(season_labels(end),"-");
last_year  = str2double(extractAfter(season_labels(end),"-"));
idx_last   = find(labels_all == last_label);

labels_future = strings(nLeads,1);

for L = 1:nLeads

    yhat_lr = predict(mdl_LR, X_input);
    Ypred_LR_future(L) = yhat_lr * sigmaX + muX;

    idx_new = mod(idx_last + L, 12);
    if idx_new == 0
        idx_new = 12;
    end

    year_new = last_year + floor((idx_last + L - 1)/12);
    labels_future(L) = labels_all(idx_new) + "-" + string(year_new);

    X_input = [X_input(2:end), yhat_lr];
end

%% ---------- Save Hindcast + Forecast ----------
all_labels  = [season_labels; labels_future];
all_obs     = [seasonal; NaN(nLeads,1)];
all_pred_LR = [Ypred_LR_hind; Ypred_LR_future];

T_out = table(all_labels, all_obs, all_pred_LR, ...
    'VariableNames', {'Season','Observed','Pred_LR'});

writetable(T_out,'enso_proyeksi.csv');
fprintf('✓ Hindcast + Forecast saved to enso_proyeksi.csv\n');

%% ---------- Evaluation per Lead (2014–Last Year) ----------
rmse_LR = NaN(nLeads,1); 
err_rmse_LR = NaN(nLeads,1);
acc_LR  = NaN(nLeads,1);  
err_acc_LR  = NaN(nLeads,1);
N_valid = NaN(nLeads,1);

Obs_season  = seasonal(years >= 2014);
Pred_LR_mat = NaN(nLeads, length(Obs_season));

for L = 1:nLeads

    numSamplesL = length(seasonal_z) - p - L + 1;
    XL = zeros(numSamplesL,p);
    YL = zeros(numSamplesL,1);
    years_Y = years(p+L:end);

    for i = 1:numSamplesL
        XL(i,:) = seasonal_z(i:i+p-1);
        YL(i)   = seasonal_z(i+p-1+L);
    end

    isTrain = years_Y < 2014;
    isTest  = years_Y >= 2014;

    X_trainL = XL(isTrain,:);
    Y_trainL = YL(isTrain);
    X_testL  = XL(isTest,:);
    Y_testL  = YL(isTest);

    N_valid(L) = length(Y_testL);

    mdl_LR_L = fitlm(X_trainL, Y_trainL);
    Yhat_LR  = predict(mdl_LR_L, X_testL) * sigmaX + muX;

    hasil_LR = pearmse1(Y_testL*sigmaX+muX, Yhat_LR);

    rmse_LR(L)    = hasil_LR(3);
    err_rmse_LR(L)= hasil_LR(4);
    acc_LR(L)     = hasil_LR(1);
    err_acc_LR(L) = hasil_LR(2);

    Pred_LR_mat(L,1:length(Yhat_LR)) = Yhat_LR';
end

Lead = (1:nLeads)';
EvalTable = table(Lead, N_valid, ...
    rmse_LR, err_rmse_LR, ...
    acc_LR, err_acc_LR);

writetable(EvalTable,'ENSO_EvalMetrics_2014_2025.csv');
fprintf('✓ RMSE & ACC saved to ENSO_EvalMetrics_2014_2025.csv\n');

PredTable = table(season_labels(years>=2014), Obs_season, ...
    'VariableNames', {'Season','Observed'});

for L = 1:nLeads
    PredTable.(['Pred_LR_Lead',num2str(L)]) = Pred_LR_mat(L,:)';
end

writetable(PredTable,'ENSO_PredPerLead_2014_2025.csv');
fprintf('✓ Per-lead predictions (2014–2025) saved.\n');

%% ---------- Plot RMSE & ACC ----------
figure('Color','w','Position',[100 100 1200 500]);

subplot(1,2,1); hold on; grid on; box on;
errorbar(Lead, rmse_LR, err_rmse_LR,'-ok','DisplayName','LR');
xlabel('Lead (season)'); ylabel('RMSE');
title('RMSE per Lead (2014–2025)');
legend('Location','best');

subplot(1,2,2); hold on; grid on; box on;
errorbar(Lead, acc_LR, err_acc_LR,'-ok','DisplayName','LR');
xlabel('Lead (season)'); ylabel('ACC');
title('ACC per Lead (2014–2025)');
legend('Location','best'); 
ylim([-0.2 1]);

%% ---------- Plot Observed vs LR ----------
leads_to_plot = [1 4 7 11];
Obs_plot = Obs_season;
nObs = length(Obs_plot);
time_cut = 1:nObs;

colorsLR   = {'k','r','c',[0.85 0.33 0.1]};
lineStyles = {'-','--','-.',':'};

figure('Color','w','Position',[100 100 1200 500]); hold on; box on;
plot(time_cut, Obs_plot,'o','MarkerFaceColor',[0 0 0.5], ...
     'MarkerEdgeColor','k','DisplayName','Observed');

for k = 1:length(leads_to_plot)
    L = leads_to_plot(k);
    plot(time_cut, Pred_LR_mat(L,:), ...
        'Color', colorsLR{k}, ...
        'LineStyle', lineStyles{k}, ...
        'LineWidth',1.5, ...
        'DisplayName',['Seasonal Lead ', num2str(L)]);
end

xlabel('Year');
ylabel('3-month averaged Niño 3.4 [°C]');
legend('Location','best','Orientation','horizontal');
legend boxoff;

years_unique = unique(years(years>=2014));
tick_pos = arrayfun(@(y)find(years(years>=2014)==y,1,'first'), years_unique);
xticks(tick_pos);
xticklabels(string(years_unique));
xtickangle(0);
grid off;

%% ---------- Display number of verification samples ----------
fprintf('\n=== NUMBER OF VERIFICATION DATA (2014 – LAST YEAR) PER LEAD ===\n');
fprintf('%-8s %-12s\n','Lead','N Data');
fprintf('%-8s %-12s\n','----','------');
for L = 1:nLeads
    fprintf('%-8d %-12d\n', L, N_valid(L));
end
fprintf('Total evaluated observations: %d seasons\n\n', sum(N_valid));