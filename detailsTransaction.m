function testTransaction = detailsTransaction(cc_num, merchant, category)
    %Função que pede os parâmetros da transação que o utilizador quer testar
    %Todos os parâmetros passam de string para double de modo a facilitar a
    %Construção da transação e de teste e facilitar a comparação entre
    %Outras transações no futuro

    fprintf("Date and time of the transfer (yyyy-MM-dd HH:mm:ss): ");
    date_trans_date_time = input('', 's');
    date_trans_hour = hour(datetime(date_trans_date_time, 'InputFormat', 'yyyy-MM-dd HH:mm:ss'));

    fprintf("Amount: ");
    amt = input('', 's'); 
    amt = str2double(amt);  

    fprintf("First Name: ");
    first = input('', 's');
    first = str2double(first);

    fprintf("Last Name: ");
    last = input('', 's'); 
    last = str2double(last); 

    fprintf("Gender (M/F): ");
    gender = input('', 's');
    gender = double(strcmp(gender, 'M'));

    fprintf("Street: ");
    street = input('', 's'); 
    street = str2double(street); 

    fprintf("City: ");
    city = input('', 's'); 
    city = str2double(city); 

    fprintf("State: ");
    state = input('', 's');
    state = str2double(state);

    fprintf("ZIP: ");
    zip_code = input('', 's');
    zip_code = str2double(zip_code);

    fprintf("Latitude: ");
    lat = input('', 's');
    lat = str2double(lat);

    fprintf("Longitude: ");
    lon = input('', 's');
    lon = str2double(lon);

    fprintf("City Pop: ");
    city_pop = input('', 's');
    city_pop = str2double(city_pop);

    fprintf("Job: ");
    job = input('', 's');
    job = str2double(job);

    fprintf("DOB: ");
    dob = input('','s');
    dob = str2double(dob);

    fprintf("Transaction Number: ");
    trans_num = input('', 's');
    trans_num = str2double(trans_num);

    fprintf("Unix Time: ");
    unix_time = input('', 's');
    unix_time = str2double(unix_time);

    fprintf("Merchant Latitude: ");
    merch_lat = input('', 's');
    merch_lat = str2double(merch_lat);

    fprintf("Merchant Longitude: ");
    merch_lon = input('', 's');
    merch_lon = str2double(merch_lon);

    %Cria a transaçao de teste com todos os dados fornecidos
    testTransaction = [date_trans_hour, str2double(cc_num), str2double(merchant), ...
                       str2double(category), amt, first, last, gender, street, city, ...
                       state, zip_code, lat, lon, city_pop, job, dob, trans_num, unix_time, ...
                       merch_lat, merch_lon];
end