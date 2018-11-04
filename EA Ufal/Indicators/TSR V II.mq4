//+---------------------------------------------------------------------------+ 
//| HMA.mq4                                                                   |
//| Copyright © 2006 WizardSerg <wizardserg@mail.ru>, ForexMagazine #104      |
//| wizardserg@mail.ru                                                        |
//| Revised by IgorAD,igorad2003@yahoo.co.uk                                  |   
//| Personalized by iGoR AKA FXiGoR for the Trend Slope Trading method (T_S_T)|
//| Link:                                                                     |
//| contact: thefuturemaster@hotmail.com                                      |                                
//+---------------------------------------------------------------------------+
#property copyright "MT4 release WizardSerg <wizardserg@mail.ru>, ?? ??????? ForexMagazine #104"
#property link      "wizardserg@mail.ru"
//----
#property indicator_chart_window
#property indicator_buffers 2
#property indicator_color1 Lime
#property indicator_color2 Red
//---- input parameters 
extern int       period =   40;
       int       method =    3;                        
       int       price  =    0;  
       color     up     = Lime;                         
       color     dn     =  Red;                         
//---- buffers 
double Uptrend[];
double Dntrend[];
double ExtMapBuffer[];
//+------------------------------------------------------------------+ iCustom(sym,0,"TSR",periods,0,i) > iCustom(sym,0,"TSR",periods,1,i)
//| Custom indicator initialization function                         | 
//+------------------------------------------------------------------+ 
int init()
  {
  
   if(period == 300)
   {
   up =    Blue;
   dn = Magenta;
   }  
   if(period == 1500)
   {
   up =      Aqua;
   dn =    Yellow;
   }    
  
   IndicatorBuffers(3);
   SetIndexBuffer(0, Uptrend);
   //ArraySetAsSeries(Uptrend, true); 
   SetIndexBuffer(1, Dntrend);
   //ArraySetAsSeries(Dntrend, true); 
   SetIndexBuffer(2, ExtMapBuffer);
   ArraySetAsSeries(ExtMapBuffer, true);
//----
   SetIndexStyle(0,DRAW_LINE,STYLE_SOLID,3,up);
   SetIndexStyle(1,DRAW_LINE,STYLE_SOLID,3,dn);
   
   
//----
   IndicatorShortName("Signal Line("+period+")");
   SetIndexDrawBegin(0,period);
   SetIndexDrawBegin(1,period);
   
//--------
   double atr = iATR(NULL,0,10,1);
   
           ObjectCreate("buy",OBJ_ARROW,0,Time[0],0);
           ObjectSet("buy",OBJPROP_PRICE1,High[0]+ atr);
           ObjectSet("buy",OBJPROP_ARROWCODE,241);
           ObjectSet("buy",OBJPROP_COLOR,Lime);

           ObjectCreate("sell",OBJ_ARROW,0,Time[0],0);
           ObjectSet("sell",OBJPROP_PRICE1,Low[0]-atr);
           ObjectSet("sell",OBJPROP_ARROWCODE,242);
           ObjectSet("sell",OBJPROP_COLOR,Red);
            


//--------   

   return(0);
  }
//+------------------------------------------------------------------+ 
//| Custor indicator deinitialization function                       | 
//+------------------------------------------------------------------+ 
int deinit()
  { 
   return(0);
  } 
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double WMA(int x, int p)
  {
   return(iMA(NULL, 0, p, 0, method, price, x));
  }
//+------------------------------------------------------------------+ 
//| Custom indicator iteration function                              | 
//+------------------------------------------------------------------+ 
int start()
  {
   int counted_bars=IndicatorCounted();
   if(counted_bars < 0)
      return(-1);
//----
   int x=0;
   int p=MathSqrt(period);
   int e=Bars - counted_bars + period + 1;
//----
   double vect[], trend[];
//----
   if(e > Bars)
      e=Bars;
//----
   ArrayResize(vect, e);
   ArraySetAsSeries(vect, true);
   ArrayResize(trend, e);
   ArraySetAsSeries(trend, true);
//----
   for(x=0; x < e; x++)
     {
      vect[x]=2*WMA(x, period/2) - WMA(x, period);
      }
   for(x=0; x < e-period; x++)
//----
      ExtMapBuffer[x]=iMAOnArray(vect, 0, p, 0, method, x);
   for(x=e-period; x>=0; x--)
     {
      trend[x]=trend[x+1];
      if (ExtMapBuffer[x]> ExtMapBuffer[x+1]) trend[x] =1;
      if (ExtMapBuffer[x]< ExtMapBuffer[x+1]) trend[x] =-1;
      if (trend[x]>0)
        { 
         Uptrend[x]=ExtMapBuffer[x];
         if (trend[x+1]<0) Uptrend[x+1]=ExtMapBuffer[x+1];
         Dntrend[x]=EMPTY_VALUE;
        }
      else
         if (trend[x]<0)
           {
            Dntrend[x]=ExtMapBuffer[x];
            if (trend[x+1]>0) Dntrend[x+1]=ExtMapBuffer[x+1];
            Uptrend[x]=EMPTY_VALUE;
           }
      }
      
      //color oldColor=ObjectGet("hline12", OBJPROP_COLOR);

      //int shift = iBarShift(Symbol(),0,;

      double   pips,profit;
      string   var1    = TimeToStr(ObjectGet("buy", OBJPROP_TIME1),TIME_DATE|TIME_SECONDS); 
      datetime buytime = StrToTime(var1);
      int      shift   = iBarShift(NULL,0,buytime);
      double   a       = iOpen(NULL,0,shift);
     
      string   var2    = TimeToStr(ObjectGet("sell", OBJPROP_TIME1),TIME_DATE|TIME_SECONDS); 
      datetime selltime = StrToTime(var2);
      int      shift2   = iBarShift(NULL,0,selltime);
      double   b        = iOpen(NULL,0,shift2);
 
               pips     = b - a;
      
 
      
               profit   = (pips/MarketInfo(Symbol(),MODE_POINT)*0.1)*MarketInfo(Symbol(),MODE_TICKVALUE);
      
      Comment(pips,"  ",profit);
      
   return(0);
  }
//+------------------------------------------------------------------+ 







