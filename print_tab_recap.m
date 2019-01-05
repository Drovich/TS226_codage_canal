function [] = print_tab_recap(poly,memoire, nb_msg)
% 
% msg_format = '|   %7.2f %9d  |  %9d |  %2.2e |  %8.2f |   %8.2f |  \n';
% fprintf(      '|------------|---------------|------------|----------|----------------|-----------------|--------------|\n')
% msg_header =  '|  Poly  |    Rend. treillis ouvert   |  Rend. treillis overt   |   memoire    |    nb. états    |     distance minimale | \n';
% fprintf(msg_header);
% reverseStr = ''; % Pour affichage en console
for i = 1:length(poly)
    poly2trellis(memoire(i), poly(i,:));
    T = poly2trellis(memoire(i), poly(i,:));
    %     m=distspec(T);
    %     msg = sprintf(msg_format,poly(i,1),poly(i,2), 1/size(poly, 2), nb_msg/(size(poly, 2)*nb_msg+memoire(i)*size(poly, 2)),  memoire(i), 2^memoire(i), m.dfree);
    %     fprintf(reverseStr);
    %     msg_sz =  fprintf(msg);
    %     reverseStr = repmat(sprintf('\b'), 1, msg_sz);
    %     drawnow limitrate
    
    fprintf('Polynôme : [%d   %d] : \n',poly(i,1),poly(i,2));
    fprintf('Rendement treillis ouvert : %d\n', 1/size(poly, 2));
    fprintf('Rendement treillis fermer : %d\n', nb_msg/(size(poly, 2)*nb_msg+memoire(i)*size(poly, 2)));
    fprintf('Memoire du code %d\n', memoire(i));
    fprintf('Nb d états du code %d\n', 2^memoire(i));
    T = poly2trellis(memoire(i), poly(i,:));
    m=distspec(T);
    fprintf('Distance minimale du code %d\n', m.dfree);
    fprintf('|------------ --------------- ------------ ---------- ---------------- ----------------- --------------|\n')

end


