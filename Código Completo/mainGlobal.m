%% Processamento de Dados
%Lê a informação do ficheiro csv e guarda os nomes das colunas
%Por causa do VariableNamingRule
data = readtable("fraudData.csv", 'VariableNamingRule', 'preserve');

%Conversão dos valores de cada coluna categórica para valores numéricos
categoricalColumns = {'category', 'gender', 'state', 'job', 'merchant', 'street', ...
                      'city', 'zip', 'trans_num', 'first', 'last'};

for col = categoricalColumns
    if ismember(col{1}, data.Properties.VariableNames)
        if iscell(data.(col{1}))
            data.(col{1}) = categorical(data.(col{1}));         % Converte as células para categórico
        end
        data.(col{1}) = grp2idx(data.(col{1}));                 % Transforma valores categóricos em numéricos
    end
end

%Normalização de colunas contínuas
continuousColumns = {'amt', 'lat', 'long', 'city_pop', 'merch_lat', 'merch_long'};
for col = continuousColumns
    if ismember(col{1}, data.Properties.VariableNames)
        if isnumeric(data.(col{1}))
            data.(col{1}) = normalize(data.(col{1}));
        end
    end
end

%Retira apenas a hora da transação 
if ismember('trans_date_trans_time', data.Properties.VariableNames)
    data.trans_hour = hour(datetime(data.trans_date_trans_time, 'InputFormat', 'yyyy-MM-dd HH:mm:ss'));
    data.trans_date_trans_time = [];
end

%% Validação das Colunas a utilizar

%Seleciona apenas como válidas as colunas que são numéricas ou categóricas
numericColumns = varfun(@isnumeric, data, 'OutputFormat', 'uniform');
categoricalColumns = varfun(@iscategorical, data, 'OutputFormat', 'uniform');
validColumns = numericColumns | categoricalColumns;

%% Menu que permite a seleção das colunas a considerar no Naive Bayes

%Caso o utilizador queira fazer o classificador Naive Bayes apenas com
%algumas das colunas em vez de todas, apenas precisa de selecionar quais
%são as que pretende

categories = data.Properties.VariableNames; %Lista de todas as colunas disponíveis
fprintf('Categorias disponíveis para o Naive Bayes:\n');
%Salta a primeira coluna à frente e vai até à penúltima coluna
%Não se pode contar a coluna que tem os valores a indicar se é fraude ou não
for i = 2:length(categories) - 2
    fprintf('%d. %s\n', i-1, categories{i});    %Subtrai-se 1 para começar nos número 1
end
fprintf('%d. Todas as Opções\n', i);        %Opção caso queira utilizar o classificador da forma normal (com todas as colunas)

fprintf('Selecione as categorias desejadas digitando os números separados por vírgulas.\n');
selectedIndices = input('Exemplo: [1, 3, 5]: ') + 1;    %Adiciona-se 1 para corrigir o facto de antes se ter subtraído

%Garante que as categorias selecionadas estão no formato indicado e são válidas
while any(selectedIndices < 1 | selectedIndices > length(categories))
    fprintf('Seleção inválida. Tente novamente.\n');
    selectedIndices = input('Exemplo: [1, 3, 5]: ');
end

%Caso só seja introduzido um número e esse número seja igual à última opção,
%Que neste caso indica todas as colunas, então as categorias selecionadas serão todas
if numel(selectedIndices) == 1 && selectedIndices(1) == 22
    selectedCategories = validColumns;
else
    %Seleciona apenas as categorias indicadas pelo utilizador
    selectedCategories = categories(selectedIndices);
end

%Filtra os dados para incluir apenas as categorias selecionadas
X = table2array(data(:, selectedCategories));
Y = data.is_fraud;

%Gráfico que demonstra o número de fraudes que existem por hora
fraudByHour(data);

%Divisão dos dados em treino (70%) e teste (30%)
cv = cvpartition(height(data), 'HoldOut', 0.3);
Xtrain = X(training(cv), :);
Ytrain = Y(training(cv), :);
Xtest = X(test(cv), :);
Ytest = Y(test(cv), :);

%Remove as colunas que têm variância zero, porque como os seus valores não alteram,
%Não contribuem em nada para o classificador
colsToRemove = false(1, size(Xtrain, 2));
for i = 1:size(Xtrain, 2)
    class0Var = var(Xtrain(Ytrain == 0, i));
    class1Var = var(Xtrain(Ytrain == 1, i));
    if class0Var == 0 || class1Var == 0
        colsToRemove(i) = true;
    end
end

Xtrain(:, colsToRemove) = [];
Xtest(:, colsToRemove) = [];

%Chama a função naiveBayesClassifier para treinar o modelo e fazer as previsões sobre as transações de Xtest
%Além disso, ainda calcula a exatidão, precisão, recall e F1-Score do classificador
[NBModel, yPredictions, accuracy, precision, recall, f1Score] = naiveBayesClassifier(Xtrain, Ytrain, Xtest, Ytest);

fprintf("Exatidão (Accuracy): %.4f\n", accuracy);
fprintf("Precisão: %.4f\n", precision);
fprintf("Recall: %.4f\n", recall);
fprintf("F1-Score: %.4f\n", f1Score);

%Matriz de confusão para apresentar os falsos positivos, falsos negativos,
%Verdadeiros negativos e verdadeiros positivos
figure;
confusionchart(Ytest, yPredictions, 'RowSummary', 'row-normalized', 'ColumnSummary', 'column-normalized');
title('Matriz de Confusão');

%Gráfico de barras que mostra a quantidade de transações fraudulentas e não fraudulentas
%Que existem no ficheiro que contém os dados
figure;
counts = [sum(Ytest == 0), sum(Ytest == 1)];
bar(categorical({'Não Fraude', 'Fraude'}), counts);
title('Distribuição de Transações no Conjunto de Teste');
ylabel('Número de Transações');
xlabel('Classe');

%% Implementação do Bloom Filter
% Parâmetros do Bloom Filter
m = 1e6;            % Tamanho do vetor de bits
k = 3;              % Número de funções hash

%Considera apenas as colunas que têm a informação sobre o número do cartão, o merchant e a categoria da compra
%Apenas utiliza as transações fraudulentas
fraudulentTransactions = [string(data.cc_num), string(data.merchant), string(data.category)];
fraudulent = data.is_fraud == 1;            
fraudulentTransactions = fraudulentTransactions(fraudulent, :);

%Seleciona uma transação aleatória para o bloom filter avaliar se é fraudulenta ou não
transactionIndex = randi(height(data));
testTransaction = [string(data.cc_num(transactionIndex)), string(data.merchant(transactionIndex)), string(data.category(transactionIndex))];
[bloomFilter, isFraudulent] = buildBloomFilter(fraudulentTransactions, testTransaction, m, k);

if isFraudulent
    fprintf("A transação de teste foi identificada como potencialmente fraudulenta.\n");
else
    fprintf("A transação de teste foi identificada como não fraudulenta.\n");
end

%% MinHash e Agrupamento de Transações Similares
%Considera apenas as colunas que têm informação sobre o número do cartão,
%O merchant, a categoria da compra e o seu valor
relevantColumns = {'cc_num', 'merchant', 'category', 'amt'};
data_relevant = data(:, relevantColumns);
isFraud = data.is_fraud;

%Cria-se os shingles com as informações de cada transação
cc_num = string(data_relevant.cc_num);
merchant = string(data_relevant.merchant);
category = string(data_relevant.category);
amt = string(data_relevant.amt);

shingles = cell(height(data_relevant), 1);
for i = 1:height(data_relevant)
    shingle = cc_num(i) + "    " + merchant(i) + "    " + category(i) + "    " + amt(i);
    shingles{i} = shingle;
end

%Funções hash que vão ser utilizadas para os cálculos (São as mesmas do bloom filter)
m = 1000;
hashFunctions = {@(x) mod(abs(sum(double(char(x))) + 31), m) + 1, ...
                 @(x) mod(abs(sum(double(char(x))) * 17 + 7), m) + 1, ...
                 @(x) mod(abs(prod(double(char(x))) + 53), m) + 1};

%Invoca-se a função para gerar signatures para cada transação
signatures = generateSignatures(shingles, 3, hashFunctions);

%Calcula a matriz de similaridade de Jaccard e compara com as signatures geradas pelas funções hash
similarityMatrix = zeros(height(data_relevant));
for i = 1:height(data_relevant)
    for j = 1:height(data_relevant)
        similarityMatrix(i, j) = jaccardSimilarity(signatures(i), signatures(j));
        similarityMatrix(j, i) = similarityMatrix(i, j);
    end
end

%Gráfico para observar a similaridade das transações entre si
figure;
imagesc(similarityMatrix);
colorbar;
title('Matriz de Similaridade de Jaccard');
xlabel('Transação 1');
ylabel('Transação 2');

% %Agrupa transações semelhantes com base na similaridade calculada anteriormente
numHashFunctions = 3;
similarityThreshold = 0.8;
[clusters, similarityMatrix] = detectFraudClusters(shingles, numHashFunctions, similarityThreshold);

%Lista para armazenar os clusters fraudulentos
fraudClusters = {};

%Verifica se cada cluster contém transações fraudulentas
%Caso seja uma fraude, então esse cluster vai ser adicionado à lista que
%Contém todos os clusters fraudulentos
for i = 1:length(clusters)
    clusterFraud = isFraud(clusters{i});
    if any(clusterFraud)
        fraudClusters{end + 1} = clusters{i};
    end
end

numClustersToPlot = length(fraudClusters);      %Número de clusters fraudulentos que existem
clusterIDs = 1:min(numClustersToPlot, length(fraudClusters)); %IDs dos clusters para depois fazer o gráfico

%Reorganiza as transações tendo em conta os clusters fraudulentos
combinedIndices = [];
clusterBoundaries = zeros(length(clusterIDs), 1);
for i = 1:length(clusterIDs)
    indices = fraudClusters{clusterIDs(i)};
    combinedIndices = [combinedIndices; indices];       %Combina os índices dos clusters fraudulentos
    clusterBoundaries(i) = length(combinedIndices);     %Define os limites da similiaridade entre clusters
end

%Reorganiza a matriz de similaridade com os clusters fraudulentos
reorderedMatrix = similarityMatrix(combinedIndices, combinedIndices);

%Faz um novo gráfico com as transações reordenadas pelos clusters fraudulentos
figure;
imagesc(reorderedMatrix);
colorbar;
title(sprintf('Heatmap de Similaridade - %d Clusters Fraudulentos', numClustersToPlot));
xlabel('Transações (Reorganizadas)');
ylabel('Transações (Reorganizadas)');