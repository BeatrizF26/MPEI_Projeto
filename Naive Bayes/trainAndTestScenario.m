function [Ytest_scenario, yPred_scenario] = trainAndTestScenario(data, validColumns, holdOutPercent)
%Função que treina e testa o classificador Naive Bayes consoante os
%Diferentes valores da percentagem de linhas que é para ser considerada como treino e, consequentemente, teste
%data -> Toda a informação que vem do dataset
%validColumns -> Indica quais são as colunas válidas para se conseguir executar o classificador
%holdOutPercent -> Percentagem que indica o número de linhas que  se quer considerar para teste
    
    %A matriz X é composta por todas as linhas das colunas válidas (categóricas ou numéricas)
    %A matriz Y é onde se encontram os valores para verificar se as transações são fraudes ou não
    X = table2array(data(:, validColumns));
    Y = data.is_fraud;
    
    %Vai fazer com que os resultados da matriz de confusão sejam sempre
    %Diferentes uma vez que gera aleatoriamente a partição do dataset, apenas tem a percentagem
    cv = cvpartition(height(data), 'HoldOut', holdOutPercent);
    Xtrain = X(training(cv), :);
    Ytrain = Y(training(cv), :);
    Xtest = X(test(cv), :);
    Ytest_scenario = Y(test(cv), :);
    
    %Remove colunas onde todas as linhas de uma coluna tenham resultados idênticos,
    %Ou seja, a variância é 0 porque as variáveis não variam
    colsToRemove = false(1, size(Xtrain, 2));
    for i = 1:size(Xtrain, 2)
        class0Var = var(Xtrain(Ytrain == 0, i));
        class1Var = var(Xtrain(Ytrain == 1, i));
        if class0Var == 0 || class1Var == 0
            colsToRemove(i) = true;
        end
    end
    
    %As matrizes de teste e de treino passam a não contar com essas colunas
    Xtrain(:, colsToRemove) = [];
    Xtest(:, colsToRemove) = [];
    
    [NBModel, yPred_scenario, accuracy, precision, recall, f1Score] = naiveBayesClassifier(Xtrain, Ytrain, Xtest, Ytest_scenario);
    
    %Exibição dos resultados
    fprintf("Resultados com %.0f%% treino:\n", (1 - holdOutPercent)*100);
    fprintf("Exatidão: %.4f\n", accuracy);
    fprintf("Precisão: %.4f\n", precision);
    fprintf("Recall: %.4f\n", recall);
    fprintf("F1-Score: %.4f\n\n", f1Score);
end