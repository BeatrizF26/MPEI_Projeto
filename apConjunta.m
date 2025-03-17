%Carrega os dados importados do classificador Naive Bayes, Bloom Filter e minHash
load("dados.mat");

%O utilizador insere a sua própria transação
fprintf("Introduz uma transação para avaliar se é fraude ou não\n");

%Inicialmente é pedido o número do cartão, merchant e a categoria da compra
%Para verificar logo se a trasação está no bloom filter
fprintf("Credit Card Number: ");
cc_num = input('', 's');

fprintf("Merchant: ");
merchant = input('', 's');

fprintf("Category: ");
category = input('', 's');

testTransaction = {cc_num, merchant, category};

%Compara a transação definida pelo utilizador com cada uma das transações fraudulentas que está no bloom filter
%Se a transação estiver no filtro, então o programa termina imediatamente para indicar que é uma fraude
foundFraud = false;
for i = 1:size(fraudulentTransactions, 1)
    if isequal(fraudulentTransactions{i, 1}, testTransaction{1}) && ...
       isequal(fraudulentTransactions{i, 2}, testTransaction{2}) && ...
       isequal(fraudulentTransactions{i, 3}, testTransaction{3})
        foundFraud = true;
        break;
    end
end

if foundFraud
    fprintf("Essa transação é considerada fraudulenta segundo o Bloom Filter.\n");
    return;
end

%Se não for uma fraude, invoca-se a função detailsTransaction que vai continuar a pedir informações ao utilizador sobre a transação
testTransaction = detailsTransaction(cc_num, merchant,category);

%Quando todos os parâmetros da transação estiverem definidos,
%O classificador Naive Bayes vai fazer a sua previsão para ver se a transação vai ser uma fraude ou não
fraudPrediction = predict(NBModel, testTransaction);

%Caso seja uma fraude, o programa acaba com uma mensagem a indicar que a transação é fraudulenta
if fraudPrediction == 1
    fprintf("A transação é considerada fraudulenta segundo o classificador Naive Bayes.\n");
    return;
end

%No minHash, para criar o shingle, é preciso ter acesso ao valor da compra,
%Além do número do cartão, do merchant e da categoria da compra (São as condições do minHash que desenvolvemos)
amt = testTransaction(5);
testShingle = cc_num + "    " + merchant + "    " + category + "    " + amt;

%Vai haver três signatures porque são utilizadas 3 funções hash
%Cada signature é o valor de uma das funções hash
testSignature = zeros(1, 3);
for i = 1:3
    testSignature(i) = hashFunctions{i}(testShingle);
end

%Se a transação for similar a algum cluster fraudulento, ou seja,
%Se o valor da similare for maior ou igual ao limite, a transação é considerada fraudulenta
%E o programa termina com uma mensagem a indicar isso precisamente
foundFraud = false;
for i = 1:length(fraudClusters)
    similarity = sum(testSignature == fraudClusters{i}) / length(fraudClusters{i});
    
    if similarity >= similarityThreshold
        foundFraud = true;
        fprintf("Essa transação é considerada fraudulenta segundo o MinHash.\n");
        return;
    end
end

%Se em nenhum dos três módulos a transação for dada como fraudulenta,
%Então é porque é uma transação legítima e não existe nenhum problema
fprintf("Essa transação não é fraudulenta\n");
