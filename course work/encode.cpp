#include<iostream>
#include<string>
using namespace std;
#define message_length 8 //the length of message
#define codeword_length 16 //the length of codeword
int message[message_length], codeword[codeword_length];//message and codeword
int state_num;//the number of the state of encoder structure

int main()
{
	int i;
	for (i = 0; i < message_length; i++)
	{
		cin >> message[i];
	}
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
	for (i = 0; i < codeword_length; i++)
	{
		cout << codeword[i];
	}
	return 0;
}
