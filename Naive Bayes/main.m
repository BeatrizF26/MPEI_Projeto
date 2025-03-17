%Lê a informação do ficheiro csv e guarda os nomes das colunas
%Por causa do VariableNamingRule
data = readtable("fraudData.csv", 'VariableNamingRule', 'preserve');

%Conversão dos valores de cada coluna categórica para valores numéricos através do grp2idx
%Caso a informação da coluna seja um array de células,
%Tranforma-se os valores em categóricos e só depois em numéricos
categoricalColumns = {'category', 'gender', 'state', 'job', 'merchant', 'street', ...
                      'city', 'zip', 'trans_num', 'first', 'last'};
for col = categoricalColumns
    if ismember(col{1}, data.Properties.VariableNames)
        if iscell(data.(col{1}))
            data.(col{1}) = categorical(data.(col{1})); %Converte as células para categórico
        end
        data.(col{1}) = grp2idx(data.(col{1}));         %Transforma valores categóricos em numéricos
    end
end

%Quando as colunas são contínuas, precisam de ser normalizadas para que
%Seja mais fácil de trabalhar com os valores
continuousColumns = {'amt', 'lat', 'long', 'city_pop', 'merch_lat', 'merch_long'};
for col = continuousColumns
    if ismember(col{1}, data.Properties.VariableNames)
        if isnumeric(data.(col{1}))
            data.(col{1}) = normalize(data.(col{1}));
        end
    end
end

%Retira-se a hora da transação da coluna que contém as informações sobre a data e a hora
if ismember('trans_date_trans_time', data.Properties.VariableNames)
    data.trans_hour = hour(datetime(data.trans_date_trans_time, 'InputFormat', 'yyyy-MM-dd HH:mm:ss'));
    data.trans_date_trans_time = [];
end

%Seleciona as colunas numéricas e categóricas para poder utilizar o
%Classificador de Naive Bayes apenas nessas colunas
numericColumns = varfun(@isnumeric, data, 'OutputFormat', 'uniform');
categoricalColumns = varfun(@iscategorical, data, 'OutputFormat', 'uniform');
validColumns = numericColumns | categoricalColumns;

%Executa os cenários com diferentes proporções de teste e de treino
[Ytest_50, yPred_50] = trainAndTestScenario(data, validColumns, 0.5); % 50% treino
[Ytest_60, yPred_60] = trainAndTestScenario(data, validColumns, 0.4); % 60% treino
[Ytest_70, yPred_70] = trainAndTestScenario(data, validColumns, 0.3); % 70% treino
[Ytest_90, yPred_90] = trainAndTestScenario(data, validColumns, 0.1); % 90% treino


%Exibe todas as matrizes de confusão em uma única figura
%As matrizes de confusão têm as informações sobre os verdadeiros negativos,
%Falsos positivos, falsos negativos e verdadeiros positivos para cada um dos cenários
figure;
tiledlayout(2,2);

nexttile;
confusionchart(Ytest_60, yPred_60, 'RowSummary', 'row-normalized', 'ColumnSummary', 'column-normalized');
title('Matriz de Confusão 60% treino');

nexttile;
confusionchart(Ytest_50, yPred_50, 'RowSummary', 'row-normalized', 'ColumnSummary', 'column-normalized');
title('Matriz de Confusão 50% treino');

nexttile;
confusionchart(Ytest_70, yPred_70, 'RowSummary', 'row-normalized', 'ColumnSummary', 'column-normalized');
title('Matriz de Confusão 70% treino');

nexttile;
confusionchart(Ytest_90, yPred_90, 'RowSummary', 'row-normalized', 'ColumnSummary', 'column-normalized');
title('Matriz de Confusão 90% treino');

%--------------------------------------------------------------------
%A partir daqui, executamos sempre para 70% treino, mas variando a coluna categórica utilizada
%Selecionamos as colunas categóricas originais (já convertidas)
selectedCategoricalColumns = {'category', 'gender', 'state', 'job', 'merchant', 'street', ...
                              'city', 'zip', 'trans_num', 'first', 'last'};

%Identifica as colunas numéricas (após as conversões)
numericColumns = varfun(@isnumeric, data, 'OutputFormat', 'uniform');
numericVars = data.Properties.VariableNames(numericColumns);

holdOutPercent = 0.3;           %70% treino, 30% teste
numCats = length(selectedCategoricalColumns);
Ytest_all = cell(numCats, 1);
yPred_all = cell(numCats, 1);

%Calcula a exatidão, precisão, recall e F1-Score do classificador para cada categoria
for i = 1:numCats
    catCol = selectedCategoricalColumns{i};
    %Cria a lista de colunas utilizadas: numéricas + esta categórica
    %Garante que não há colunas iguais e que essas colunas fazem parte do dataset 
    columnsToUse = [numericVars, {catCol}];
    columnsToUse = unique(columnsToUse);
    columnsToUse = columnsToUse(ismember(columnsToUse, data.Properties.VariableNames));

    %A matriz X é composta por todas as linhas das colunas válidas (categóricas ou numéricas)
    %A matriz Y é onde se encontram os valores para verificar se as transações são fraudes ou não
    X = table2array(data(:, columnsToUse));
    Y = data.is_fraud;

    %Divide a informação do ficheiro para a matriz de treino (70%) e a de teste (30%)
    cv = cvpartition(height(data), 'HoldOut', holdOutPercent);
    Xtrain = X(training(cv), :);
    Ytrain = Y(training(cv), :);
    Xtest = X(test(cv), :);
    Ytest_scenario = Y(test(cv), :);

    %Remove colunas onde todas as linhas de uma coluna tenham resultados idênticos,
    %Ou seja, a variância é 0 porque as variáveis não variam
    colsToRemove = false(1, size(Xtrain, 2));
    for j = 1:size(Xtrain, 2)
        class0Var = var(Xtrain(Ytrain == 0, j));
        class1Var = var(Xtrain(Ytrain == 1, j));
        if class0Var == 0 || class1Var == 0
            colsToRemove(j) = true;
        end
    end

    %As matrizes de teste e de treino passam a não contar com essas colunas
    Xtrain(:, colsToRemove) = [];
    Xtest(:, colsToRemove) = [];

    [NBModel, yPred_scenario, accuracy, precision, recall, f1Score] = naiveBayesClassifier(Xtrain, Ytrain, Xtest, Ytest_scenario);

    %Exibição dos resultados
    fprintf("Resultados com 70%% treino usando a categoria '%s':\n", catCol);
    fprintf("Exatidão: %.4f\n", accuracy);
    fprintf("Precisão: %.4f\n", precision);
    fprintf("Recall: %.4f\n", recall);
    fprintf("F1-Score: %.4f\n\n", f1Score);

    %Guarda os resultadoos obtidos em células 
    Ytest_all{i} = Ytest_scenario;
    yPred_all{i} = yPred_scenario;
end

%Criar ficheiro com as variáveis mais importantes do classificador de Naive Bayes
diretorioAtual = pwd;
diretorioAnterior = fullfile(diretorioAtual, '..');
nomeFicheiro = "dados.mat";
diretorioFicheiro = fullfile(diretorioAnterior, nomeFicheiro);

save(diretorioFicheiro, 'data', "Xtrain","Ytrain","Xtest","Ytest_scenario", "NBModel", "yPred_scenario", ...
    "accuracy", "precision", "recall", "f1Score");