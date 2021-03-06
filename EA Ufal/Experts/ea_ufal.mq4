//+------------------------------------------------------------------+
//|                                                 projeto_ufal.mq4 |
//|                                                                  |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright ""
#property link      ""
#property version   "1.00"
#property strict

#define SELL -1
#define BUY 1
#define ND 0

extern      string             separador0              =  "-== Parâmetros iniciais ==-";
extern      double             lote                    =  0.10;
extern      double             take_proft              =  600;
extern      double             stop_loss               =  300;
extern      bool               ativar_trailling        =  true;
extern      int                TS                      =  50; 
extern      string             separador2              =  "# Rompimento de Sup/Res ";
extern      int                qtd_candles             =  3;
extern      bool               plot_hlines             =  false;
extern      string             separador3              =  "# Cruzamento de médias";
extern      int                period_media_rapida     =  3;
extern      int                period_media_lenta      =  10;
extern      ENUM_MA_METHOD     ma_method_rapida        =  MODE_EMA;
extern      ENUM_MA_METHOD     ma_method_lenta         =  MODE_SMA;
extern      ENUM_APPLIED_PRICE ma_applied_rapida       =  PRICE_CLOSE;
extern      ENUM_APPLIED_PRICE ma_applied_lenta        =  PRICE_CLOSE;
extern      string             separador4              =  "# TSR";
extern      int                period_TSR              =  130;
extern      string             separador5              =  "# Parabolic SAR";
extern      double             step_price              =  0.02;
extern      double             step_maximum            =  0.2;
extern      string             separador6              =  "# Bandas de Bollinger";
extern      int                period                  =  20;
extern      int                deviation               =  2;
extern      int                bands_shift             =  0;
extern      ENUM_APPLIED_PRICE applied_price           =  PRICE_CLOSE;
extern      string             separador7              =  "# Alligator";
extern      int                jaw_period              =  13;
extern      int                jaw_shift               =  8;
extern      int                teeth_period            =  8;
extern      int                teeth_shift             =  5;
extern      int                lips_period             =  5;
extern      int                lips_shift              =  3;
extern      ENUM_MA_METHOD     al_method               =  MODE_SMMA;
extern      ENUM_APPLIED_PRICE al_price                =  PRICE_CLOSE;


//jaw_period,jaw_shift,teeth_period,teeth_shift,lips_period,lips_shift,al_method,al_price,
// Variáveis globais
   int            ticket;
   double         pip;
   datetime       CurrentTimeStamp, CurrentTimeStamp_2;
   double         soma_operacoes_neutras=0, soma_operacoes_compra=0, soma_operacoes_venda=0;
   double         porcentagem_cobranca=0.5;
   
   //Sinal principal
   double         signal=ND;
   bool           atualizou_pesos=false;
   
// Variável de pesos e sinais
   double         pesos[7], sinais[7], sinal[7];    
   
// Estratégia 1
   double         maxima_candles, minima_candles;
// Estratégia 2
   double         media_lenta, media_rapida;
   double         sinal_media             =  ND;
// Estratégia 3
   double         sinal_compra_zigzag, sinal_venda_zigzag;   
// Estratégia 4   
   double         sinal_compra_TSR, sinal_venda_TSR;
// Estratégia 5   
   double         sinal_SAR;
// Estratégia 6
   double         banda_superior, banda_inferior;
// Estratégia 7
   double         gatorjaw, gatorteeth, gatorlips;
   double         sinal_alligator          =  ND;
                  
void init(){
// Funções
   // Chama função dos plots 
      plotHline();
      
   // Atribuindo valor inicial aos pesos
   for(int w=0; w<=ArraySize(pesos)-1; w++){
      pesos[w] = 1.0/NormalizeDouble(ArraySize(pesos),1);
   }

   Print("iniciou = "+pesos[0]+", "+pesos[1]+", "+pesos[2]+"\n"+pesos[3]+" "+pesos[4]+" "+pesos[5]+" "+pesos[6]);
// -----
HideTestIndicators(true); 

// Pega o tempo atual para que não dê sinal no momento que colocar o EA para rodar
   CurrentTimeStamp = Time[0];
   CurrentTimeStamp_2 = Time[0];
}

void start(){
   
// Funções
      if(OrdersTotal()>0 && ativar_trailling==true) Trailling(); 
   // Chama função dos plots 
      plotHline();
      openTrade();
      
      // Estratégia 1
         // Carregadores
         maxima_candles = iHigh(Symbol(), Period(),iHighest(Symbol(),Period(),MODE_HIGH,qtd_candles,1));
         minima_candles = iLow(Symbol(), Period(), iLowest(Symbol(),Period(),MODE_LOW,qtd_candles,1));
         //--
         
         if(CurrentTimeStamp != Time[0]){
            if(Ask > maxima_candles){
               sinais[0] = BUY;
            }
         
            else if(Bid < minima_candles){
               sinais[0] = SELL; 
            }
            
            else{
               sinais[0] = ND;
            }

      //---------

      // Estratégia 2
         // Carregadores
         media_rapida = iMA(Symbol(), Period(), period_media_rapida, 0, ma_method_rapida, ma_applied_rapida, 0);
         media_lenta  = iMA(Symbol(), Period(), period_media_lenta, 0, ma_method_lenta, ma_applied_lenta, 0);
         //--
         
            if(media_rapida > media_lenta && (sinal_media==ND||sinal_media==SELL)){
               sinais[1] = BUY;
               sinal_media = BUY;
            }
         
            else if(media_rapida < media_lenta && (sinal_media==ND||sinal_media==BUY)){
               sinais[1] = SELL;
               sinal_media = SELL;
            }
            
            else{
               sinais[1] = ND;
               sinal_media = ND;
            }
            
      //---------
         
      // Estratégia 3
         // Carregadores
         sinal_compra_zigzag = iCustom(NULL,0,"ZigAndZag",5,1);
         sinal_venda_zigzag = iCustom(NULL,0,"ZigAndZag",6,1);
         //--
            
            if(sinal_compra_zigzag!=NULL){
               sinais[2] = BUY;
            }
         
            else if(sinal_venda_zigzag!=NULL){
               sinais[2] = SELL;
            }
            
            else{
               sinais[2] = ND;
            }
            
      //---------
         
      // Estratégia 4
         // Carregadores
         sinal_compra_TSR = iCustom(NULL,0,"TSR V II",period_TSR,0,0);
         sinal_venda_TSR = iCustom(NULL,0,"TSR V II",period_TSR,1,0);
         //--
            
            if(sinal_compra_TSR!=EMPTY_VALUE){
               sinais[3] = BUY;
            }
         
            else if(sinal_venda_TSR!=EMPTY_VALUE){
               sinais[3] = SELL;
            }
            
      //---------
         
      // Estratégia 5
         // Carregadores
         sinal_SAR = iSAR(NULL,0,step_price,step_maximum,0);
         //--
          
            if(sinal_SAR>Close[0]){
               sinais[4] = BUY;
            }
         
            else if(sinal_SAR<Close[0]){
               sinais[4] = SELL;
            }
      
      //---------
         
      // Estratégia 6
         // Carregadores
         banda_superior = iBands(NULL,0,period, deviation, bands_shift, applied_price, MODE_UPPER,0);
         banda_inferior = iBands(NULL,0,period, deviation, bands_shift, applied_price, MODE_LOWER,0);
         //--
         
            if(High[1]>banda_superior && Close[1]<banda_superior) sinais[5] = SELL;
            else if(Low[1]<banda_inferior && Close[1]>banda_inferior) sinais[5] = BUY;
            else sinais[5] = ND;
      
      //---------
         
      // Estratégia 7
         // Carregadores
         gatorjaw = iAlligator(NULL,0,jaw_period,jaw_shift,teeth_period,teeth_shift,lips_period,lips_shift,al_method,al_price,MODE_GATORJAW,1);
         gatorteeth = iAlligator(NULL,0,jaw_period,jaw_shift,teeth_period,teeth_shift,lips_period,lips_shift,al_method,al_price,MODE_GATORTEETH,1);
         gatorlips = iAlligator(NULL,0,jaw_period,jaw_shift,teeth_period,teeth_shift,lips_period,lips_shift,al_method,al_price,MODE_GATORLIPS,1);
         //--
         
            if(gatorjaw>gatorteeth && gatorjaw>gatorlips) sinais[6] = BUY;
            else if(gatorjaw<gatorteeth && gatorjaw<gatorlips) sinais[6] = SELL;
            else sinais[6] = ND;
         
            CurrentTimeStamp = Time[0];  
         }   
}

void plotHline(){
   if(plot_hlines==true){
      // Plots - estratégia 1
         ObjectDelete("resistencia");
         ObjectDelete("suporte");
         // Resistencia
         ObjectCreate("resistencia", OBJ_HLINE, 0, Time[0], maxima_candles, 0, 0);
         ObjectSet("resistencia", OBJPROP_COLOR, Yellow);
         ObjectSet("resistencia", OBJPROP_WIDTH, 3);
         // Suporte
         ObjectCreate("suporte", OBJ_HLINE, 0, Time[0], minima_candles, 0, 0);
         ObjectSet("suporte", OBJPROP_COLOR, Yellow);
         ObjectSet("suporte", OBJPROP_WIDTH, 3);
   }else{
      // Limpar plots
         ObjectDelete("resistencia");
         ObjectDelete("suporte");
   }
}

void openTrade(){   
            if(OrdersTotal()==0 && CurrentTimeStamp_2!=Time[0]){  
               //------------------------------ atualizar pesos
               int cont=0;
               for(int i=0; i<ArraySize(sinal); i++){
                  if(sinal[i]==BUY || sinal[i]==SELL) cont++;
               }    
               if(atualizou_pesos==false && cont>1) atualizarPesos();
               else if(atualizou_pesos==false) atualizarPesos_2();
               //------------------------------  
               
               if(calcularSinal()==BUY){
                  ticket = OrderSend(Symbol(),OP_BUY,lote,Ask,0,Bid-stop_loss*Point,Ask+take_proft*Point,"",0,0,clrBlue);
                  for(int i=0; i<=ArraySize(sinais)-1; i++) sinal[i]=sinais[i];
                  atualizou_pesos=false;
               }
         
               else if(calcularSinal()==SELL){
                  ticket = OrderSend(Symbol(),OP_SELL,lote,Bid,0,Ask+stop_loss*Point,Bid-take_proft*Point,"",0,0,clrRed);
                  for(int i=0; i<=ArraySize(sinais)-1; i++) sinal[i]=sinais[i];  
                  atualizou_pesos=false;       
               }
               CurrentTimeStamp_2=Time[0];
            }
}

//----------------------------------------------- FUNÇÕES PARA O CÁLCULO DOS PESOS / SINAL
double calcularSinal(){
  double soma_ponderada=0, soma_sinais_neutros=0;
  
  for(int i=0; i<ArraySize(pesos); i++){
     if(sinais[i]!=0) soma_ponderada+=pesos[i]*sinais[i];
     else if(sinais[i]==0) soma_sinais_neutros+=pesos[i];
     
     if(soma_sinais_neutros>abs(soma_ponderada)) signal=ND;
     else if(soma_ponderada>=0) signal=BUY;
     else if(soma_ponderada<0) signal=SELL;
  } 
  
  return signal;
}

void calcular_soma_ponderada(){

   for(int i=0; i<ArraySize(pesos); i++){
      if(sinal[i]==0) soma_operacoes_neutras+=pesos[i];
      else if(sinal[i]==-1) soma_operacoes_venda+=pesos[i];
      else soma_operacoes_compra+=pesos[i];
   }
}

void atualizarPesos(){
   int saida_operacao = 0, erro;
   double valor_cobranca = 0;
   
   if(Profit()>0 && signal==BUY) saida_operacao=BUY; 
   else if(Profit()<0 && signal==BUY) saida_operacao=SELL;
   else if(Profit()>0 && signal==SELL) saida_operacao=SELL;
   else if(Profit()<0 && signal==SELL) saida_operacao=BUY;
   
   erro = saida_operacao-signal;
   calcular_soma_ponderada();
   
   if(saida_operacao==1) valor_cobranca=soma_operacoes_venda*porcentagem_cobranca;
   else valor_cobranca=soma_operacoes_compra*porcentagem_cobranca;
   
   for(int i=0;i<ArraySize(pesos);i++){
      if(sinal[i]!=0){ 
          if(sinal[i]==saida_operacao && sinal[i]==1){
            pesos[i]+=(pesos[i]/soma_operacoes_compra)*valor_cobranca;
          }
          else if(sinal[i]==saida_operacao && sinal[i]==-1){
            pesos[i]+=(pesos[i]/soma_operacoes_venda)*valor_cobranca;
          }
          else if(sinal[i]!=saida_operacao && sinal[i]==1){
            pesos[i]-=(pesos[i]/soma_operacoes_compra)*valor_cobranca;
          }
          else if(sinal[i]!=saida_operacao && sinal[i]==-1){
            pesos[i]-=(pesos[i]/soma_operacoes_venda)*valor_cobranca;
          }
      }
   }
   
   atualizou_pesos=true;
   Print("atualizou = "+pesos[0]+" "+pesos[1]+" "+pesos[2]+" "+pesos[3]+" "+pesos[4]+" "+pesos[5]+" "+pesos[6]+" / sinal = "+sinal[0]+" "+sinal[1]+" "+sinal[2]+" "+sinal[3]+" "+sinal[4]+" "+pesos[5]+" "+pesos[6]);
   //logs(pesos[0],pesos[1],pesos[2],sinal[0],sinal[1],sinal[2]);
}

void atualizarPesos_2(){
   int saida_operacao = 0, erro;
   
   if(Profit()>0 && signal==BUY) saida_operacao=BUY; 
   else if(Profit()<0 && signal==BUY) saida_operacao=SELL;
   else if(Profit()>0 && signal==SELL) saida_operacao=SELL;
   else if(Profit()<0 && signal==SELL) saida_operacao=BUY;
   
   erro = saida_operacao-signal;
   
   for(int i=0;i<ArraySize(pesos);i++){
      if(sinal[i]!=0){
         if(erro==0 && sinal[i]==saida_operacao) pesos[i]+=0.1;
         else if(erro==0 && sinal[i]!=saida_operacao) pesos[i]-=0.1;
         else if(erro!=0 && sinal[i]==saida_operacao) pesos[i]-=0.1;
         else if(erro!=0 && sinal[i]!=saida_operacao) pesos[i]+=0.1;
      }
   }
   
   atualizou_pesos=true;
   Print("atualizou = "+pesos[0]+" "+pesos[1]+" "+pesos[2]+" "+pesos[3]+" "+pesos[4]+" "+pesos[5]+" "+pesos[6]);
}

// Verifica o lucro da última operação do History
double Profit(){
   double profit=0;
   for(int i=0; i<=OrdersHistoryTotal()-1; i++){
      if(OrderSelect(i, SELECT_BY_POS, MODE_HISTORY)){
         profit=OrderProfit();
      }
   }
   
   return(profit);
}

void Trailling(){
   if(Digits==4 || Digits<=2) pip=Point;
   if(Digits==5 || Digits==3) pip=Point*10;
   
//--- 1.2. Trailing -------------------------------------------------------
   for(int i=0;i<OrdersTotal();i++)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==true)
        {
         if(OrderSymbol()==Symbol() && TS>0 && OrderProfit()>0)
           {
            if(OrderType()==OP_BUY && OrderOpenPrice()+TS*pip<=Bid && OrderStopLoss()<Bid-TS*pip) ticket=OrderModify(OrderTicket(),OrderOpenPrice(),Bid-TS*pip,OrderTakeProfit(),0);
            if(OrderType()==OP_SELL && OrderOpenPrice()-TS*pip>=Ask && (OrderStopLoss()>Ask+TS*pip || OrderStopLoss()==0)) ticket=OrderModify(OrderTicket(),OrderOpenPrice(),Ask+TS*pip,OrderTakeProfit(),0);
           }
      }
   }
}

double abs(double value){
   if(value<0) return value*-1;
   else return value;
}

/*void logs(double peso1, double peso2, double peso3, int sinal1, int sinal2, int sinal3){

int fh = FileOpen("log_pesos.txt", FILE_TXT|FILE_READ|FILE_WRITE);
if (fh==-1) // <- MQL4 code says a file handle of -1 will be returned if fileopen fails, don't make this a general case of <0
   {
   Alert("File opening failed: "+GetLastError());
   }

//if (fh>0) <- not guaranteed to have a >0 file handle value, can be any numer != -1
else
   {
    FileSeek(fh, 0, SEEK_END);
    FileWrite(fh,"pesos: "+peso1+" "+peso2+" "+peso3+" / sinais: "+sinal1+" "+sinal2+" "+sinal3);
    FileClose(fh);
    }
    // FileFlush(fh); <- not necessary, FileClose does FileFlush for you  
}*/