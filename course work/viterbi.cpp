/***************************************************
Channel Coding Course Work: conolutional codes
This program template has given the message generator, BPSK modulation, AWGN channel model and BPSK demodulation,
you should first determine the encoder structure, then define the message and codeword length, generate the state table, write the convolutional encoder and decoder.

If you have any question, please contact me via e-mail: wuchy28@mail2.sysu.edu.cn
***************************************************/

#define  _CRT_SECURE_NO_WARNINGS
#include<stdio.h>
#include<stdlib.h>
#include<time.h>
#include<math.h>

#define message_length 1000000 //the length of message
#define codeword_length 2000000 //the length of codeword
float code_rate = (float)message_length / (float)codeword_length;

// channel coefficient
#define pi 3.1415926
double N0, sgm;

int state_table[2][2];//state table, the size should be defined yourself
int state_num=2;//the number of the state of encoder structure

int message[message_length], codeword[codeword_length];//message and codeword
int re_codeword[codeword_length];//the received codeword
int de_message[message_length];//the decoding message

double tx_symbol[codeword_length][2];//the transmitted symbols
double rx_symbol[codeword_length][2];//the received symbols

float branchdis[8][message_length] = { 0 };//分支度量
float pathdis[4][message_length + 1] = { 0 };//路径度量
int transitionID[4][message_length] = { 0 };//转移路径
int r[message_length + 1] = { 0 };//寄存器当前状态

void hviterbi();
void sviterbi();
void statetable();
void encoder();
void modulation();
void demodulation();
void channel();
void decoder();

void main()
{
	int i;
	float SNR, start, finish;
	long int bit_error, seq, seq_num;
	double BER;
	double progress;

	//generate state table
	statetable();

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

			//convolutional encoder
			encoder();

			//BPSK modulation
			modulation();

			//AWGN channel
			channel();

			//BPSK demodulation, it's needed in hard-decision Viterbi decoder
			//demodulation();

			//convolutional decoder
			decoder();

			//calculate the number of bit error
			for (i = 0; i < message_length; i++)
			{
				if (message[i] != de_message[i])
					bit_error++;
			}

			progress = (double)(seq * 100) / (double)seq_num;

			//calculate the BER
			BER = (double)bit_error / (double)(message_length * seq);

			//print the intermediate result
			printf("Progress=%2.1f, SNR=%2.1f, Bit Errors=%2.1d, BER=%E\r", progress, SNR, bit_error, BER);
		}

		//calculate the BER
		BER = (double)bit_error / (double)(message_length * seq_num);

		//print the final result
		printf("Progress=%2.1f, SNR=%2.1f, Bit Errors=%2.1d, BER=%E\n", progress, SNR, bit_error, BER);
	}
	system("pause");
}
void statetable()
{

}

void encoder()
{
	//convolution encoder, the input is message[] and the output is codeword[]
	int r1 = 0;
	int r2 = 0;
	for (int i = 0; i < message_length; i++)
	{
		codeword[2 * i] = message[i] ^ r1 ^ r2;
		codeword[2 * i + 1] = message[i] ^ r2;
		r2 = r1;
		r1 = message[i];
	}
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
			r = sgm * sqrt(2.0 * log(1.0 / (1.0 - u)));

			u = (float)rand() / (float)RAND_MAX;
			if (u == 1.0)
				u = 0.999999;
			g = (float)r * cos(2 * pi * u);

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
		d1 = (rx_symbol[i][0] - 1) * (rx_symbol[i][0] - 1) + rx_symbol[i][1] * rx_symbol[i][1];
		d2 = (rx_symbol[i][0] + 1) * (rx_symbol[i][0] + 1) + rx_symbol[i][1] * rx_symbol[i][1];
		if (d1 < d2)
			re_codeword[i] = 0;
		else
			re_codeword[i] = 1;
	}
}
void decoder()
{
	sviterbi();
}
//硬判决维特比
void hviterbi()
{
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