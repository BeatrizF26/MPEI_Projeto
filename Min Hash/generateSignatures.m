function [signatures] = generateSignatures(shingles, numHashFunctions, hashFunctions)
%Função que gera as assinaturas minHash para os shingles
%Shingles -> Conjunto de shingles
%numHashFunctions -> Número de funções hash que se são usadas
%hashFunctions -> Funções hash que se quer utilizar

    signatures = zeros(length(shingles), numHashFunctions);
    for i = 1:numHashFunctions
        %Calcula os valores hash em cada uma das funções hash para cada shingle
        %Esses valores são colocados num array onde vão estar todas as signatures
        hashValues = arrayfun(@(shingle) hashFunctions{i}(cellstr(shingle)), shingles);
        signatures(:, i) = hashValues;
    end
end
