//+------------------------------------------------------------------+
//|                                                   control_ea.mq4 |
//|                                                                  |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright ""
#property link      ""
#property version   "1.00"
#property strict

#include <WinUser32.mqh>
#import "user32.dll"
int GetAncestor(int,int);
#define MT4_WMCMD_EXPERTS  33020 
#import

bool Disable=false;
bool Enable=false;
input string filename="control_ea.txt";

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- create timer
   EventSetMillisecondTimer(500);
   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//--- destroy timer
   EventKillTimer();
   
  }

//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
//---
      int main=GetAncestor(WindowHandle(Symbol(),Period()),2);
      
      if(lerArquivo()=="turnoff" && !Disable){
         PostMessageA(main,WM_COMMAND,MT4_WMCMD_EXPERTS,0);
         PrintFormat("Negociação automática foi desabilitada...");
         Disable=true;
         Enable=false;
      }
      
      if(lerArquivo()=="turnon" && !Enable){
         PostMessageA(main,WM_COMMAND,MT4_WMCMD_EXPERTS,0);
         PrintFormat("Negociação automática foi ativada...");
         Enable=true;
         Disable=false;
      }
      
  }
//+------------------------------------------------------------------+

string lerArquivo(){
   ResetLastError();
   int file_handle=FileOpen(filename,FILE_READ|FILE_TXT);
   if(file_handle!=INVALID_HANDLE){
      int    str_size;
      string str;
      //--- read data from the file
      str_size=FileReadInteger(file_handle,INT_VALUE);
      str=FileReadString(file_handle,str_size);
      FileClose(file_handle);
      return(str);
    }
    else
      return(IntegerToString(INVALID_HANDLE));
   return("");
}