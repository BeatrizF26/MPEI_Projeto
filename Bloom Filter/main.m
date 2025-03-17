%Parâmetros do Bloom Filter
m = 1e6;            %Tamanho do vetor de bits
k = 3;              %Número de funções hash

%Lê o dataset
data = readtable("fraudData.xlsx");

%Seleciona as colunas necessárias para o filtro (número do cartão, merchant e categoria do produto)
if all(ismember({'cc_num', 'merchant', 'category'}, data.Properties.VariableNames))
    fraudulentTransactions = [string(data.cc_num), string(data.merchant), string(data.category)];
else
    error("As colunas necessárias ('cc_num', 'merchant', 'category') não estão no dataset.");
end

%Seleciona as transações consideradas fraudes,
%Para apenas elas serem utilizadas no bloom filter
fraudulent = data.is_fraud == 1;
fraudulentTransactions = fraudulentTransactions(fraudulent, :);

%Seleciona-se uma transação aleatória de teste
transactionIndex = randi(height(data));
testTransaction = [string(data.cc_num(transactionIndex)), string(data.merchant(transactionIndex)), string(data.category(transactionIndex))];

%Chama a função buildBloomFilter para avaliar se a transação de teste foi fraudulenta ou não
[bloomFilter, isFraudulent] = buildBloomFilter(fraudulentTransactions, testTransaction, m, k);

if isFraudulent
    fprintf("A transação de teste foi identificada como potencialmente fraudulenta.\n");
else
    fprintf("A transação de teste foi identificada como não fraudulenta.\n");
end

%Criar ficheiro com as variáveis mais importantes do Bloom Filter
diretorioAtual = pwd;
diretorioAnterior = fullfile(diretorioAtual, '..');
nomeFicheiro = "dados.mat";
diretorioFicheiro = fullfile(diretorioAnterior, nomeFicheiro);

save(diretorioFicheiro, "fraudulentTransactions", "fraudulent", ...
    "bloomFilter", '-append');

