x1=0:1:9;
y1=[1.97E-01	1.30E-01	7.24E-02	3.22E-02	1.15E-02	3.17E-03	6.70E-04	9.15E-05	1.00E-05	1.00E-06];
semilogy(x1,y1,'-o');
xlabel('SNR(dB)');
ylabel('BER');
xlim([0 10]);
hold on;
x2=0:1:7;
y2=[1.08E-01,5.12E-02	,1.83E-02,	4.62E-03	,8.31E-04	,1.08E-04	,9.30E-06,	7.00E-07 ];
semilogy(x2,y2,'-+');
hold on;
x3=0:1:7;
y3=[8.80E-02	4.03E-02	1.39E-02	3.48E-03	6.26E-04	8.71E-05	9.10E-06	1.00E-07];
semilogy(x3,y3,'-*');
legend('Hard-Viterbi','Soft-Viterbi','BCJR');
