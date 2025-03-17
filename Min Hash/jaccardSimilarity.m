function similarity = jaccardSimilarity(signature1, signature2)
%Função que calcula a similaridade de Jaccard entre duas signatures

    intersection = sum(signature1 == signature2);
    union = length(signature1);
    similarity = intersection/union;
end