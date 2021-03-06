extern bool ativar_operacoes_ob = false, 
            ativar_operacoes_forex = false;
extern string separador1 = "===========================";
extern bool AtivarMartingale_OB=false;
extern bool AtivarMartingale_FX=false;
extern bool MaximoGales_OB=false;
extern int MaxGales_OB=4; //Quantidade de gales permitido (OB)
extern bool MaximoGales_FX=false;
extern bool GalesSeguidosOuNao_OB=false;
extern double MaxGale_LoteFX=0.32; //Quantidade de gales permitido (FX)
extern double MultiplicadorMartingale_OB=2.5;
extern double MultiplicadorMartingale_FX=2;
extern string separador2 = "===========================";
extern bool AtivarTraillingStop_FX=false;
extern double LoteForex=0.01;
extern int StopLoss=1000;
extern int TakeProfit=1000;
extern string separador3 = "===========================";
extern double LoteOB=1;
extern int TempoExpiracaoMinutos_OB=1;
extern int Expert_ID = 1234; 
extern string separador4 = "=============Trailing Stop (pips)";
//+------------------------------------------------------------------+
int sinal=0, arrow_i=0, _MagicNumber=0, contador=0, tipOrder=2;
double Martingale_OB=LoteOB,
       Martingale_FX=LoteForex;

double abertura_preco=0;
//+------------------------------------------------------------------+
int ticket=0;
extern int TS = 25;                  

//-------------------------------------------------------------------------
// Variables
//-------------------------------------------------------------------------
double pip;
bool w, OrdemAnteriorComLucro=false;


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnInit()
  {
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
    
    
    TempoExpiracaoMinutos_OB=TempoExpiracaoMinutos_OB*60;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick()
  {
  
   if(AtivarTraillingStop_FX==true){
     Trailling();
   }

     Estrategia();
  }
  
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
int Estrategia()
  {
//---
     if(OrdersTotal()==0){
     double TJ_UP1 = iCustom(NULL,0,"Correlation 0",1,0);
     double TJ_DOWN1 = iCustom(NULL,0,"Correlation 0",1,1);
     
     double TJ_UP2 = iCustom(NULL,0,"Correlation 1",1,3);
     double TJ_DOWN2 = iCustom(NULL,0,"Correlation 1",1,4);
     
     double TJ_UP3 = iCustom(NULL,0,"Correlation 2",1,6);
     double TJ_DOWN3 = iCustom(NULL,0,"Correlation 2",1,7);
     
     double TJ_UP4 = iCustom(NULL,0,"Correlation 3",1,9);
     double TJ_DOWN4 = iCustom(NULL,0,"Correlation 3",1,10);
     
     if(ativar_operacoes_ob==true && AtivarMartingale_OB==true){      
         MartingaleOB(); 
     }
     
     if(ativar_operacoes_forex==true && AtivarMartingale_FX==true){
         MartingaleFX();
     }
     
     if((Close[1] > Open[1]) && TJ_DOWN1!=0 && TJ_DOWN2!=0 && TJ_DOWN3!=0 && TJ_DOWN4!=0){
        if(ativar_operacoes_ob==true){
            ticket=OrderSend(Symbol(),OP_SELL,Martingale_OB,Bid,0,0,0,"BO exp:"+IntegerToString(TempoExpiracaoMinutos_OB),_MagicNumber,0,clrRed);
            tipOrder=0;
        }
        
        if(ativar_operacoes_forex==true){
            if(TakeProfit!=0){
               ticket=OrderSend(Symbol(),OP_SELL,Martingale_FX,Bid,3,Bid+StopLoss*Point,Bid-TakeProfit*Point,"",_MagicNumber,0,clrRed);
            }else{
               ticket=OrderSend(Symbol(),OP_SELL,Martingale_FX,Bid,3,Bid+StopLoss*Point,0,"",_MagicNumber,0,clrRed);
            }
        }
        
        sinal=-1;
     }
     
     if((Close[1] < Open[1]) && TJ_UP1!=0 && TJ_UP2!=0 && TJ_UP3!=0 && TJ_UP4!=0){
        if(ativar_operacoes_ob==true){
            ticket=OrderSend(Symbol(),OP_BUY,Martingale_OB,Ask,0,0,0,"BO exp:"+IntegerToString(TempoExpiracaoMinutos_OB),_MagicNumber,0,clrBlue);
            tipOrder=1;
        }
        
        if(ativar_operacoes_forex==true){
            if(TakeProfit!=0){
               ticket=OrderSend(Symbol(),OP_BUY,Martingale_FX,Ask,3,Ask-StopLoss*Point,Ask+TakeProfit*Point,"",_MagicNumber,0,clrBlue);
            }else{
               ticket=OrderSend(Symbol(),OP_BUY,Martingale_FX,Ask,3,Ask-StopLoss*Point,0,"",_MagicNumber,0,clrBlue);
            }
        }
        
        sinal=1;
     }
     
     MostrarSeta();

     if(GalesSeguidosOuNao_OB==true){
         if(Martingale_OB>LoteOB){
               if(tipOrder==1){
                   ticket=OrderSend(Symbol(),OP_BUY,Martingale_OB,Ask,0,0,0,"BO exp:"+IntegerToString(TempoExpiracaoMinutos_OB),_MagicNumber,0,clrBlue);
               }
               
               else if(tipOrder==0){      
                   ticket=OrderSend(Symbol(),OP_SELL,Martingale_OB,Bid,0,0,0,"BO exp:"+IntegerToString(TempoExpiracaoMinutos_OB),_MagicNumber,0,clrRed);
               }
         }
      }
   }

   return(0);
 }
//+------------------------------------------------------------------+

void Trailling(){
//--- 1.1. Define pip -----------------------------------------------------
   if(Digits==4 || Digits<=2) pip=Point;
   if(Digits==5 || Digits==3) pip=Point*10;

//--- 1.2. Trailing -------------------------------------------------------
   for(int i=0;i<OrdersTotal();i++)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==true)
        {
         if(OrderSymbol()==Symbol() && TS>0 && OrderProfit()>0)
           {
            if(OrderType()==OP_BUY && OrderOpenPrice()+TS*pip<=Bid && OrderStopLoss()<Bid-TS*pip) w=OrderModify(OrderTicket(),OrderOpenPrice(),Bid-TS*pip,OrderTakeProfit(),0);
            if(OrderType()==OP_SELL && OrderOpenPrice()-TS*pip>=Ask && (OrderStopLoss()>Ask+TS*pip || OrderStopLoss()==0)) w=OrderModify(OrderTicket(),OrderOpenPrice(),Ask+TS*pip,OrderTakeProfit(),0);
            if(OrderType()==OP_BUY && OrderOpenPrice()+TS*pip<=Bid && OrderStopLoss()<Bid-TS*pip) w=OrderModify(OrderTicket(),OrderOpenPrice(),Bid-TS*pip,OrderTakeProfit(),0);
            if(OrderType()==OP_SELL && OrderOpenPrice()-TS*pip>=Ask && (OrderStopLoss()>Ask+TS*pip || OrderStopLoss()==0)) w=OrderModify(OrderTicket(),OrderOpenPrice(),Ask+TS*pip,OrderTakeProfit(),0);
            if(OrderType()==OP_BUY && OrderOpenPrice()+TS*pip<=Bid && OrderStopLoss()<Bid-TS*pip) w=OrderModify(OrderTicket(),OrderOpenPrice(),Bid-TS*pip,OrderTakeProfit(),0);
            if(OrderType()==OP_SELL && OrderOpenPrice()-TS*pip>=Ask && (OrderStopLoss()>Ask+TS*pip || OrderStopLoss()==0)) w=OrderModify(OrderTicket(),OrderOpenPrice(),Ask+TS*pip,OrderTakeProfit(),0);
            if(OrderType()==OP_BUY && OrderOpenPrice()+TS*pip<=Bid && OrderStopLoss()<Bid-TS*pip) w=OrderModify(OrderTicket(),OrderOpenPrice(),Bid-TS*pip,OrderTakeProfit(),0);
            if(OrderType()==OP_SELL && OrderOpenPrice()-TS*pip>=Ask && (OrderStopLoss()>Ask+TS*pip || OrderStopLoss()==0)) w=OrderModify(OrderTicket(),OrderOpenPrice(),Ask+TS*pip,OrderTakeProfit(),0);
           }
        }
     }
      
      
//--- 1.3. End of main function -------------------------------------------
}
int MartingaleOB(){
  ///////// Verificar último trade
  for(int i=0; i<=OrdersHistoryTotal(); i++){    
      if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY)&&AtivarMartingale_OB==true){
         if(OrderProfit()<0 && OrderSymbol()==Symbol()){
             Martingale_OB=OrderLots()*MultiplicadorMartingale_OB;      
         }else if(OrderProfit()==0){
             Martingale_OB=OrderLots();
         }else if(OrderProfit()>0){
             Martingale_OB=LoteOB;
         }
      }
   }
  
  ///////// Limitador de gales
  if(MaximoGales_OB==true){
       if(LoteOB==1){
           if(Martingale_OB>=pow((LoteOB*2),MaxGales_OB)){
               Martingale_OB=LoteOB;
           }
       }else if(Martingale_OB>=pow(LoteOB,MaxGales_OB)){
               Martingale_OB=LoteOB;
       }
  }
  
  return(0);
}

void MartingaleFX(){
   for(int i=0; i<=OrdersHistoryTotal(); i++){   
      if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY)){
         if(OrderType()==OP_BUY || OrderType()==OP_SELL){
             if(OrderProfit()<0){
                   Martingale_FX=OrderLots()*MultiplicadorMartingale_FX;  
             }else if(OrderProfit()==0){
                   Martingale_FX=OrderLots();
             }else if(OrderProfit()>0){
                  Martingale_FX=LoteForex;
             }
         }
      }
   }

  ///////// Limitador de gales - fx
  if(MaximoGales_FX==true && Martingale_FX>MaxGale_LoteFX){
               Martingale_FX=LoteForex;
  }
}

void MostrarSeta(){
   if(abertura_preco!=Open[1] && contador!=0){
     contador=0;
   }
    
    if(contador==0){
      abertura_preco = Open[1];           
    }
    
    if(abertura_preco==Open[1] && contador==0){
         contador++;
               
         if(sinal==-1){
           sinal=0;
           arrow_i++;
           ObjectCreate("Down-Martingale"+IntegerToString(arrow_i), OBJ_ARROW, 0, Time[1], High[1]+20*Point);
           ObjectSet("Down-Martingale"+IntegerToString(arrow_i), OBJPROP_ARROWCODE, 222);
           ObjectSet("Down-Martingale"+IntegerToString(arrow_i), OBJPROP_COLOR, clrRed);
         }
     
         else if(sinal==1){
          sinal=0;
          arrow_i++;
          ObjectCreate("Up-Martingale"+IntegerToString(arrow_i), OBJ_ARROW, 0, Time[1], Low[1]-20*Point);
          ObjectSet("Up-Martingale"+IntegerToString(arrow_i), OBJPROP_ARROWCODE, 221);
          ObjectSet("Up-Martingale"+IntegerToString(arrow_i), OBJPROP_COLOR, clrGreen); 
         }
    }
}

