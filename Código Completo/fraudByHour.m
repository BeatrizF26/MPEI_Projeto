function fraudByHour(data)
    %Função que calcula e apresenta num gráfico as transações fraudulentas que existem por hora do dia

    %Considera apenas a hora das transações fraudulentas
    fraudHours = data.trans_hour(data.is_fraud == 1);

    %Conta o número de fraudes por hora
    numHours = 0:23;
    fraudCounts = histcounts(fraudHours, [numHours, 24]);

    %Identifica a hora com maior número de fraudes
    [maxFraudCount, maxFraudHour] = max(fraudCounts);

    %Gráfico com o número de fraudes realizadas por cada hora do dia
    figure;
    bar(numHours, fraudCounts, 'FaceColor', 'r');
    title('Frequência de Fraudes por Hora do Dia');
    xlabel('Hora do Dia');
    ylabel('Número de Fraudes');
    xticks(numHours);   %Coloca o número da hora por baixo de cada barra
    grid on;
end
