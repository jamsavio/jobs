//+------------------------------------------------------------------+
//|                                                     expert_2.mq4 |
//|                                                                  |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright ""
#property link      ""
#property version   "1.00"
#property strict

struct set
{
   int    period;   
   double deviation;    
   double win;   
   double loss;   
   int    consecutive_wins;       
   int    consecutive_losses; 
   int    count_entries;
   double aptidao;
   double aptidao_relativa;
};

extern int     historical_bars      = 1000;   
extern int     Pc                   = 70;
extern int     Pm                   = 20;
extern int     period_start         = 20;
extern int     period_step          = 5;
extern int     period_stop          = 50;
extern double  deviation_start      = 2;
extern double  deviation_step       = 1;
extern double  deviation_stop       = 6; 

set melhor_anterior, melhor_atual, populacao[], melhores_ind_epocas[];
int epoca=0;

int OnInit()
{
   PopulacaoInicial();
   Print("Tamanho populacao: "+IntegerToString(ArraySize(populacao)));
   while(melhor_anterior.aptidao < melhor_atual.aptidao){ 
      Backtest();
      Selecao();
      Cruzamento();
      Mutacao();
      epoca++;
   }
   
   for(int i=0, e=1; i<ArraySize(melhores_ind_epocas); i++){
      PrintFormat("e = "+IntegerToString(e)+" | melhor = "+DoubleToString(melhores_ind_epocas[i].aptidao,2));
      e++;
   }
   
   PrintFormat("Melhor SET -> Period: "+IntegerToString(melhor_anterior.period)
                  +" Deviation: "+DoubleToString(melhor_anterior.deviation,2)
                  +" Wins: "+IntegerToString(melhor_anterior.win,2)
                  +" Losses: "+IntegerToString(melhor_anterior.loss,2)
                  +" Loss acumulado: "+IntegerToString(melhor_anterior.consecutive_losses)
                  +" Win acumulado: "+IntegerToString(melhor_anterior.consecutive_wins)
                  +" Entradas: "+IntegerToString(melhor_anterior.count_entries)
                  +" Aptidao: "+DoubleToString(melhor_anterior.aptidao,2)
                  +" Epocas: "+IntegerToString(epoca));
return(0);
}

void PopulacaoInicial(){
   //inicializa aptidao
   melhor_anterior.aptidao=-1;
   melhor_atual.aptidao=0;   
   
   int periodo=period_start;
   double desvio=deviation_start;
   
   int qtd_individuos = ((period_stop-period_start)/period_step)+1;
   ArrayResize(populacao,qtd_individuos);
   
   for(int j=0; j<qtd_individuos; j++){
      //step by step
      populacao[j].consecutive_losses=0;
      populacao[j].consecutive_wins=0;
      populacao[j].count_entries=0;
      populacao[j].loss=0;
      populacao[j].win=0;
      
      if(periodo < period_stop){
         periodo = j==0 ? periodo : periodo+period_step;
         populacao[j].period = periodo;
      }

      if(desvio < deviation_stop){
         desvio = j==0 ? desvio : desvio+deviation_step;
         populacao[j].deviation = desvio;
      }else{
         desvio = deviation_start;
         populacao[j].deviation = desvio;
      }
   }
}

void Backtest(){
   for(int in=0; in<ArraySize(populacao); in++){
      int count_losses=0, count_wins=0;
 
      for(int i=historical_bars; i>=1; i--){
         double banda_inferior = iBands(NULL,0,populacao[in].period,populacao[in].deviation,0,PRICE_OPEN,MODE_LOWER,i+1);
         double banda_superior = iBands(NULL,0,populacao[in].period,populacao[in].deviation,0,PRICE_OPEN,MODE_UPPER,i+1);
         
         //realiza uma call
         if(Low[i+1] < banda_inferior && Close[i+1] > banda_inferior){
            if(Close[i] > Open[i]){
               populacao[in].win+=1;
               count_wins+=1;
               if(count_wins > populacao[in].consecutive_wins) populacao[in].consecutive_wins = count_wins;
               count_losses=0;
            }
            
            else if(Close[i] < Open[i]){
               populacao[in].loss+=1;
               count_losses+=1;
               if(count_losses > populacao[in].consecutive_losses) populacao[in].consecutive_losses = count_losses;
               count_wins=0;
            }
            
            populacao[in].count_entries+=1;
         }
         
         //realiza um put 
         else if(High[i+1] > banda_superior && Close[i+1] < banda_superior){
            if(Close[i] < Open[i]){
               populacao[in].win+=1;
               count_wins+=1;
               if(count_wins > populacao[in].consecutive_wins) populacao[in].consecutive_wins = count_wins;
               count_losses=0;
            }
            
            else if(Close[i] > Open[i]){
               populacao[in].loss+=1;
               count_losses+=1;
               if(count_losses > populacao[in].consecutive_losses) populacao[in].consecutive_losses = count_losses;
               count_wins=0;
            }
            
            populacao[in].count_entries+=1;
         }
         
      }
      
       //Avalia a aptidao do individuo
       double aptidao=populacao[in].win - populacao[in].loss - populacao[in].consecutive_losses;
       
       aptidao = aptidao > 0 ? aptidao + populacao[in].count_entries * 0.035 : aptidao - populacao[in].count_entries;
       
       populacao[in].aptidao=aptidao;
    }
   
   //elitismo
   if(epoca>1){
      if(populacao[PiorAptidao(populacao)].aptidao < melhor_anterior.aptidao){
         populacao[PiorAptidao(populacao)] = melhor_anterior;
      }
   }
    
}

void Selecao(){
   //guarda melhor aptidão atual 
   if(epoca>1) melhor_anterior = melhor_atual;
   melhor_atual = populacao[MelhorAptidao(populacao)];
   //guarda o melhor de cada época para exibir no final
   ArrayResize(melhores_ind_epocas,ArraySize(melhores_ind_epocas)+1);
   melhores_ind_epocas[ArraySize(melhores_ind_epocas)-1]=melhor_atual;
   
   //---
   CalcularAptidaoRelativa(populacao);
   
   set pop_sel[];
   for(int i=0; i<ArraySize(populacao); i++){
      double r = MathRandRange(0,100);
      double sum_s=0;
      int in=0;
      
      while(sum_s <= r){
         sum_s+=populacao[in].aptidao_relativa;
         in++;
      }
      
      ArrayResize(pop_sel,i+1);
      pop_sel[i] = populacao[in-1];
   }
   
   ArrayFree(populacao);
   ArrayResize(populacao,ArraySize(pop_sel));
   for(int in=0; in<ArraySize(pop_sel); in++){
      populacao[in].period=pop_sel[in].period;
      populacao[in].deviation=pop_sel[in].deviation;
   }
   
   PrintFormat(" ---------------------- Indivíduos selecionados ----------------------");
   ExibeArray(pop_sel);
}

void Cruzamento(){
   int ic[];
   
   for(int i=0; i<ArraySize(populacao); i++){
      double r = MathRandRange(0,100);
      
      if(r <= Pc){
         ArrayResize(ic,ArraySize(ic)+1);
         ic[ArraySize(ic)-1] = i;
      }
   }
   
   if(ArraySize(ic)%2!=0) ArrayResize(ic,ArraySize(ic)-1);
   
   double deviation_temp;
   for(int j=0; j<ArraySize(ic); j++){
      if(j%2==0){
         deviation_temp = populacao[ic[j]].deviation;
         populacao[ic[j]].deviation = populacao[ic[j]+1].deviation;
      }else{
         populacao[ic[j]].deviation = deviation_temp;
      }       
   }
   
   PrintFormat(" ------------------------ Indivíduos cruzados ------------------------");
   ExibeArray(populacao);
}

void Mutacao(){
   for(int i=0; i<ArraySize(populacao); i++){
      double r = MathRandRange(0,100);
      double j = MathRandRange(0,1);
      
      if(j==0 && r<=Pm){
         int random_period = MathRandRange(period_start,period_stop);
         populacao[i].period = random_period;  
      }
      
      else if(j==1 && r<=Pm){
         double random_deviation = MathRandRange(deviation_start,deviation_stop);
         populacao[i].deviation = random_deviation;
      }
   }
   
   PrintFormat(" ------------------------ Indivíduos mutados -------------------------");
   ExibeArray(populacao);
}

double MathRandRange(double x, double y) { 
   return(x+MathMod(MathRand(),MathAbs(x-y))); 
}

void OrdenaArray(set& array[]){
   set temp;
   
   for(int j = 0; j < ArraySize(array); j++) {
      for(int i = 0; i < ArraySize(array)-1; i++){
           if(array[i].aptidao > array[i+1].aptidao) {
               temp = array[i+1];
               array[i+1]=array[i];
               array[i]=temp;
           }       
      }
   }
}

void CalcularAptidaoRelativa(set& array[]){
   //ordena o array em ordem crescente (pela aptidão)
   OrdenaArray(array);
   
   // Use the gauss formula to get the sum of all ranks (sum of integers 1 to N).
   double rank_sum = ArraySize(array) * (ArraySize(array) + 1) / 2;
   
   int rank=1;
   for(int in=0; in<ArraySize(array); in++){
      populacao[in].aptidao_relativa=(rank/rank_sum)*100;
      rank++;
   }
}

int MelhorAptidao(set& array[]){
   double melhor_aptidao = array[0].aptidao;
   int index=0;
   
   for(int i=0; i<ArraySize(array); i++){
      if(array[i].aptidao > melhor_aptidao){
         melhor_aptidao = array[i].aptidao;
         index=i;
      }
   }
   
   return index;
}

int PiorAptidao(set& array[]){
   double pior_aptidao = array[0].aptidao;
   int index=0;
   
   for(int i=0; i<ArraySize(array); i++){
      if(array[i].aptidao < pior_aptidao){
         pior_aptidao = array[i].aptidao;
         index=i;
      }
   }
   
   return index;
}

void ExibeArray(set& array[]){
   PrintFormat("Size: "+IntegerToString(ArraySize(array)));
   for(int in=0; in<ArraySize(array); in++){
      PrintFormat(IntegerToString(in)+" | "+IntegerToString(array[in].period)
      +" "+DoubleToString(array[in].deviation,2)
      +" "+DoubleToString(array[in].aptidao,2)
      +" "+DoubleToString(array[in].aptidao_relativa,2)
      /*+" "+array[in].win
      +" "+array[in].loss
      +" "+array[in].consecutive_losses
      +" "+array[in].count_entries*/);
   }
   PrintFormat(" ------------------------- ");
}