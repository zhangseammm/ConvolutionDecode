#define pi 3.1415926
#define message_length ... //the length of message
#define codeword_length ... //the length of codeword
float code_rate = (float)message_length / (float)codeword_length;

double N0;
int re_codeword[codeword_length];//the received codeword
int de_message[message_length];//the decoding message
int de_message[message_length];//the decoding message
double tx_symbol[codeword_length][2];//the transmitted symbols
double rx_symbol[codeword_length][2];//the received symbols



void BCJR()
{
	int i, j;
	int NA, NB, Np;//normalization factor
	double prob_ch_0[codeword_length];//Pch=0
	double prob_ch_1[codeword_length];//Pch=1
	double trans_prob[message_length][8];//the state transition probabilities
	double beginning_prob[message_length + 1][4];//the probability of each beginning state
	double ending_prob[message_length + 1][4];//the probability of each ending state
	double post_prob[message_length][2];//the posteriori proability of each information bit

	for (i = 0; i < codeword_length; i++)
	{
		prob_ch_0[i] = (exp(-(rx_symbol[i][0] - 1)*(rx_symbol[i][0] - 1) / N0)) / (sqrt(pi*N0));
		prob_ch_1[i] = (exp(-(rx_symbol[i][0] + 1)*(rx_symbol[i][0] + 1) / N0)) / (sqrt(pi*N0));
	}
	for (i = 0; i < codeword_length; i = i + 2)//calculate the transition probabilities
	{
		for (j = 0; j < 8; j++)
		{
			switch (j)
			{
			case 0:trans_prob[i / 2][j] = 0.5 * prob_ch_0[i] * prob_ch_0[i + 1]; break;
			case 1:trans_prob[i / 2][j] = 0.5 * prob_ch_1[i] * prob_ch_1[i + 1]; break;
			case 2:trans_prob[i / 2][j] = 0.5 * prob_ch_1[i] * prob_ch_1[i + 1]; break;
			case 3:trans_prob[i / 2][j] = 0.5 * prob_ch_0[i] * prob_ch_0[i + 1]; break;
			case 4:trans_prob[i / 2][j] = 0.5 * prob_ch_1[i] * prob_ch_0[i + 1]; break;
			case 5:trans_prob[i / 2][j] = 0.5 * prob_ch_0[i] * prob_ch_1[i + 1]; break;
			case 6:trans_prob[i / 2][j] = 0.5 * prob_ch_0[i] * prob_ch_1[i + 1]; break;
			case 7:trans_prob[i / 2][j] = 0.5 * prob_ch_1[i] * prob_ch_0[i + 1]; break;
			}
		}
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
		ending_prob[i][2] = ending_prob[i + 1][1] * trans_prob[i][4] + ending_prob[i + 1][1] * trans_prob[i][5];//c
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
	for (i = 0; i < message_length; i++)
		cout << de_message[i];
}