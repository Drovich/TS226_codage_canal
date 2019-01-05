function [] =  print_tab_recap(poly,memoire, nb_msg, Gain,Debit)
% 
msg_format = '|[%3d %3d]|  %20d |  %19d |  %14d |   %15d | %17d | %16d | %19d | \n';
fprintf(      '|---------|-----------------------|----------------------|-----------------|-------------------|-------------------|------------------|---------------------| \n')
msg_header =  '|  Poly.  | Rend. treillis ouvert | Rend. treillis ferme |     memoire     |     nb. états     | distance minimale |  gain de codage  |  debit sort recpt.  | \n';
fprintf(msg_header);


for i = 1:length(poly)
    reverseStr = ''; % Pour affichage en console
    poly2trellis(memoire(i), poly(i,:));
    T = poly2trellis(memoire(i), poly(i,:));
    T = poly2trellis(memoire(i), poly(i,:));
    m=distspec(T);
    msgg = sprintf(msg_format,...
        poly(i,1),         ... % Polynome
        poly(i,2),           ... % Polynome
        1/size(poly, 2),           ... % Rend. treillis ouvert
        nb_msg/(size(poly, 2)*nb_msg+memoire(i)*size(poly, 2)),... % Rend. treillis femer
        memoire(i),... % memoire
        2^memoire(i),... % nb. états
        m.dfree,...
        Gain(i),...
        Debit(i)); % distance minimale
    fprintf(reverseStr);
    msg_sz =  fprintf(msgg);
    reverseStr = repmat(sprintf('\b'), 1, msg_sz);
%       fprintf('Gain du code %d\n', Gain(length(Gain))-Gain(i));
%     fprintf('Debit de sortie du code %d\n', Debit(i));
    fprintf('|--------- ----------------------- ---------------------- ----------------- ------------------- ------------------- ------------------ ---------------------|\n')
    
end


