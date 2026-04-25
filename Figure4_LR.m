%% ============================================================
%  ENSO Forecast + Economic Benefit Analysis
%  Author: Sri Asriyanti
% =============================================================

clear; close all; clc;

%% =========================
% 1. LOAD ENSO DATA
% =========================
filename = 'enso_seasons_revisi.csv';

T = readtable(filename);
enso = T{:,2};  
time = (1:length(enso))';

p = 44;         
trainRatio = 0.7;

%% =========================
% 2. BUILD DATASET
% =========================
X = [];
Y = [];

for i = 1:length(enso)-p
    X = [X; enso(i:i+p-1)'];
    Y = [Y; enso(i+p)];
end

nTrain = floor(trainRatio * size(X,1));

X_train = X(1:nTrain,:);
Y_train = Y(1:nTrain);

X_test  = X(nTrain+1:end,:);
Y_test  = Y(nTrain+1:end);

%% =========================
% 3. LINEAR REGRESSION MODEL
% =========================
mdl = fitlm(X_train, Y_train);

Y_pred = predict(mdl, X_test);

%% =========================
% 4. NAIVE MODEL (PERSISTENCE)
% =========================
Y_naive = X_test(:,end);  

%% =========================
% 5. EVALUATION ENSO
% =========================
rmse_model = sqrt(mean((Y_test - Y_pred).^2));
rmse_naive = sqrt(mean((Y_test - Y_naive).^2));

corr_model = corr(Y_test, Y_pred);
corr_naive = corr(Y_test, Y_naive);

fprintf('\n=== ENSO Forecast Evaluation ===\n');
fprintf('Model RMSE : %.4f\n', rmse_model);
fprintf('Naive RMSE : %.4f\n', rmse_naive);
fprintf('Model Corr : %.4f\n', corr_model);
fprintf('Naive Corr : %.4f\n', corr_naive);

%% =========================
% 6. LOAD COMMODITY DATA
% =========================
Tc = readtable('commodity_clean.csv');

price_cocoa = Tc.Cocoa;
price_sugar = Tc.Sugar;

% sesuaikan panjang data
minLen = min(length(Y_pred), length(price_cocoa));
price_cocoa = price_cocoa(end-minLen+1:end);
price_sugar = price_sugar(end-minLen+1:end);
Y_pred = Y_pred(end-minLen+1:end);

%% =========================
% 7. RELATION ENSO → PRICE (LINEAR)
% =========================
mdl_cocoa = fitlm(Y_pred, price_cocoa);
mdl_sugar = fitlm(Y_pred, price_sugar);

price_pred_cocoa = predict(mdl_cocoa, Y_pred);
price_pred_sugar = predict(mdl_sugar, Y_pred);

%% =========================
% 8. DECISION FRAMEWORK
% =========================
threshold = 0; 

decision = zeros(length(Y_pred),1);

for i = 1:length(Y_pred)
    if Y_pred(i) > threshold
        decision(i) = 1;  
    else
        decision(i) = -1; 
    end
end

%% =========================
% 9. ECONOMIC BENEFIT
% =========================
ret_cocoa = diff(price_cocoa);
ret_sugar = diff(price_sugar);

decision = decision(1:end-1);

profit_cocoa_model = sum(decision .* ret_cocoa);
profit_sugar_model = sum(decision .* ret_sugar);

profit_cocoa_base = sum(ret_cocoa);
profit_sugar_base = sum(ret_sugar);

gain_cocoa = profit_cocoa_model - profit_cocoa_base;
gain_sugar = profit_sugar_model - profit_sugar_base;

fprintf('\n=== Economic Benefit ===\n');
fprintf('Cocoa (ENSO)   : %.2f USD\n', profit_cocoa_model);
fprintf('Cocoa (Base)   : %.2f USD\n', profit_cocoa_base);
fprintf('Cocoa Gain     : %.2f USD\n', gain_cocoa);

fprintf('\nSugar (ENSO)   : %.2f USD\n', profit_sugar_model);
fprintf('Sugar (Base)   : %.2f USD\n', profit_sugar_base);
fprintf('Sugar Gain     : %.2f USD\n', gain_sugar);

%% =========================
% 10. PLOT ENSO
% =========================
figure;
plot(Y_test,'k','LineWidth',1.5); hold on;
plot(Y_pred,'r');
plot(Y_naive,'b--');
legend('Observed','Model','Naive');
title('ENSO Forecast');
grid on;

print(gcf,'-dpng','-r300','ENSO_forecast.png');

%% =========================
% 11. PLOT PRICE VS ENSO
% =========================
figure;
subplot(2,1,1)
plot(price_cocoa,'k','LineWidth',1); hold on;
plot(price_pred_cocoa,'r','LineWidth',1);
title('Cocoa Price vs ENSO');
xlabel('Time (Month)');
ylabel('Price (USD)');
legend('Actual','Predicted','Location','best');
grid off;

subplot(2,1,2)
plot(price_sugar,'k','LineWidth',1); hold on;
plot(price_pred_sugar,'r','LineWidth',1);
title('Sugar Price vs ENSO');
xlabel('Time (Month)');
ylabel('Price (USD)');
legend('Actual','Predicted','Location','best');
grid off;

print(gcf,'-dpng','-r300','Commodity_relation.png');

%% =========================
% 12. SAVE TO EXCEL
% =========================
Result = table(price_cocoa(2:end), price_sugar(2:end), ...
               decision, ret_cocoa, ret_sugar, ...
               'VariableNames',{'Cocoa','Sugar','Decision','RetCocoa','RetSugar'});

writetable(Result,'economic_results.xlsx');

fprintf('\nAll outputs saved:\n');
fprintf('- ENSO_forecast.png\n');
fprintf('- Commodity_relation.png\n');
fprintf('- economic_results.xlsx\n');