clear
% close all
clc

%% Parametres
% -------------------------------------------------------------------------
R = 1/2; % Rendement de la communication

pqt_par_trame = 1000; % Nombre de paquets par trame
bit_par_pqt   = 330;% Nombre de bit par paquet
K = pqt_par_trame*bit_par_pqt; % Nombre de bits de message par trame
N = K/R; % Nombre de bits codés par trame (codée)

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

%% Construction de l'objet évaluant le TEB
stat_erreur = comm.ErrorRate(); % Calcul du nombre d'erreur et du BER

%% Initialisation des vecteurs de résultats
ber = zeros(1,length(EbN0dB));
Pe = qfunc(sqrt(2*EbN0));

%% Q1
p1 = [002 003];
p2 = [007 005];
p3 = [013 015];
p4 = [133 171];


%% Préparation de l'affichage
semilogy(EbN0dB,ber,'XDataSource','EbN0dB', 'YDataSource','ber');
hold all
ylim([1e-6 1])
grid on
xlabel('$\frac{E_b}{N_0}$ en dB','Interpreter', 'latex', 'FontSize',14)
ylabel('TEB','Interpreter', 'latex', 'FontSize',14)


%% Préparation de l'affichage en console
msg_format = '|   %7.2f  |   %9d   |  %9d | %2.2e |  %8.2f kO/s |   %8.2f kO/s |   %8.2f s |\n';

%% Simulation
T(1) = poly2trellis(7, p4);
T(2) = poly2trellis(4, p3);
T(3) = poly2trellis(3, p2);
T(4) = poly2trellis(2, p1);
for i = 1:5
    ber = zeros(1,length(EbN0dB));
    fprintf(      '|------------|---------------|------------|----------|----------------|-----------------|--------------|\n')
    msg_header =  '|  Eb/N0 dB  |    Bit nbr    |  Bit err   |   TEB    |    Debit Tx    |     Debit Rx    | Tps restant  |\n';
    fprintf(msg_header);
    fprintf(      '|------------|---------------|------------|----------|----------------|-----------------|--------------|\n')
    if i==5 %% Si on encode pas le message, le rendement est de 1
        R=1;
    end
    if i<5
        H = comm.ConvolutionalEncoder(T(i));
        H.TerminationMethod = 'Terminated';
        V = comm.ViterbiDecoder(T(i));
        V.TerminationMethod = 'Terminated';
        V.TracebackDepth = 50; %% par rapport à la mémoire du code (">5*longueur du code")
        V.InputFormat = 'Unquantized';

    end
    
    for i_snr = 1:length(EbN0dB)
        

        reverseStr = ''; % Pour affichage en console
        awgn_channel.EsNo = EsN0dB(i_snr);% Mise a jour du EbN0 pour le canal
        
        stat_erreur.reset; % reset du compteur d'erreur
        
        err_stat    = [0 0 0]; % vecteur résultat de stat_erreur

        
        demod_psk.Variance = awgn_channel.Variance;
        
        n_frame = 0;
        T_rx = 0;
        T_tx = 0;
        general_tic = tic;
        
        while (err_stat(2) < nbr_erreur && err_stat(3) < nbr_bit_max)
            n_frame = n_frame + 1;
            
            %% Emetteur
            tx_tic = tic;                 % Mesure du débit d'encodage
            msg    = randi([0,1],K,1);    % Génération du message aléatoire
            if(i<5) 
                msg_c = H.step(msg);      % Encodage du message aléatoire
            else
                msg_c = msg;              % Si on encode pas le message (i=5)
            end
            x      = step(mod_psk,  msg_c); % Modulation QPSK
            T_tx   = T_tx+toc(tx_tic);    % Mesure du débit d'encodage
            
            %% Canal
            y     = step(awgn_channel,x); % Ajout d'un bruit gaussien
            
            
            %% Recepteur
            rx_tic = tic;                  % Mesure du débit de décodage
            
            Lc = step(demod_psk,y);   % Démodulation (retourne des LLRs)
            
            if i<5
                rec_msg = V.step(Lc(1:N)); %Decodage de viterbi
            else
                Ldc = double(Lc(1:K) < 0); % Décision
                rec_msg = Ldc;
            end             
          
            T_rx    = T_rx + toc(rx_tic);  % Mesure du débit de décodage
            
            err_stat   = step(stat_erreur, msg, rec_msg); % Comptage des erreurs binaires
            
            %% Affichage du résultat
            if mod(n_frame,100) == 1
                msgg = sprintf(msg_format,...
                    EbN0dB(i_snr),         ... % EbN0 en dB
                    err_stat(3),           ... % Nombre de bits envoyés
                    err_stat(2),           ... % Nombre d'erreurs observées
                    err_stat(1),           ... % BER
                    err_stat(3)/8/T_tx/1e3,... % Débit d'encodage
                    err_stat(3)/8/T_rx/1e3,... % Débit de d�codage
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


legend('Non cod�', '(133, 171)_{8}', '(13, 15)_8', '(7, 5)_8', '(2, 3)_{8}')
xlim([-2 13])
ylim([1e-6 1])

save('NC.mat','EbN0dB','ber')
