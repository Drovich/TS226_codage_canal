clear
close all
clc

%% Parametres
% -------------------------------------------------------------------------
R = 1/2; % Rendement de la communication

pqt_par_trame = 100; % Nombre de paquets par trame
bit_par_pqt   = 330;% Nombre de bit par paquet
K = pqt_par_trame*bit_par_pqt; % Nombre de bits de message par trame
N = K/R; % Nombre de bits cod�s par trame (cod�e)

M = 2; % Modulation BPSK <=> 2 symboles
phi0 = 0; % Offset de phase our la BPSK

EbN0dB_min  = -2; % Minimum de EbN0
EbN0dB_max  = 13; % Maximum de EbN0
EbN0dB_step = 1;% Pas de EbN0

nbr_erreur  = 100;  % Nombre d'erreurs à observer avant de calculer un BER
nbr_bit_max = 100e6;% Nombre de bits max à simuler
ber_min     = 7e-6; % BER min
ber_min     = 3e-5; % BER min

EbN0dB = EbN0dB_min:EbN0dB_step:EbN0dB_max;     % Points de EbN0 en dB à simuler
EbN0   = 10.^(EbN0dB/10);% Points de EbN0 à simuler
EsN0   = R*log2(M)*EbN0; % Points de EsN0
EsN0dB = 10*log10(EsN0); % Points de EsN0 en dB à simuler

% -------------------------------------------------------------------------

%% Construction du modulateur
mod_psk = comm.PSKModulator(...
    'ModulationOrder', M, ... % BPSK
    'PhaseOffset'    , phi0, ...
    'SymbolMapping'  , 'Gray',...
    'BitInput'       , true);

%% Construction du demodulateur
demod_psk = comm.PSKDemodulator(...
    'ModulationOrder', M, ...
    'PhaseOffset'    , phi0, ...
    'SymbolMapping'  , 'Gray',...
    'BitOutput'      , true,...
    'DecisionMethod' , 'Log-likelihood ratio');

%% Construction du canal AWGN
awgn_channel = comm.AWGNChannel(...
    'NoiseMethod', 'Signal to noise ratio (Es/No)',...
    'EsNo',EsN0dB(1),...
    'SignalPower',1);

%% Construction de l'objet �valuant le TEB
stat_erreur = comm.ErrorRate(); % Calcul du nombre d'erreur et du BER

%% Initialisation des vecteurs de r�sultats
ber = zeros(1,length(EbN0dB));
Pe = qfunc(sqrt(2*EbN0));

%% Q1
p = [007 005];
T = poly2trellis(3, p,7);

H = comm.ConvolutionalEncoder(T);
H.TerminationMethod = 'Terminated';

inter = comm.MatrixInterleaver('NumRows',bit_par_pqt,'NumColumns',pqt_par_trame);
deinter = comm.MatrixDeinterleaver('NumRows',bit_par_pqt,'NumColumns',pqt_par_trame);

%% Pr�paration de l'affichage
semilogy(EbN0dB,ber,'XDataSource','EbN0dB', 'YDataSource','ber');
hold all
ylim([1e-6 1])
grid on
xlabel('$\frac{E_b}{N_0}$ en dB','Interpreter', 'latex', 'FontSize',14)
ylabel('TEB','Interpreter', 'latex', 'FontSize',14)


%% Pr�paration de l'affichage en console
msg_format = '|   %7.2f  |   %9d   |  %9d | %2.2e |  %8.2f kO/s |   %8.2f kO/s |   %8.2f s |\n';

%% Simulation
for i = 1:5
    ber = zeros(1,length(EbN0dB));
    fprintf(      '|------------|---------------|------------|----------|----------------|-----------------|--------------|\n')
    msg_header =  '|  Eb/N0 dB  |    Bit nbr    |  Bit err   |   TEB    |    Debit Tx    |     Debit Rx    | Tps restant  |\n';
    fprintf(msg_header);
    fprintf(      '|------------|---------------|------------|----------|----------------|-----------------|--------------|\n')
    
    
    
    for i_snr = 1:length(EbN0dB)    
        
        reverseStr = ''; % Pour affichage en console
        awgn_channel.EsNo = EsN0dB(i_snr);% Mise a jour du EbN0 pour le canal
        
        stat_erreur.reset; % reset du compteur d'erreur
        
        err_stat    = [0 0 0]; % vecteur r�sultat de stat_erreur
        
        
        demod_psk.Variance = awgn_channel.Variance;
        
        n_frame = 0;
        T_rx = 0;
        T_tx = 0;
        general_tic = tic;
        
        while (err_stat(2) < nbr_erreur && err_stat(3) < nbr_bit_max)
            n_frame = n_frame + 1;
            
            %% Emetteur
            tx_tic = tic;
            un = randi([0,1],K,1);    % G�n�ration du message al�atoire
            un_entr = step(inter,un); % Entrelacement
            
            msg_entre_c = H.step(un_entr);
            msg_c = H.step(un);          % Encodage du message
            
            pn = msg_entre_c(2:2:end); % Extraction des valeurs d'indice pair
            qn = msg_c(2:2:end); % Idem
            
            %Utile pour le poinconage https://tel.archives-ouvertes.fr/tel-00487330/document
            x      = step(mod_psk,  msg_c); % Modulation QPSK
            T_tx   = T_tx+toc(tx_tic);    % Mesure du d�bit d'encodage
            
            %% Canal
            y     = step(awgn_channel,x); % Ajout d'un bruit gaussien
            
            
            %% Recepteur
            rx_tic = tic;                  % Mesure du d�bit de d�codage
            
            Lc = step(demod_psk,y);        % D�modulation (retourne des LLRs)
            
            rec_msg = V.step(Lc); %Decodage de viterbi            
            
            rec_msg_entre = step(deinter,rec_msg(1:378*pqt_par_trame));       % D�entrelacement
            rec_msg = step(RSdec,rec_msg_entre);
            
            T_rx    = T_rx + toc(rx_tic);  % Mesure du d�bit de d�codage
            
            err_stat   = step(stat_erreur, msg, rec_msg); % Comptage des erreurs binaires
            
            %% Affichage du r�sultat
            if mod(n_frame,100) == 1
                msgg = sprintf(msg_format,...
                    EbN0dB(i_snr),         ... % EbN0 en dB
                    err_stat(3),           ... % Nombre de bits envoy�s
                    err_stat(2),           ... % Nombre d'erreurs observ�es
                    err_stat(1),           ... % BER
                    err_stat(3)/8/T_tx/1e3,... % D�bit d'encodage
                    err_stat(3)/8/T_rx/1e3,... % D�bit de d�codage
                    toc(general_tic)*(nbr_erreur - min(err_stat(2),nbr_erreur))/nbr_erreur); % Temps restant
                fprintf(reverseStr);
                msg_sz =  fprintf(msgg);
                reverseStr = repmat(sprintf('\b'), 1, msg_sz);
            end
            
        end
        
        msgg = sprintf(msg_format,EbN0dB(i_snr), err_stat(3), err_stat(2), err_stat(1), err_stat(3)/8/T_tx/1e3, err_stat(3)/8/T_rx/1e3, toc(general_tic)*(100 - min(err_stat(2),100))/100);
        fprintf(reverseStr);
        msg_sz =  fprintf(msgg);
        reverseStr = repmat(sprintf('\b'), 1, msg_sz);
        
        ber(i_snr) = err_stat(1);
        drawnow limitrate
        
        if err_stat(1) < ber_min
            break
        end

    end
    [ok Gain(i)]=min(ber);
    Debit(i) = err_stat(3)/8/T_rx/1e3;
    semilogy(EbN0dB,ber,'XDataSource','EbN0dB', 'YDataSource','ber');
end
fprintf('|------------|---------------|------------|----------|----------------|-----------------|--------------|\n')

%%
print_tab_recap([p1; p2 ; p3; p4],[2 3 4 7],K,Gain,Debit);


legend('TEB (non code)', '(133, 171)_{8}', '(13, 15)', '(7, 5)', '(2, 3)_{8}')
xlim([-2 13])
ylim([1e-6 1])

save('NC.mat','EbN0dB','ber')
