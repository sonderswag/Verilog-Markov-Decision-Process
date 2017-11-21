#include <cmath> 
#include <vector> 
#include <string> 
#include <iostream>


using namespace std; 

int main (int argc, char*argv[])
{
	char *binary = argv[1];
	int sum_e =0; 
	float sum_total; 
	for (int i=0; i < 5; i++)
	{
		if (binary[5-i] == '1') 
		{
			sum_e += pow(2,i); 
		}
	} 	
	sum_e -= 15; 
	if (sum_e <= 0 )
	{
		sum_e += -1; 
	}
	sum_total = pow(2,1+sum_e);

	for (int i = 6; i <= 15 ; i++)
	{
		if (binary[i] == '1')
		{	
			sum_total += pow(2,-i+6+sum_e);
		}
	}
	if (binary[0] == '1')
	{
		sum_total = sum_total*-1; 
	}

	cout << sum_total << endl; 

	return 0;
}