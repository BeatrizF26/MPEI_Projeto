function [clusters, similarity] = detectFraudClusters(transactions, numHashFunctions, similarityThreshold)
%Função que deteta clusters de transações fraudulentas recorrendo ao minHash
%transactions -> Célula que contem os shingles para cada informação
%numHashFunctions -> Número de funções hash que vão ser calculadas
%similarityThreshold -> Limiar para determinar se duas transações pertencem ao mesmo cluster.

    numTransactions = length(transactions);
    
    %Cria um conjunto único com todos os shingles nas transações
    shingles = unique([transactions{:}]);
    universeSize = length(shingles);
    
    signatureMatrix = zeros(numHashFunctions, numTransactions);
    
    %Gera os coeficientes para as funções de hash de forma aleatória
    a = randi([1, universeSize], numHashFunctions, 1);
    b = randi([1, universeSize], numHashFunctions, 1);
    hashFunctions = @(x, h) mod(a(h) * x + b(h), universeSize);
    
    %Preenche a matriz usando minHash
    for i = 1:numTransactions
        %Encontra os índices dos shingles presentes na transação
        elements = find(ismember(shingles, transactions{i}));
        for h = 1:numHashFunctions
            %Aplica a função hash nos shingles da transação e
            %Atualiza a assinatura com o menor valor hash
            hashedValues = hashFunctions(elements, h);
            signatureMatrix(h, i) = min(hashedValues);
        end
    end

    %Calcula a matriz de similaridade Jaccard
    similarity = zeros(numTransactions);
    for i = 1:numTransactions
        for j = i:numTransactions
            if i == j
                similarity(i, j) = 1;           %Similaridade máxima consigo mesmo
            else
                %Calcula o número de vezes em que as signatures das transações i e j são iguais
                numMatches = sum(signatureMatrix(:, i) == signatureMatrix(:, j));

                %Fórmula para calcular a similaridade = (i && j) / (i || j)
                %(i && j) -> Interseção entre as transações, ou seja, quando elas são iguais
                %(i || j) -> Reunião entre as transações, ou seja, o número total de hashFunctions 
                %Porque é o número de casos que se podem comparar as transações
                similarity(i, j) = numMatches / numHashFunctions;
                similarity(j, i) = similarity(i, j);
            end
        end
    end

    %Identifica clusters de transações similares
    clusters = {};
    visited = false(numTransactions, 1);
    for i = 1:numTransactions
        if ~visited(i)
            %Encontra todas as transações que são similares à transação em questão
            %Para ser considerada similar, a similaridade entre as
            %transações tem de ser maior ou igual ao valor definido anteriormente
            cluster = find(similarity(i, :) >= similarityThreshold);
            clusters{end + 1} = cluster;        %Adiciona o cluster à lista de clusters
            visited(cluster) = true;            %Indica que o cluster já foi verificado
        end
    end
end