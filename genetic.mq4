//+------------------------------------------------------------------+
//|                                                      genetic.mq4 |
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
   int    win;   
   int    loss;   
   int    consecutive_wins;       
   int    consecutive_losses; 
   int    count_entries;
   double aptidao;
   double aptidao_relativa;
};

extern int     historical_bars      = 1000;   
extern int     period_start         = 20;
extern int     period_step          = 5;
extern int     period_stop          = 50;
extern double  deviation_start      = 2;
extern double  deviation_step       = 1;
extern double  deviation_stop       = 6; 

int pais_sel_size=0, epocas=1;
set populacao[];
set melhor_anterior;
set melhor_atual;

int OnInit()
{
//---
      populacao_inicial();
      
      while(melhor_anterior.aptidao < melhor_atual.aptidao){ 
         backtest();
         selecao();
         cruzamento();
         mutacao();
         
         epocas++;
         //Print(melhor_anterior.aptidao+" "+melhor_atual.aptidao);
      }
      
     PrintFormat("Melhor SET -> Period: "+IntegerToString(melhor_anterior.period)
                  +" Deviation: "+DoubleToString(melhor_anterior.deviation,2)
                  +" Aptidao: "+DoubleToString(melhor_anterior.aptidao,2)
                  +" Epocas: "+epocas);
      
//---
   return(0);
}

void populacao_inicial(){
   //inicializa aptidao
   melhor_anterior.aptidao=-1;
   melhor_atual.aptidao=0;   
   
   int periodo=period_start;
   int desvio=deviation_start;
   
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
      }else{
         periodo = period_start;
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

void backtest(){
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
      
       //Calcula a aptidao do individuo
       double aptidao=populacao[in].win - populacao[in].loss - populacao[in].consecutive_losses;
       aptidao = aptidao > 0 ? aptidao + populacao[in].count_entries * 0.035 : aptidao - populacao[in].count_entries;
       populacao[in].aptidao=aptidao;
    }
}

void selecao(){

   // guarda o melhor individuo anterior
   if(epocas>1) melhor_anterior = melhor_atual;
   
   //ordena o array em ordem crescente
   OrdenaArray(populacao);
   
   //define a aptidao relativa de cada individuo
   CalcularAptidaoRelativa(populacao);
   
   //guarda o melhor individuo atual
   melhor_atual = populacao[ArraySize(populacao)-1];
   
   //exibe_array(populacao);
   
   //--
   set pop_sel[];

   //seleciona 30% da população atual aleatoriamente para a próxima epoca
   for(int i=0; i<MathRound(ArraySize(populacao)*0.3); i++){
   
      double r = MathRandRange(0,100);
      double sum_s=0;
      int in=0;
      
      /*acumula a aptidao relativa até chegar em um individuo em que a soma das aptidoes seja maior ou igual a aptidao sorteada
      que é quando sai do laço com a posição do individuo em que parou*/
      while(sum_s <= r){
         sum_s+=populacao[in].aptidao_relativa;
         in++;
      }
      
      //adiciona o selecionado em uma array temporaria 
      ArrayResize(pop_sel,i+1);
      pop_sel[i] = populacao[in-1];
      
      //remove o ind selecionado da array principal para evitar que ele seja selecionado de novo
      /*PrintFormat("--- Antes ---");
      exibe_array(populacao);*/
      ArrayRemove(populacao,in-1);
      //Recalcula aptidao relativa dos individuos
      CalcularAptidaoRelativa(populacao);
      
      /*PrintFormat("Random: "+r+" Sum_s: "+NormalizeDouble(sum_s,2)+" in: "+(in-1)+" tamanho array: "+ArraySize(populacao));
      PrintFormat("--- Depois ---");
      exibe_array(populacao);*/
   }
   
   /*elitismo - pega o melhor da população atual e substitui o pior que foi selecionado
    (somente se o melhor não foi incluso na seleção randomica)*/
   OrdenaArray(pop_sel);
   if(pop_sel[ArraySize(pop_sel)-1].aptidao != melhor_atual.aptidao){
      if(pop_sel[0].aptidao < melhor_atual.aptidao) pop_sel[0] = melhor_atual; 
   }
   
   //limpa o array (populacao) para receber a populacao selecionada
   ArrayFree(populacao);
   ArrayResize(populacao,ArraySize(pop_sel));
   //zera as aptidoes dos pais pra proxima epoca
   for(int in=0; in<ArraySize(populacao); in++){
      populacao[in].period=pop_sel[in].period;
      populacao[in].deviation=pop_sel[in].deviation;
   }
   
   PrintFormat(" ---------------------- Indivíduos selecionados ----------------------");
   OrdenaArray(pop_sel);
   exibe_array(pop_sel);
   PrintFormat(" ---------------------------------------------------------------------");
}

void cruzamento(){
   pais_sel_size=ArraySize(populacao);
   
   for(int i=0, aux=1; i<pais_sel_size; i++){
      //se chegar ao final da lista adiciona 0 ao 'aux' para pegar o ultimo elemento e cruzar com o primeiro
      if(aux > pais_sel_size-1) aux=0;
      
      //acrescenta mais um espaço na lista para receber o novo individuo cruzado
      ArrayResize(populacao,ArraySize(populacao)+1);
      
      //pega a posição do novo espaço no array
      int index = ArraySize(populacao)-1;
      
      if(i%2==0){
         populacao[index].period=populacao[i].period;
         populacao[index].deviation=populacao[aux].deviation;
      }else{
         populacao[index].period=populacao[i].period;
         populacao[index].deviation=populacao[i-1].deviation;     
      }
      
      //inicializa variaveis para o próximo backtest
      populacao[index].consecutive_losses=0;
      populacao[index].consecutive_wins=0;
      populacao[index].count_entries=0;
      populacao[index].loss=0;
      populacao[index].win=0;
      
      aux++;
   }
   
   PrintFormat(" ------------------------ Indivíduos cruzados ------------------------");
   exibe_array(populacao);
   PrintFormat(" ---------------------------------------------------------------------");
}

void mutacao(){
   for(int i=0; i<MathRandRange(1,ArraySize(populacao)); i++){
      //verifica primeiro se tem algum filho que não sofreu alteração no cruzamento para adicionar o ruído
      for(int j=0; j<ArraySize(populacao); j++){
         for(int t=pais_sel_size; t<ArraySize(populacao); t++){
            if(j!=t && populacao[j].period == populacao[t].period && populacao[j].deviation == populacao[t].deviation){
                  realiza_mutacao(populacao,t);
            }
         }
      }
           
      int in_mut = MathRandRange(pais_sel_size,ArraySize(populacao)-1); 
      if(ArraySize(populacao)==2) in_mut = 1;
      realiza_mutacao(populacao,in_mut);
   }
   
   PrintFormat(" ------------------------ Indivíduos mutados -------------------------");
   exibe_array(populacao);
   PrintFormat(" ---------------------------------------------------------------------");
}

//+------------------ Utilitários ------------------*

void exibe_array(set& array[]){
   PrintFormat("Size: "+ArraySize(array)+" -------------- ");
   for(int in=0; in<ArraySize(array); in++){
      PrintFormat(in+" | "+array[in].period
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

double MathRandRange(double x, double y) { 
   return(x+MathMod(MathRand(),MathAbs(x-y))); 
}

void ArrayRemove(set& array[], int index){
   set temp_array[];
   
   ArrayCopy(temp_array,array,0,0,index);
   ArrayCopy(temp_array,array,index,index+1,ArraySize(array)-1);
   ArrayFree(array);
   ArrayCopy(array,temp_array,0,0);
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
   int rank=1;
   // Use the gauss formula to get the sum of all ranks (sum of integers 1 to N).
   double rank_sum = ArraySize(array) * (ArraySize(array) + 1) / 2;

   for(int in=0; in<ArraySize(array); in++){
      populacao[in].aptidao_relativa=(rank/rank_sum)*100;
      rank++;
   }
}

void realiza_mutacao(set& array[], int index){
   int def_mutation = MathRandRange(0,2); //se 0 entao modifica o periodo, senao modifica a variacao
   int signal = MathRandRange(0,2); // se 0 então soma, senão subtrai o ruido adicional
      
   if(def_mutation==0){
         int period_noise = MathRandRange(1,10); 
         if(signal==0) populacao[index].period+=period_noise;
         else if (populacao[index].period-period_noise > 0) populacao[index].period-=period_noise; 
         else populacao[index].period+=period_noise;
   }else{
         int deviation_noise = MathRandRange(1,4);
         if(signal==0) populacao[index].deviation+=deviation_noise;
         else if (populacao[index].deviation-deviation_noise > 0) populacao[index].deviation-=deviation_noise;
         else populacao[index].deviation+=deviation_noise;
   }
}