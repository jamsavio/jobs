//+------------------------------------------------------------------+
//|                                    calculadora_probabilidade.mq4 |
//|                                                                  |
//|                                                                  |
//+------------------------------------------------------------------+

input    double   banca_inicial = 100;
input    double   valor_operacao = 2;
input    int      qtd_operacaoes = 100;
input    double   win_rate = 60;
input    double   payout = 70;
input    int      geracoes_total = 10;

int epoca_resul[];

int OnInit()
  {
//---
    int geracoes = 1;
    double loss_rate = 100-win_rate;
    
    while(geracoes<=geracoes_total){
       double banca = banca_inicial;
       int qtd = qtd_operacaoes;
    
       while(qtd!=0){
          double r = MathRandRange(0,100);
          if(r <= loss_rate){
            if((banca-valor_operacao) >= 0) banca-=valor_operacao;
            //PrintFormat("LOSS / Banca R$ = "+DoubleToString(banca,2));
          }else{
            banca+=valor_operacao*(payout/100);
            //PrintFormat("WIN / Banca R$ = "+DoubleToString(banca,2));
          }
          
          if(qtd == 1){
            ArrayResize(epoca_resul,ArraySize(epoca_resul)+1);
            epoca_resul[ArraySize(epoca_resul)-1] = banca;
            PrintFormat("=====> Total da Banca da Geração "+IntegerToString(geracoes)+" após "+IntegerToString(qtd_operacaoes)+" operações: R$"+DoubleToString(banca,2));
          }
       
         qtd--;
       }
       
       geracoes++;
    }
    
    //Calcula a média das bancas das epocas
    double media=0, acumulador=0;
    int SIZE = ArraySize(epoca_resul), acima=0, abaixo=0;
    
    for(int i=0; i<SIZE; i++){
      acumulador+=epoca_resul[i];
      if(epoca_resul[i] > banca_inicial) acima++;
      else if(epoca_resul[i] < banca_inicial) abaixo++;
    }
    media=acumulador/SIZE;
    
    PrintFormat("A média das bancas das "+IntegerToString(geracoes_total)+" gerações é: R$ "+DoubleToString(media,2)+" / "+acima+" gerações ficaram acima da banca inicial / "+abaixo+" gerações ficaram abaixo da banca inicial");
    
    return(INIT_SUCCEEDED);
//---
  }
  
double MathRandRange(double x, double y) { 
   return(x+MathMod(MathRand(),MathAbs(x-y))); 
}

void OnDeinit(const int reason){
   ArrayFree(epoca_resul);
}