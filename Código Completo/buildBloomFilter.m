function [bloomFilter, isFraudulent] = buildBloomFilter(fraudulentTransactions, testTransaction, m, k)
%Função responsável pela implementação do Bloom Filter
%fraudulentTransactions: Matriz com as características de transações fraudulentas
%testTransaction: Características da transação a ser verificada
%m: Tamanho do vetor de bits
%k: Número de funções hash

    %Inicialização do vetor de bits onde os valores iniciais são todos considerados falsos
    bloomFilter = false(1, m);

    %Funções hash para converter as características em valores numéricos no vetor de bits
    hashFunctions = {@(x) mod(abs(sum(double(char(x))) + 31), m) + 1, ...
                     @(x) mod(abs(sum(double(char(x))) * 17 + 7), m) + 1, ...
                     @(x) mod(abs(prod(double(char(x))) + 53), m) + 1};

    %Adicionar transações fraudulentas ao Bloom Filter
    for i = 1:size(fraudulentTransactions, 1)
        transactionStr = strjoin(fraudulentTransactions(i, :), '-');
        for j = 1:k
            idx = hashFunctions{j}(transactionStr);
            bloomFilter(idx) = true;
        end
    end

    %Converte a transação de teste numa string
    testTransactionStr = strjoin(testTransaction, '-');
    fprintf("----Transação a ser analisada----\n" + ...
        "Número do Cartão    ID Merchant    ID Categoria\n%s\n", testTransactionStr);

    %Verifica se a transação de teste é fraudulenta
    %Se a transação já se encontrar no bloom filter, vai ser considerada fraudulenta 
    isFraudulent = true;
    for j = 1:k
        idx = hashFunctions{j}(testTransactionStr);
        if ~bloomFilter(idx)
            isFraudulent = false;
            break;
        end
    end
end
