//+------------------------------------------------------------------+
//|                                                     Trend EA.mq4 |
//|                                                                  |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright ""
#property link      ""
#property version   "1.00"

extern double Investimento = 1;
extern double MultiplicadorMartingale = 2.5;
extern bool AtivarMartingale = true; 
extern int TempoExpiracao = 15; 
extern int Expert_ID = 1234; 

double Martingale=Investimento, vela1_b=0, vela2_b=0; 
// vela1 e vela2 serve para identificar os candles e evitar que conte mais de 1 no msm candle
int ticket=0, arrow_i=0, _MagicNumber=0;

int OnInit(){
 int Period_ID = 0;
    switch ( Period() )
    {
        case PERIOD_MN1: Period_ID = 9; break;
        case PERIOD_W1:  Period_ID = 8; break;
        case PERIOD_D1:  Period_ID = 7; break;
        case PERIOD_H4:  Period_ID = 6; break;
        case PERIOD_H1:  Period_ID = 5; break;
        case PERIOD_M30: Period_ID = 4; break;
        case PERIOD_M15: Period_ID = 3; break;
        case PERIOD_M5:  Period_ID = 2; break;
        case PERIOD_M1:  Period_ID = 1; break;
    }
    _MagicNumber = Expert_ID * (10 + Period_ID);
    
   return(0);
}

void OnTick()
  {
//---
   TempoExpiracao=TempoExpiracao*60;
   
   // Martingale
   if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_HISTORY)&&AtivarMartingale==true){
         if(OrderProfit()<0 && OrderMagicNumber() == _MagicNumber){
             Martingale=OrderLots()*MultiplicadorMartingale;
         }else if(OrderProfit()==0){
             Martingale=OrderLots();
         }else if(OrderProfit()>0){
             Martingale=Investimento;
         }
   }
         
   if(Investimento==1){
      if(Martingale>=pow((Investimento*2),4)){
         Martingale=Investimento;
      }
   }
   
   else if(Martingale>=pow(Investimento,4)){
      Martingale=Investimento;
   }
   ///////////////////    
   
   double buy = iCustom(NULL,0,"Trend-Following",0,0);
   double sell = iCustom(NULL,0,"Trend-Following",1,0);
   
   int max_contador=0;
    
   for(int e=OrdersTotal(); e>=0; e--){
      if(OrderSelect(e,SELECT_BY_POS,MODE_TRADES)){     
            if(OrderMagicNumber() == _MagicNumber && OrderSymbol() == Symbol()){
               max_contador++;
            }
         }  
   } 
   
     
   if(max_contador<1){ 
      if(buy<0 && sell==0)
      {
         if(vela1_b==0&&vela2_b==0){
            vela1_b=Open[0];
         }
         
         if((vela1_b!=0&&vela1_b!=Open[0])&&vela2_b==0){
            vela2_b=Open[0];
         }
         
         if(vela1_b!=Open[0]&&vela2_b!=Open[0]){
            ticket=OrderSend(Symbol(),OP_BUY,NormalizeDouble(Martingale,0),Ask,0,0,0,"BO exp:"+TempoExpiracao,0,0,clrBlue);
            
            vela1_b=0; // reseta 
            vela2_b=0; // reseta 
            
            arrow_i++;
            ObjectCreate("Up-Martingale"+arrow_i, OBJ_ARROW, 0, Time[0], Low[0]-20*Point);
            ObjectSet("Up-Martingale"+arrow_i, OBJPROP_ARROWCODE, 221);
            ObjectSet("Up-Martingale"+arrow_i, OBJPROP_COLOR, clrGreen);
            Alert("Entrada de CALL feita! "+Symbol()); 
         }
      }
      
      if(buy==0 && sell>0){
         if(vela1_b==0&&vela2_b==0){
            vela1_b=Open[0];
         }
         
         if((vela1_b!=0&&vela1_b!=Open[0])&&vela2_b==0){
            vela2_b=Open[0];
         }
         
         if(vela1_b!=Open[0]&&vela2_b!=Open[0]){
            ticket=OrderSend(Symbol(),OP_SELL,NormalizeDouble(Martingale,0),Bid,0,0,0,"BO exp:"+TempoExpiracao,0,0,clrRed);
            
            vela1_b=0; // reseta
            vela2_b=0; // reseta
            
            arrow_i++;
            ObjectCreate("Down-Martingale"+arrow_i, OBJ_ARROW, 0, Time[0], High[0]+20*Point);
            ObjectSet("Down-Martingale"+arrow_i, OBJPROP_ARROWCODE, 222);
            ObjectSet("Down-Martingale"+arrow_i, OBJPROP_COLOR, clrRed);
            Alert("Entrada de PUT feita! "+Symbol()); 
         }
      }
      
      if(buy<0 && sell>0){
         vela1_b=0; // reseta
         vela2_b=0; // reseta
      }
    }
    
    Comment(vela1_b+" "+vela2_b+" "+buy+" "+sell);
//---
  }
