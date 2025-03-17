%Lê a informação do ficheiro csv e guarda os nomes das colunas
%Por causa do VariableNamingRule
data = readtable("fraudData.csv", 'VariableNamingRule', 'preserve');

%Seleciona as colunas relevantes para o minHash (número do cartão, merchant, categoria e preço)
%Para trabalhar apenas com as informações nessas colunas
relevantColumns = {'cc_num', 'merchant', 'category', 'amt'};
data_relevant = data(:, relevantColumns);
isFraud = data.is_fraud;

%Converte os valores das colunas para strings
cc_num = string(data_relevant.cc_num);
merchant = string(data_relevant.merchant);
category = string(data_relevant.category);
amt = string(data_relevant.amt);

%Cria-se os shingles com as informações de cada transação
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

%Agrupa transações semelhantes com base na similaridade calculada anteriormente
numHashFunctions = 3;
similarityThreshold = 0.8;

% Deteta clusters de transações semelhantes
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

%Guarda num ficheiro as variáveis mais importantes do módulo minHash
diretorioAtual = pwd;
diretorioAnterior = fullfile(diretorioAtual, '..');
nomeFicheiro = "dados.mat";
diretorioFicheiro = fullfile(diretorioAnterior, nomeFicheiro);

save(diretorioFicheiro, "shingles", "similarityThreshold", "hashFunctions", "signatures", "clusters", ...
    "fraudClusters", "reorderedMatrix", '-append');
