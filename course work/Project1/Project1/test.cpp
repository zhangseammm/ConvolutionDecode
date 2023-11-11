#define  _CRT_SECURE_NO_WARNINGS
#include<stdio.h>
#include<stdlib.h>
#include<time.h>
#include<math.h>
#include<iostream>
using namespace std;

#define message_length 5000 //the length of message
#define codeword_length 10000 //the length of codeword
float code_rate = (float)message_length / (float)codeword_length;

// channel coefficient
#define pi 3.1415926
double N0, sgm;

//int state_table[...][...];//state table, the size should be defined yourself
int state_num=2;//the number of the state of encoder structure

int message[message_length], codeword[codeword_length];//message and codeword
int re_codeword[codeword_length];//the received codeword
int de_message[message_length];//the decoding message

double tx_symbol[codeword_length][2];//the transmitted symbols
double rx_symbol[codeword_length][2];//the received symbols

//void statetable();
void encoder();
void modulation();
void demodulation();
void channel();
//decode
void hviterbi();
void sviterbi();
void BCJR();

void main()
{
	int i;
	float SNR, start, finish;
	long int bit_error, seq, seq_num;
	double BER;
	double progress;

	//generate state table
	//statetable();

	//random seed
	srand((int)time(0));

	//input the SNR and frame number
	printf("\nEnter start SNR: ");
	scanf("%f", &start);
	printf("\nEnter finish SNR: ");
	scanf("%f", &finish);
	printf("\nPlease input the number of message: ");
	scanf("%d", &seq_num);

	for (SNR = start; SNR <= finish; SNR++)
	{
		//channel noise
		N0 = (1.0 / code_rate) / pow(10.0, (float)(SNR) / 10.0);
		sgm = sqrt(N0 / 2);

		bit_error = 0;

		for (seq = 1; seq <= seq_num; seq++)
		{
			//generate binary message randomly
			/****************
			Pay attention that message is appended by 0 whose number is equal to the state of encoder structure.
			****************/
			for (i = 0; i < message_length - state_num; i++)
			{
				message[i] = rand() % 2;
			}
			for (i = message_length - state_num; i < message_length; i++)
			{
				message[i] = 0;
			}

			/*
			int message_0=0, message_1=0;
			for (i = 0; i < message_length; i++)
			{
				if (message[i] == 0)
					message_0++;
				else
					message_1++;
			}
			cout << "messgae_1=" << message_1 << endl;
			cout << "messgae_0=" << message_0 << endl;
			*/
			

			/*
			cout << "message:";
			for (i = 0; i < message_length; i++)
			{
				cout << message[i];
			}
			cout << endl;
			*/

			//convolutional encoder
			encoder();

			//BPSK modulation
			modulation();

			//AWGN channel
			channel();

			//BPSK demodulation, it's needed in hard-decision Viterbi decoder
			demodulation();

			//convolutional decoder
			hviterbi();
			//sviterbi();
			//BCJR();

			//calculate the number of bit error
			for (i = 0; i < message_length; i++)
			{
				if (message[i] != de_message[i])
					bit_error++;
			}

			progress = (double)(seq * 100) / (double)seq_num;

			//calculate the BER
			BER = (double)bit_error / (double)(message_length*seq);

			//print the intermediate result
			printf("Progress=%2.1f, SNR=%2.1f, Bit Errors=%2.1d, BER=%E\r", progress, SNR, bit_error, BER);
		}

		//calculate the BER
		BER = (double)bit_error / (double)(message_length*seq_num);

		//print the final result
		printf("Progress=%2.1f, SNR=%2.1f, Bit Errors=%2.1d, BER=%E\n", progress, SNR, bit_error, BER);
	}
	system("pause");
}

//void statetable()

void encoder()    //convolution encoder, the input is message[] and the output is codeword[]
{
	int i;
	int current_state = 0;
	int next_state;
	for (i = 0; i < message_length; i++)
	{
		switch (current_state)
		{
		case 0:
			if (message[i] == 0)
			{
				codeword[2 * i] = 0;
				codeword[2 * i + 1] = 0;
				next_state = 0;
			}
			else
			{
				codeword[2 * i] = 1;
				codeword[2 * i + 1] = 1;
				next_state = 2;
			}
			break;
		case 1:
			if (message[i] == 0)
			{
				codeword[2 * i] = 1;
				codeword[2 * i + 1] = 1;
				next_state = 0;
			}
			else
			{
				codeword[2 * i] = 0;
				codeword[2 * i + 1] = 0;
				next_state = 2;
			}
			break;
		case 2:
			if (message[i] == 0)
			{
				codeword[2 * i] = 1;
				codeword[2 * i + 1] = 0;
				next_state = 1;
			}
			else
			{
				codeword[2 * i] = 0;
				codeword[2 * i + 1] = 1;
				next_state = 3;
			}
			break;
		case 3:
			if (message[i] == 0)
			{
				codeword[2 * i] = 0;
				codeword[2 * i + 1] = 1;
				next_state = 1;
			}
			else
			{
				codeword[2 * i] = 1;
				codeword[2 * i + 1] = 0;
				next_state = 3;
			}
			break;
		default:cout << "error\n"; break;
		}
		current_state = next_state;
	}
	/*
	cout << "codeword:";
	for (i = 0; i < codeword_length; i++)
	{
		cout << codeword[i];
	}
	cout <<endl;
	*/

}

void modulation()
{
	//BPSK modulation
	int i;

	//0 is mapped to (1,0) and 1 is mapped tp (-1,0)
	for (i = 0; i < codeword_length; i++)
	{
		tx_symbol[i][0] = -1 * (2 * codeword[i] - 1);
		tx_symbol[i][1] = 0;
	}
}
void channel()
{
	//AWGN channel
	int i, j;
	double u, r, g;

	for (i = 0; i < codeword_length; i++)
	{
		for (j = 0; j < 2; j++)
		{
			u = (float)rand() / (float)RAND_MAX;
			if (u == 1.0)
				u = 0.999999;
			r = sgm * sqrt(2.0*log(1.0 / (1.0 - u)));

			u = (float)rand() / (float)RAND_MAX;
			if (u == 1.0)
				u = 0.999999;
			g = (float)r*cos(2 * pi*u);

			rx_symbol[i][j] = tx_symbol[i][j] + g;
		}
	}
}

void demodulation()
{
	int i;
	double d1, d2;
	for (i = 0; i < codeword_length; i++)
	{
		d1 = (rx_symbol[i][0] - 1)*(rx_symbol[i][0] - 1) + rx_symbol[i][1] * rx_symbol[i][1];
		d2 = (rx_symbol[i][0] + 1)*(rx_symbol[i][0] + 1) + rx_symbol[i][1] * rx_symbol[i][1];
		if (d1 < d2)
			re_codeword[i] = 0;
		else
			re_codeword[i] = 1;
	}
}

//硬判决维特比
void hviterbi()
{
	float branchdis[8][message_length] = { 0 };//分支度量
	float pathdis[4][message_length + 1] = { 0 };//路径度量
	int transitionID[4][message_length] = { 0 };//转移路径
	int r[message_length + 1] = { 0 };//寄存器当前状态
	//计算分支度量(汉明距离）
	for (int i = 0; i < message_length; i++)
	{
		if (re_codeword[2 * i] == 0)
		{
			if (re_codeword[2 * i + 1] == 0)
			{
				branchdis[3][i] = branchdis[0][i] = 0;
				branchdis[2][i] = branchdis[1][i] = 2;
				branchdis[7][i] = branchdis[4][i] = 1;
				branchdis[6][i] = branchdis[5][i] = 1;
			}
			else
			{
				branchdis[3][i] = branchdis[0][i] = 1;
				branchdis[2][i] = branchdis[1][i] = 1;
				branchdis[7][i] = branchdis[4][i] = 2;
				branchdis[6][i] = branchdis[5][i] = 0;
			}
		}
		else
		{
			if (re_codeword[2 * i + 1] == 0)
			{
				branchdis[3][i] = branchdis[0][i] = 1;
				branchdis[2][i] = branchdis[1][i] = 1;
				branchdis[7][i] = branchdis[4][i] = 0;
				branchdis[6][i] = branchdis[5][i] = 2;
			}
			else
			{
				branchdis[3][i] = branchdis[0][i] = 2;
				branchdis[2][i] = branchdis[1][i] = 0;
				branchdis[7][i] = branchdis[4][i] = 1;
				branchdis[6][i] = branchdis[5][i] = 1;
			}
		}
	}

	//计算路径度量
	pathdis[0][1] = branchdis[0][0] + pathdis[0][0];
	pathdis[2][1] = branchdis[1][0] + pathdis[0][0];
	transitionID[0][0] = 1;
	transitionID[2][0] = 2;
	pathdis[0][2] = branchdis[0][1] + pathdis[0][1];
	pathdis[1][2] = branchdis[4][1] + pathdis[2][1];
	transitionID[0][1] = 1;
	transitionID[2][1] = 2;
	pathdis[2][2] = branchdis[2][1] + pathdis[0][1];
	pathdis[3][2] = branchdis[5][1] + pathdis[2][1];
	transitionID[1][1] = 5;
	transitionID[3][1] = 6;

	for (int i = 3; i < message_length - 1; i++)
	{
		if (pathdis[0][i - 1] + branchdis[0][i - 1] < pathdis[1][i - 1] + branchdis[2][i - 1])
		{
			pathdis[0][i] = pathdis[0][i - 1] + branchdis[0][i - 1];
			transitionID[0][i - 1] = 1;
		}
		else
		{
			pathdis[0][i] = pathdis[1][i - 1] + branchdis[2][i - 1];
			transitionID[0][i - 1] = 3;
		}
		if (pathdis[2][i - 1] + branchdis[4][i - 1] < pathdis[3][i - 1] + branchdis[6][i - 1])
		{
			pathdis[1][i] = pathdis[2][i - 1] + branchdis[4][i - 1];
			transitionID[1][i - 1] = 5;
		}
		else
		{
			pathdis[1][i] = pathdis[3][i - 1] + branchdis[6][i - 1];
			transitionID[1][i - 1] = 7;
		}
		if (pathdis[0][i - 1] + branchdis[1][i - 1] < pathdis[1][i - 1] + branchdis[3][i - 1])
		{
			pathdis[2][i] = pathdis[0][i - 1] + branchdis[1][i - 1];
			transitionID[2][i - 1] = 2;
		}
		else
		{
			pathdis[2][i] = pathdis[1][i - 1] + branchdis[3][i - 1];
			transitionID[2][i - 1] = 4;
		}
		if (pathdis[2][i - 1] + branchdis[5][i - 1] < pathdis[3][i - 1] + branchdis[7][i - 1])
		{
			pathdis[3][i] = pathdis[2][i - 1] + branchdis[5][i - 1];
			transitionID[3][i - 1] = 6;
		}
		else
		{
			pathdis[3][i] = pathdis[3][i - 1] + branchdis[7][i - 1];
			transitionID[3][i - 1] = 8;
		}
	}

	if (pathdis[0][message_length - 2] + branchdis[0][message_length - 2] < pathdis[1][message_length - 2] + branchdis[2][message_length - 2])
	{
		pathdis[0][message_length - 1] = pathdis[0][message_length - 2] + branchdis[0][message_length - 2];
		transitionID[0][message_length - 2] = 1;
	}
	else
	{
		pathdis[0][message_length - 1] = pathdis[1][message_length - 2] + branchdis[2][message_length - 2];
		transitionID[0][message_length - 2] = 3;
	}
	if (pathdis[2][message_length - 2] + branchdis[4][message_length - 2] < pathdis[3][message_length - 2] + branchdis[6][message_length - 2])
	{
		pathdis[1][message_length - 1] = pathdis[2][message_length - 2] + branchdis[4][message_length - 2];
		transitionID[1][message_length - 2] = 5;
	}
	else
	{
		pathdis[1][message_length - 1] = pathdis[3][message_length - 2] + branchdis[6][message_length - 2];
		transitionID[1][message_length - 2] = 7;
	}
	if (pathdis[0][message_length - 1] + branchdis[0][message_length - 1] < pathdis[1][message_length - 1] + branchdis[2][message_length - 1])
	{
		pathdis[0][message_length] = pathdis[0][message_length - 1] + branchdis[0][message_length - 1];
		transitionID[0][message_length - 1] = 1;
	}
	else
	{
		pathdis[0][message_length] = pathdis[1][message_length - 1] + branchdis[2][message_length - 1];
		transitionID[0][message_length - 1] = 3;
	}
	//选择路径最小
	r[message_length] = 1;
	for (int i = message_length; i > 0; i--)
	{
		if (r[i] == 1)
		{
			if (transitionID[0][i - 1] == 1)
			{
				de_message[i - 1] = 0;
				r[i - 1] = 1;
			}
			else
			{
				de_message[i - 1] = 0;
				r[i - 1] = 2;
			}
		}
		else if (r[i] == 2)
		{
			if (transitionID[1][i - 1] == 5)
			{
				de_message[i - 1] = 0;
				r[i - 1] = 3;
			}
			else
			{
				de_message[i - 1] = 0;
				r[i - 1] = 4;
			}
		}
		else if (r[i] == 3)
		{
			if (transitionID[2][i - 1] == 2)
			{
				de_message[i - 1] = 1;
				r[i - 1] = 1;
			}
			else
			{
				de_message[i - 1] = 1;
				r[i - 1] = 2;
			}
		}
		else
		{
			if (transitionID[3][i - 1] == 6)
			{
				de_message[i - 1] = 1;
				r[i - 1] = 3;
			}
			else
			{
				de_message[i - 1] = 1;
				r[i - 1] = 4;
			}
		}
	}

}

//软判决维特比
void sviterbi()
{
	float branchdis[8][message_length] = { 0 };//分支度量
	float pathdis[4][message_length + 1] = { 0 };//路径度量
	int transitionID[4][message_length] = { 0 };//转移路径
	int r[message_length + 1] = { 0 };//寄存器当前状态
	//计算分支度量（欧氏距离）
	for (int i = 0; i < message_length; i++)
	{
		branchdis[3][i] = branchdis[0][i] = sqrt((rx_symbol[2 * i][0] - 1) * (rx_symbol[2 * i][0] - 1) + rx_symbol[2 * i][1] * rx_symbol[2 * i][1]) + sqrt((rx_symbol[2 * i + 1][0] - 1) * (rx_symbol[2 * i + 1][0] - 1) + rx_symbol[2 * i + 1][1] * rx_symbol[2 * i + 1][1]);
		branchdis[2][i] = branchdis[1][i] = sqrt((rx_symbol[2 * i][0] + 1) * (rx_symbol[2 * i][0] + 1) + rx_symbol[2 * i][1] * rx_symbol[2 * i][1]) + sqrt((rx_symbol[2 * i + 1][0] + 1) * (rx_symbol[2 * i + 1][0] + 1) + rx_symbol[2 * i + 1][1] * rx_symbol[2 * i + 1][1]);
		branchdis[7][i] = branchdis[4][i] = sqrt((rx_symbol[2 * i][0] + 1) * (rx_symbol[2 * i][0] + 1) + rx_symbol[2 * i][1] * rx_symbol[2 * i][1]) + sqrt((rx_symbol[2 * i + 1][0] - 1) * (rx_symbol[2 * i + 1][0] - 1) + rx_symbol[2 * i + 1][1] * rx_symbol[2 * i + 1][1]);
		branchdis[6][i] = branchdis[5][i] = sqrt((rx_symbol[2 * i][0] - 1) * (rx_symbol[2 * i][0] - 1) + rx_symbol[2 * i][1] * rx_symbol[2 * i][1]) + sqrt((rx_symbol[2 * i + 1][0] + 1) * (rx_symbol[2 * i + 1][0] + 1) + rx_symbol[2 * i + 1][1] * rx_symbol[2 * i + 1][1]);
	}

	//计算路径度量
	pathdis[0][1] = branchdis[0][0] + pathdis[0][0];
	pathdis[2][1] = branchdis[1][0] + pathdis[0][0];
	transitionID[0][0] = 1;
	transitionID[2][0] = 2;
	pathdis[0][2] = branchdis[0][1] + pathdis[0][1];
	pathdis[1][2] = branchdis[4][1] + pathdis[2][1];
	transitionID[0][1] = 1;
	transitionID[2][1] = 2;
	pathdis[2][2] = branchdis[2][1] + pathdis[0][1];
	pathdis[3][2] = branchdis[5][1] + pathdis[2][1];
	transitionID[1][1] = 5;
	transitionID[3][1] = 6;

	for (int i = 3; i < message_length + 1; i++)
	{
		if (pathdis[0][i - 1] + branchdis[0][i - 1] < pathdis[1][i - 1] + branchdis[2][i - 1])
		{
			pathdis[0][i] = pathdis[0][i - 1] + branchdis[0][i - 1];
			transitionID[0][i - 1] = 1;
		}
		else
		{
			pathdis[0][i] = pathdis[1][i - 1] + branchdis[2][i - 1];
			transitionID[0][i - 1] = 3;
		}
		if (pathdis[2][i - 1] + branchdis[4][i - 1] < pathdis[3][i - 1] + branchdis[6][i - 1])
		{
			pathdis[1][i] = pathdis[2][i - 1] + branchdis[4][i - 1];
			transitionID[1][i - 1] = 5;
		}
		else
		{
			pathdis[1][i] = pathdis[3][i - 1] + branchdis[6][i - 1];
			transitionID[1][i - 1] = 7;
		}
		if (pathdis[0][i - 1] + branchdis[1][i - 1] < pathdis[1][i - 1] + branchdis[3][i - 1])
		{
			pathdis[2][i] = pathdis[0][i - 1] + branchdis[1][i - 1];
			transitionID[2][i - 1] = 2;
		}
		else
		{
			pathdis[2][i] = pathdis[1][i - 1] + branchdis[3][i - 1];
			transitionID[2][i - 1] = 4;
		}
		if (pathdis[2][i - 1] + branchdis[5][i - 1] < pathdis[3][i - 1] + branchdis[7][i - 1])
		{
			pathdis[3][i] = pathdis[2][i - 1] + branchdis[5][i - 1];
			transitionID[3][i - 1] = 6;
		}
		else
		{
			pathdis[3][i] = pathdis[3][i - 1] + branchdis[7][i - 1];
			transitionID[3][i - 1] = 8;
		}
	}


	//选择路径最小

	r[message_length] = 1;
	for (int i = message_length; i > 0; i--)
	{
		if (r[i] == 1)
		{
			if (transitionID[0][i - 1] == 1)
			{
				de_message[i - 1] = 0;
				r[i - 1] = 1;
			}
			else
			{
				de_message[i - 1] = 0;
				r[i - 1] = 2;
			}
		}
		else if (r[i] == 2)
		{
			if (transitionID[1][i - 1] == 5)
			{
				de_message[i - 1] = 0;
				r[i - 1] = 3;
			}
			else
			{
				de_message[i - 1] = 0;
				r[i - 1] = 4;
			}
		}
		else if (r[i] == 3)
		{
			if (transitionID[2][i - 1] == 2)
			{
				de_message[i - 1] = 1;
				r[i - 1] = 1;
			}
			else
			{
				de_message[i - 1] = 1;
				r[i - 1] = 2;
			}
		}
		else if (r[i] == 4)
		{
			if (transitionID[3][i - 1] == 6)
			{
				de_message[i - 1] = 1;
				r[i - 1] = 3;
			}
			else
			{
				de_message[i - 1] = 1;
				r[i - 1] = 4;
			}
		}
	}
}

void BCJR()
{
	int i;
	double NA, NB, Np;//normalization factor
	double prob_ch_0[codeword_length];//Pch=0
	double prob_ch_1[codeword_length];//Pch=1
	double trans_prob[message_length][8];//the state transition probabilities
	double beginning_prob[message_length + 1][4];//the probability of each beginning state
	double ending_prob[message_length + 1][4];//the probability of each ending state
	double post_prob[message_length][2];//the posteriori proability of each information bit

	for (i = 0; i < codeword_length; i++)
	{
		prob_ch_0[i] = (exp(-((rx_symbol[i][0] - 1)*(rx_symbol[i][0] - 1) + rx_symbol[i][1] * rx_symbol[i][1]) / N0)) / (sqrt(pi*N0));
		prob_ch_1[i] = (exp(-((rx_symbol[i][0] + 1)*(rx_symbol[i][0] + 1) + rx_symbol[i][1] * rx_symbol[i][1]) / N0)) / (sqrt(pi*N0));
	}
	for (i = 0; i < codeword_length; i = i + 2)//calculate the transition probabilities
	{
			trans_prob[i / 2][0] = 0.5 * prob_ch_0[i] * prob_ch_0[i + 1]; 
			trans_prob[i / 2][1] = 0.5 * prob_ch_1[i] * prob_ch_1[i + 1]; 
			trans_prob[i / 2][2] = 0.5 * prob_ch_1[i] * prob_ch_1[i + 1]; 
			trans_prob[i / 2][3] = 0.5 * prob_ch_0[i] * prob_ch_0[i + 1]; 
			trans_prob[i / 2][4] = 0.5 * prob_ch_1[i] * prob_ch_0[i + 1]; 
			trans_prob[i / 2][5] = 0.5 * prob_ch_0[i] * prob_ch_1[i + 1]; 
			trans_prob[i / 2][6] = 0.5 * prob_ch_0[i] * prob_ch_1[i + 1]; 
			trans_prob[i / 2][7] = 0.5 * prob_ch_1[i] * prob_ch_0[i + 1]; 
	}
	beginning_prob[0][0] = 1;//initialize the beginning state
	beginning_prob[0][1] = 0;
	beginning_prob[0][2] = 0;
	beginning_prob[0][3] = 0;
	for (i = 1; i <= message_length; i++)//calculate the probability of each beginning state
	{
		beginning_prob[i][0] = beginning_prob[i - 1][0] * trans_prob[i - 1][0] + beginning_prob[i - 1][1] * trans_prob[i - 1][2]; //a
		beginning_prob[i][1] = beginning_prob[i - 1][2] * trans_prob[i - 1][4] + beginning_prob[i - 1][3] * trans_prob[i - 1][6]; //b
		beginning_prob[i][2] = beginning_prob[i - 1][0] * trans_prob[i - 1][1] + beginning_prob[i - 1][1] * trans_prob[i - 1][3]; //c
		beginning_prob[i][3] = beginning_prob[i - 1][2] * trans_prob[i - 1][5] + beginning_prob[i - 1][3] * trans_prob[i - 1][7]; //d
		NA = sqrt(beginning_prob[i][0] * beginning_prob[i][0] + beginning_prob[i][1] * beginning_prob[i][1] + beginning_prob[i][2] * beginning_prob[i][2] + beginning_prob[i][3] * beginning_prob[i][3]);//normalize
		beginning_prob[i][0] = beginning_prob[i][0] / NA;
		beginning_prob[i][1] = beginning_prob[i][1] / NA;
		beginning_prob[i][2] = beginning_prob[i][2] / NA;
		beginning_prob[i][3] = beginning_prob[i][3] / NA;
	}
	ending_prob[message_length][0] = 1;//initialize the ending state
	ending_prob[message_length][1] = 0;
	ending_prob[message_length][2] = 0;
	ending_prob[message_length][3] = 0;
	for (i = message_length - 1; i >= 0; i--)//calculate the probability of each ending state
	{
		ending_prob[i][0] = ending_prob[i + 1][0] * trans_prob[i][0] + ending_prob[i + 1][2] * trans_prob[i][1];//a
		ending_prob[i][1] = ending_prob[i + 1][0] * trans_prob[i][2] + ending_prob[i + 1][2] * trans_prob[i][3];//b
		ending_prob[i][2] = ending_prob[i + 1][1] * trans_prob[i][4] + ending_prob[i + 1][3] * trans_prob[i][5];//c
		ending_prob[i][3] = ending_prob[i + 1][1] * trans_prob[i][6] + ending_prob[i + 1][3] * trans_prob[i][7];//d
		NB = sqrt(ending_prob[i][0] * ending_prob[i][0] + ending_prob[i][1] * ending_prob[i][1] + ending_prob[i][2] * ending_prob[i][2] + ending_prob[i][3] * ending_prob[i][3]);//normalize
		ending_prob[i][0] = ending_prob[i][0] / NB;
		ending_prob[i][1] = ending_prob[i][1] / NB;
		ending_prob[i][2] = ending_prob[i][2] / NB;
		ending_prob[i][3] = ending_prob[i][3] / NB;
	}
	for (i = 0; i < message_length; i++)
	{
		post_prob[i][0] = beginning_prob[i][0] * trans_prob[i][0] * ending_prob[i + 1][0] + beginning_prob[i][1] * trans_prob[i][2] * ending_prob[i + 1][0] + beginning_prob[i][2] * trans_prob[i][4] * ending_prob[i + 1][1] + beginning_prob[i][3] * trans_prob[i][6] * ending_prob[i + 1][1];//0
		post_prob[i][1] = beginning_prob[i][0] * trans_prob[i][1] * ending_prob[i + 1][2] + beginning_prob[i][1] * trans_prob[i][3] * ending_prob[i + 1][2] + beginning_prob[i][2] * trans_prob[i][5] * ending_prob[i + 1][3] + beginning_prob[i][3] * trans_prob[i][7] * ending_prob[i + 1][3];//1
		Np = sqrt(post_prob[i][0] * post_prob[i][0] + post_prob[i][1] * post_prob[i][1]);
		post_prob[i][0] = post_prob[i][0] / Np;
		post_prob[i][1] = post_prob[i][1] / Np;
		if (post_prob[i][0] >= post_prob[i][1])
			de_message[i] = 0;
		else
			de_message[i] = 1;
	}
	/*
	cout << "decodeword:";
	for (i = 0; i < message_length; i++)
	{
		cout << de_message[i];
	}
	cout << endl;
	cout << endl;
	*/
}