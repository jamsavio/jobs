//+------------------------------------------------------------------+
//|                                         manipulacao_arquivos.mq4 |
//|                                                                  |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Jam Sávio - jamsaavio@gmail.com"
#property link      ""
#property version   "1.00"
#property strict


int ticket;

string conteudo_array[][6]; //array que irá armazenar o conteúdo do arquivo

int OnInit()
  {
   LeArquivo(); 
   
   return(0);
  }

void OnTick()
  {
//---
         for(int i=0; i<ArraySize(conteudo_array); i++){
         
            if(conteudo_array[i][0] == Symbol()){
            
               if(conteudo_array[i][1] == "BUY" && Close[0] > StringToDouble(conteudo_array[i][2])){
                  ticket = OrderSend(Symbol(),OP_BUY,StringToDouble(conteudo_array[i][3]),Ask,0,Ask-StringToDouble(conteudo_array[i][4])*Point,Ask+StringToDouble(conteudo_array[i][5])*Point,"",0,0,clrBlue);
                  rewrite_file(i);
               }
               
               else if(conteudo_array[i][1] == "SELL" && Close[0] < StringToDouble(conteudo_array[i][2])){
                  ticket = OrderSend(Symbol(),OP_SELL,StringToDouble(conteudo_array[i][3]),Bid,0,Bid+StringToDouble(conteudo_array[i][4])*Point,Bid-StringToDouble(conteudo_array[i][5])*Point,"",0,0,clrRed);
                  rewrite_file(i);
               } 
            }
         } 
         
         LeArquivo(); 
  }

void LeArquivo(){
ResetLastError();
ArrayFree(conteudo_array);
   
   int filehandle = FileOpen("arquivo.csv", FILE_READ|FILE_CSV);
   if (filehandle != INVALID_HANDLE){
      FileReadString(filehandle); // consume a primeira linha e ignora
       
      while(!FileIsEnding(filehandle)){
         string array_temp[];
         string conteudo_arquivo = FileReadString(filehandle);
                
         //--- A separator as a character
         string sep=","; 
         //--- Get the separator code
         ushort u_sep=StringGetCharacter(sep,0);
         //--- Split the string to substrings
         int k=StringSplit(conteudo_arquivo,u_sep,array_temp);
         
         ArrayResize(conteudo_array,ArraySize(conteudo_array)+1);
         int aux = ArraySize(conteudo_array)-1;
         if(aux==4) Print(conteudo_array[4][0]);
         conteudo_array[aux][0]    = array_temp[0];
         conteudo_array[aux][1]    = array_temp[1];
         conteudo_array[aux][2]    = array_temp[2];
         conteudo_array[aux][3]    = array_temp[3];
         conteudo_array[aux][4]    = array_temp[4];
         conteudo_array[aux][5]    = array_temp[5];
         
      }  
      
      FileClose(filehandle);
      
   }else{
	   Print("O arquivo não foi aberto com sucesso, error ",GetLastError());
   }
}

void rewrite_file(int index){
   FileDelete("arquivo.csv");
   
   int fileHandle = FileOpen("arquivo.csv" , FILE_READ|FILE_WRITE|FILE_TXT);
   if(fileHandle!=INVALID_HANDLE){
      FileSeek(fileHandle,0,SEEK_END);
      FileWriteString(fileHandle,"PAR,TIPO_ORDEM,GATILHO,STOP_LOSS,TAKE_PROFIT"); 
      FileWriteArray(fileHandle,conteudo_array,0,index-1);
      FileWriteArray(fileHandle,conteudo_array,index+1,ArraySize(conteudo_array)-1);
      FileClose(fileHandle); 
   }
}