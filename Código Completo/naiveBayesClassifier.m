function [NBModel, yPredictions, accuracy, precision, recall, f1Score] = naiveBayesClassifier(Xtrain, Ytrain, Xtest, Ytest)
%Função que realiza o classificador de Naive Bayes
%Xtrain -> Matriz de treino com as informações
%Ytrain -> Matriz de treino com os valores correspondentes das fraudes
%Xtest -> Matriz de teste com as informações
%Ytest -> Matriz de teste com os valores correspondentes das fraudes

    %Treina o classificador com a matriz de treino e conclui sobre os
    %Valores da matriz de teste
    try
        NBModel = fitcnb(Xtrain, Ytrain, 'DistributionNames', 'kernel', 'Prior', 'empirical');
    catch ME
        error("Erro ao treinar o modelo Naïve Bayes: %s", ME.message);
    end
    
    yPredictions = predict(NBModel, Xtest);

    %Cálculo da exatidão dos resultados
    accuracy = sum(yPredictions == Ytest) / length(Ytest);

    %Cálculo de verdadeiros positivos, falsos positivos,
    %Falsos negativos e verdadeiros negativos
    TP = sum((yPredictions == 1) & (Ytest == 1));           %Fraude prevista corretamente
    FP = sum((yPredictions == 1) & (Ytest == 0));           %Previsão de fraude, mas não era
    FN = sum((yPredictions == 0) & (Ytest == 1));           %Era fraude, mas não foi previsto
    TN = sum((yPredictions == 0) & (Ytest == 0));           %Não fraude prevista corretamente

    %Cálculo da precisaõ, recall e f1-score, tendo em atenção quando os
    %Denominadores são nulos
    if TP + FP == 0
        precision = 0;
    else
        precision = TP / (TP + FP);
    end

    if TP + FN == 0
        recall = 0;
    else
        recall = TP / (TP + FN);
    end

    if precision + recall == 0
        f1Score = 0;
    else
        f1Score = 2 * (precision * recall) / (precision + recall);
    end
end
