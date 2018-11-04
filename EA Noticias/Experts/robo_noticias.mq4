#property copyright "Copyright © 2018, @jsvio_"
#property link "jamsaavio@gmail.com"
#property description "Operate notice of high impact"
#property strict

// -- External variables
extern 		int 		   height				    =	30;   // Distance of orders to actual price 
extern		int			time_open_orders	    = 5;  	 // Time before notice to open orders
extern      int         time_close_orders     = -5;    // Time after notice to close orders
extern      int         event_impact          = 3;    
extern      bool        news_current_pair     = true;  // News of just current pair
extern 		double 		lot_size    		    =	0.05;	 // Lot size
extern      int         TS                    = 1;    // Points of distance to move the tralling stop 
extern      double      spread_max            = 20;    // Spread maximum to open orders  
extern      int         magic_number          = 12345; // Magic number

// -- Global variables
       		int    		ticket				    =	0;		

// -- Inicialization
void OnInit(){
   EventSetTimer(1);
}

void OnDeinit(const int reason){
   EventKillTimer();
}

// -- Algo
void OnTimer(){
   int EventMinute = (int)iCustom(NULL,0,"FFC",news_current_pair,0,0);
   int EventImpact = (int)iCustom(NULL,0,"FFC",news_current_pair,1,0);

   if(EventMinute<=time_open_orders && EventMinute>0 && EventImpact>=event_impact) PendingOrders();
   else if(EventMinute<=time_close_orders && TotalPendingOrders()>0) ClosePendingOrders();
   else if(TotalOrders()>0){
      if(TotalPendingOrders()>0) ClosePendingOrders();
      TraillingStop();
   }
}

// -- Functions 

void PendingOrders(){
      double spread_atual = MarketInfo(Symbol(),MODE_SPREAD);
      
      if(TotalPendingOrders()==0 && spread_atual<=spread_max){
	      ticket = OrderSend(Symbol(), OP_BUYSTOP, lot_size, Ask + height * Point, 1, 0, 0, "", magic_number, 0, clrWhite);
	      ticket = OrderSend(Symbol(), OP_SELLSTOP, lot_size, Bid - height * Point, 1, 0, 0, "", magic_number, 0, clrWhite);	
	   }
	
	   else{
	        ModifyOrders();
	   }
}

int TotalPendingOrders(){
   int total_pending_orders=0;
   
   for(int i=0; i<=OrdersTotal(); i++){
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)){
         if(OrderMagicNumber()==magic_number && OrderSymbol()==Symbol()){
            if(OrderType()==OP_BUYSTOP || OrderType()==OP_SELLSTOP) total_pending_orders++;
         }
      }
   }
   
   return total_pending_orders;
}

int TotalOrders(){
   int total_orders=0;
   
   for(int i=0; i<=OrdersTotal(); i++){
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)){
         if(OrderMagicNumber()==magic_number && OrderSymbol()==Symbol()){
            if(OrderType()==OP_BUY || OrderType()==OP_SELL) total_orders++;
         }
      }
   }
   
   return total_orders;
}

void ClosePendingOrders(){
   for(int i=0; i<=OrdersTotal(); i++){
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)){
         if(OrderMagicNumber()==magic_number && OrderSymbol()==Symbol()){
            if(OrderType()==OP_BUYSTOP || OrderType()==OP_SELLSTOP){
               ticket = OrderDelete(OrderTicket(),clrWhite);
            }
         }
      }
   }
}

void ModifyOrders(){
   for(int i=0; i<=OrdersTotal(); i++){
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)){
         if(OrderMagicNumber()==magic_number && OrderSymbol()==Symbol()){
            if(OrderType()==OP_BUYSTOP){
               ticket = OrderModify(OrderTicket(),Ask+height*Point,Close[0],0,0,clrWhite);
            }else if(OrderType()==OP_SELLSTOP){
               ticket = OrderModify(OrderTicket(),Bid-height*Point,Close[0],0,0,clrWhite);
            }
         }
      }
   }
}

void TraillingStop(){
	bool w;
	double pip=1;

	if(Digits==4 || Digits<=2) pip=Point;
   if(Digits==5 || Digits==3) pip=Point*10;

	for(int i=0; i<OrdersTotal(); i++){
		if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES) == true){
		
			if(OrderSymbol() == Symbol() && TS >0 && OrderProfit()>0){
				if(OrderType() == OP_BUY && OrderOpenPrice() + TS * pip <= Bid && OrderStopLoss() < Bid - TS * pip){ 
					w = OrderModify(OrderTicket(), OrderOpenPrice(), Bid - TS * pip, OrderTakeProfit(), 0);
				}
            	
				if(OrderType() == OP_SELL && OrderOpenPrice() - TS * pip >= Ask && (OrderStopLoss() > Ask + TS * pip || OrderStopLoss() == 0)){
				    w = OrderModify(OrderTicket(), OrderOpenPrice(), Ask + TS * pip, OrderTakeProfit(), 0);
				}
			}		
		}	
	}
}
