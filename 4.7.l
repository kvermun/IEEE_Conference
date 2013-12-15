%{
	int count=1;
	int done;
%}

digit [0-9]
num {digit}{digit}*
id -?{num}
space " "
%%
{id} {fprintf(yyout,"id");}
{space} {}
