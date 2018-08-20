//+------------------------------------------------------------------+
//|                                                      Mansour.mq4 |
//|                                            Mohamed Mansour Beek. |
//|                                          https://www.mansour.com |
//+------------------------------------------------------------------+
#property copyright "Mohamed Mansour Beek."
#property link      "https://www.DasStack.com"
#property version   "2.52"
#property strict


/********************************************************************
To do
// Rety if failure
// Normalize All prices
**********************************************************************/

//---- Dependencies
#import "stdlib.ex4"
   string ErrorDescription(int e);
#import

// External variables
extern string PS_Ex0                   = ">> Lot Size TP SL";
extern double LotSize                  = 0.01;
extern double StopLoss                 = 0;
extern double TakeProfit               = 50;
extern double Max_Spread               = 35;
extern string PS_Ex1                   = ">> Timing and Graph";
extern int shift                       = 1;
extern int MagicNumber                 = 224455;
extern string PS_Ex2                   = ">> Entry strategy";
extern double TradeStep                = 0.002;
extern double TradeMax                 = 0.2;
extern string PS_Ex3                   = ">> Exit strategy";
extern double StopStep                 = 0.004;
extern double StopMax                  = 0.4;              
input string PS_Ex4                    = ">> File ";
input string InpFileName               ="Mansour";       // File name
input string InpDirectoryName          ="Data";     // Folder name
input bool Log_all                     = true;
input bool Log_trades                  = true;
input bool Close_Profit                = true;
// Global variables
int LongTicket;
int ShortTicket;
double RealPoint;
bool change = false;
bool ordered = false;
double last_order;
string Reason = ""; string Action = "";

int file_handle,file_handle_trade;
string comment, comment_trade;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- create timer
     EventSetTimer(900);
     Comment("Copyright © http://www.dasstack.com");
     SendNotification("Started on " + (string) Symbol());
     RealPoint = RealPipPoint(Symbol());
     Print("Symbol=",Symbol());
     Print("SymbolAllow=",MarketInfo(Symbol(), MODE_TRADEALLOWED));
     Max_Spread_Reached = false;
     string file_name = Symbol() + ".txt" ;
     if(Log_all)
      file_handle=FileOpen(InpDirectoryName+"//"+InpFileName+file_name,FILE_READ|FILE_WRITE);
     file_name = Symbol() +  "trades.txt" ;
     if(Log_trades)
     file_handle_trade=FileOpen(InpDirectoryName+"//"+InpFileName+file_name,FILE_READ|FILE_WRITE);
     //timer = Hour() + ":0" + Minute();
     //RealPoint = 0.0001
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//--- destroy timer
   if(Log_all)
      FileClose(file_handle);
   if(Log_trades)
      FileClose(file_handle_trade);
   EventKillTimer();
      
  }
//+------------------------------------------------------------------+
//| Expert Global          Vars                                      |
//+------------------------------------------------------------------+

double adxplsH1,adxminusH1;
double adxplsH11,adxminusH11;
double adxminusM15,adxplsM15;
double adxminusM30,adxplsM30;
double adxminusM151,adxplsM151;
double lastP,lastM;
double lastH;
double adxMin,adxMinH4;
int _CountOrd, _Buy, _Sell;
double _SLots,_BLots;
double _SProfit, _BProfit;
double profit;
// Timing
bool BarM,BarH;
bool Max_Spread_Reached;
// iSAR
double trade_sar,trade_sar1,stop_sar;
// Bars
double CLOSE,CLOSE1,HIGH,LOW;


bool buy_condition_H ;
bool buy_condition_M ;
bool intersect_M_to_Buy;
bool sell_condition_H ;
bool sell_condition_M ;
bool intersect_M_to_Sell ;
bool intersect_H_to_Buy ;
bool intersect_H_to_Sell ;
bool Sell_signal ;
bool Buy_signal ;


//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+

int start()
  {
  //
  //Vars
   if(MarketInfo(Symbol(), MODE_TRADEALLOWED) == 0.0 ) return 0;
   
   if((MarketInfo(Symbol(),MODE_SPREAD) > Max_Spread )&& !Max_Spread_Reached){
      _Update(OP_BUY,true);
      Max_Spread_Reached = true;
   } else if((MarketInfo(Symbol(),MODE_SPREAD) <= Max_Spread )&& Max_Spread_Reached){
      _Update(OP_BUY);
      Max_Spread_Reached = false;
   }  
      
   adxplsH1= iADX(NULL, PERIOD_M15, 14 , PRICE_CLOSE, MODE_PLUSDI, shift );
   adxminusH1= iADX(NULL, PERIOD_M15, 14 , PRICE_CLOSE, MODE_MINUSDI, shift);
   adxMinH4 = iADX(NULL, PERIOD_H1, 50,PRICE_CLOSE, MODE_MAIN,shift);
   
   adxplsM30= iADX(NULL, PERIOD_M30, 14 , PRICE_CLOSE, MODE_PLUSDI, shift);
   adxminusM30= iADX(NULL, PERIOD_M30, 14 , PRICE_CLOSE, MODE_MINUSDI, shift);
   
   adxplsM15= iADX(NULL, PERIOD_M1, 14 , PRICE_CLOSE, MODE_PLUSDI, shift);
   adxminusM15= iADX(NULL, PERIOD_M1, 14 , PRICE_CLOSE, MODE_MINUSDI, shift);
   adxMin = iADX(NULL, PERIOD_M1, 14,PRICE_CLOSE, MODE_MAIN,shift);
   
   adxplsH11= iADX(NULL, PERIOD_M15, 14 , PRICE_CLOSE, MODE_PLUSDI, shift+1);
   adxminusH11= iADX(NULL, PERIOD_M15, 14 , PRICE_CLOSE, MODE_MINUSDI, shift+1);
   
   adxplsM151= iADX(NULL, PERIOD_M1, 14 , PRICE_CLOSE, MODE_PLUSDI, shift+1);
   adxminusM151= iADX(NULL, PERIOD_M1, 14 , PRICE_CLOSE, MODE_MINUSDI, shift+1);
   
   trade_sar  = iSAR(Symbol(), PERIOD_M15, TradeStep, TradeMax, shift);
   trade_sar1 = iSAR(Symbol(), PERIOD_M15, TradeStep, TradeMax, shift+1);
   stop_sar   = iSAR(Symbol(), PERIOD_M15, StopStep, StopMax, shift);
   // Bars
   CLOSE  = iClose(Symbol(),PERIOD_M15, shift);
   CLOSE1 = iClose(Symbol(),PERIOD_M15, shift+1);
   HIGH   = iHigh(Symbol(), PERIOD_M15, shift);
   LOW    = iLow(Symbol(), PERIOD_M15, shift);
   
   BarH = IsBarClosed(PERIOD_M15,0) ;
   BarM = IsBarClosed(PERIOD_M1,1);
   
   comment = "";
   comment_trade = "";
   RefreshRates();
   
   Total_orders(false);
   if( profit > 1.0 && _SLots > 0.0 && _BLots > 0.0 ){ //@ Break Even
      Print("### Close All ####");
      _Close_all();
      Total_orders();
      }
        
   order_check(); 
   return(0);
   
}
//+------------------------------------------------------------------+
//| Pip Point Function                                                  |
//+------------------------------------------------------------------+
double RealPipPoint(string Currency)
  {
    double CalcPoints;
    CalcPoints = 0.001;
    double CalcDigits = MarketInfo(Currency,MODE_DIGITS); 
    if(CalcDigits == 4 || CalcDigits == 5) CalcPoints = 0.00001;
    return(CalcPoints);
  }

//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
//---
   ordered = false;
  }

//+------------------------------------------------------------------+
//| Clock function                                                   |
//+------------------------------------------------------------------+
bool IsBarClosed(int timeframe,int index)
{
    static datetime lastbartime[3];

    if(iTime(NULL,timeframe,1)==lastbartime[index]) // wait for new bar
        return(false);
    lastbartime[index]=iTime(NULL,timeframe,1);
    return(true);
}
//+------------------------------------------------------------------+
//| Totals function                                                  |
//+------------------------------------------------------------------+
void Total_orders(bool P = true)
{
   _CountOrd=0;_Buy=0;_Sell=0;
   _SLots = 0.0; _BLots =0.0;
   profit = 0.0;
   _BProfit = 0.0; _SProfit = 0.0;
   RefreshRates();
   for(int i=0;i<OrdersTotal();i++)
   {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES) == false) continue;
      if(OrderSymbol()==Symbol()&&(OrderMagicNumber()==MagicNumber))
      {
         if(OrderType()==OP_BUY){
         _CountOrd++;
         _Buy++;
         _BLots += OrderLots();
         _BProfit += OrderProfit()+OrderCommission()+OrderSwap();
         }else if(OrderType()==OP_SELL){
         _CountOrd++;
         _Sell++;
         _SLots += OrderLots();
         _SProfit += OrderProfit()+OrderCommission()+OrderSwap();
         }
         profit+=OrderProfit()+OrderCommission()+OrderSwap();
      }
   }
   if(P)
      Print("Total " + IntegerToString( _CountOrd) 
      + " Buy " + IntegerToString(_Buy) + " = " + (string) _BLots 
      + " Sell " + IntegerToString(_Sell) + " = " + (string) _SLots 
      + " Profit " + (string) profit
      );
}
//+------------------------------------------------------------------+
//| Order Process                                                   |
//+------------------------------------------------------------------+
int order_check()
{  
  //Print("NowDIPlus="+adxplsM15+" NowDIMinus="+adxminusM15+" PrevDIPlus="+adxplsM151+" PrevDIMinus="+adxminusM151);
                           
   buy_condition_H = adxplsH1  > adxminusH1;
   buy_condition_M = adxplsM15 > adxminusM15;
   intersect_M_to_Buy =  ((adxplsM151 < adxminusM151) && (adxplsM15 > adxminusM15));
  
   sell_condition_H = (adxplsH1  < adxminusH1);
   sell_condition_M = (adxminusM15 > adxplsM15 );
   intersect_M_to_Sell =  ((adxplsM151 > adxminusM151) && (adxplsM15 < adxminusM15));
   
   intersect_H_to_Buy = ((adxplsH11 < adxminusH11) && (adxplsH1 > adxminusH1));
   intersect_H_to_Sell = ((adxplsH11 > adxminusH11) && (adxplsH1 < adxminusH1));
   
   Sell_signal = trade_sar > CLOSE && stop_sar > CLOSE;
   Buy_signal = trade_sar < CLOSE && stop_sar < CLOSE;
   
   if(adxMin < 15 || adxMinH4 < 10 )
      return 0;

   string alert = ("Status : \n BH "+ (string)  buy_condition_H +" SH "+ (string)  sell_condition_H  +  "\n" + 
      " H2B "+ (string)  intersect_H_to_Buy+" H2S "+ (string) intersect_H_to_Sell + "\n" + 
      " BM "+ (string) buy_condition_M +  " SM "+ (string) sell_condition_M +  "\n" + 
      " M2B "+ (string)  intersect_M_to_Buy+  " M2S "+ (string) intersect_M_to_Sell );
      
   if(BarH){
      SendNotification("Hour Change" + alert);
      // Change on H
      if(intersect_H_to_Buy && Buy_signal ){
         if (_Sell > 0 ){
            Reason = "#Reason# H2Buy & _Sell";
            Action = "#Action# Buy Double ";
            Buy_double(0);
            print();
            return (0);
            }
         else if ( buy_condition_M ){
            Reason = "#Reason# H2Buy & _SM";
            Action = "#Action# BuyNorm";
            Buy_normal (LotSize,TakeProfit);
            print();
            return (0);
            }
         }
      if(intersect_H_to_Sell && Sell_signal){
         if (_Buy > 0 ){
            Reason = "#Reason# H2Sell & _Buy";
            Action = "#Action# Sell Double ";
            Sell_double(0);
            print();
            return (0);
            }
         else if ( sell_condition_M ){
            Reason = "#Reason# H2Buy & SM";
            Action = "#Action# SellNorm";
            Sell_normal (LotSize,TakeProfit);
            print();
            return (0);
            }        
         }   
    }

   if(!BarM) return (0);
   // Change on M and Hour is reversed
   // May be Close all 
   if( sell_condition_H && intersect_M_to_Buy && (_Buy > 0)){
     Reason = "#Reason# SH & M2Buy & _Buy";
     Action = "#Action# Close Sell Diff";
     if(_BLots < _SLots){
        _Close(OP_SELL, NormalizeDouble(_SLots -_BLots, Digits));
        //Total_orders();
        _Update(OP_BUY);
         }
        //_Close(OP_BUY, 0);
        //_Close(OP_SELL, 0);
     }
   else if( buy_condition_H && intersect_M_to_Sell && (_Sell > 0)){
      Reason = "#Reason# BH & M2Sell & _Sell";
      Action = "#Action# Close Buy Diff";
      if(_BLots > _SLots){
         _Close(OP_BUY, NormalizeDouble((_BLots - _SLots), Digits));
         _Update(OP_SELL);
         }
        }
   else if( buy_condition_H && intersect_M_to_Buy && (_Sell > 0) ){
     Reason = "#Reason# BH & M2B & _Sell";
     Action = "#Action# Buy Double "+ (string) LotSize +" Lot; Tp "+ (string) TakeProfit;
     Buy_double(LotSize);
   }
   else if( sell_condition_H && intersect_M_to_Sell  && (_Buy > 0) ){  
     Reason = "#Reason# SH & M2S & _Buy";
     Action = "#Action# Sell Double "+ (string)  LotSize +" Lot; Tp " + (string)  TakeProfit;
     Sell_double(LotSize);
   }        
  else if( buy_condition_H && intersect_M_to_Buy && (_Sell == 0)){
     Reason = "#Reason BH & M2B & !_Sell";
     Action = "#Action# Buy "+ (string) LotSize +" Lot; Tp "+ (string) TakeProfit;
     Buy_normal (LotSize,TakeProfit);            
    }
  else if( sell_condition_H && intersect_M_to_Sell  && (_Buy == 0)  ){
     Reason = "#Reason SH & M2S & !_Buy";
     Action = "#Action# Sell "+ (string)  LotSize +" Lot; Tp " + (string)  TakeProfit;
     Sell_normal(LotSize,TakeProfit);
    }
    
  if(BarM){
         print();
      }     
  
  return (0);
 }

//+------------------------------------------------------------------+
//| Print                                                            |
//+------------------------------------------------------------------+ 
  
void print(bool trade = false){
      Total_orders();
      if(!trade){
      Comment("Status : \n BH  ", buy_condition_H ," SH  ", sell_condition_H  , "\n" ,
      " H2B ", intersect_H_to_Buy,              " H2S ",intersect_H_to_Sell ,"\n" ,
      " BM  ",buy_condition_M ,                 " SM  ",sell_condition_M , "\n" ,
      " M2B ", intersect_M_to_Buy,              " M2S ",intersect_M_to_Sell, "\n" ,
      " SLt ", _SLots,                          " BLt ",_BLots, "\n" ,
      " Pft ", _SProfit,                        " pft ",_BProfit, "\n" ,
      " Ttl ", profit
       );

      Print("Status : BH  ", buy_condition_H ," SH  ", sell_condition_H  ,
      " H2B ", intersect_H_to_Buy,              " H2S ",intersect_H_to_Sell ,
      " BM  ",buy_condition_M ,                 " SM  ",sell_condition_M ,
      " M2B ", intersect_M_to_Buy,              " M2S ",intersect_M_to_Sell, 
      " SLt ", _SLots,                          " BLt ",_BLots,
      " Pft ", _SProfit,                        " pft ",_BProfit, 
      " Ttl ", profit
          ); 
          
     }
     string str = ("Status : BH "+ (string)  buy_condition_H +" SH "+ (string)  sell_condition_H  +
      " H2B "+ (string)  intersect_H_to_Buy+" H2S "+ (string) intersect_H_to_Sell +
      " BM "+ (string) buy_condition_M +  " SM "+ (string) sell_condition_M +
      " M2B "+ (string)  intersect_M_to_Buy+  " M2S "+ (string) intersect_M_to_Sell +
      " SLt "+ (string)   _SLots + " BLt " + (string)  _BLots+
      " Pft "+ (string)   _SProfit + " pft " + (string)  _BProfit+
      " Ttl "+ (string)   profit 
      );
      
     if(Log_all) 
      FileWriteString(file_handle,str + comment +"\r\n");
     if(Log_trades && trade)
      FileWriteString(file_handle_trade,str + comment_trade +"\r\n");
}
//+------------------------------------------------------------------+
//| Buy Double Condition                                                   |
//+------------------------------------------------------------------+ 
  
 void Buy_double(double Max_Lots)
 {
   // TP of open sell + diff
   _Close(OP_SELL,0);
   // Refesh lots
   Total_orders();
   // open new 2x diff sell 
   double _LotSize = 0.0;
   if(Max_Lots > 0.0)
      _LotSize = Max_Lots;
   else if(_SLots == _BLots)
      _LotSize = _SLots;
   else if (_SLots > _BLots)
      _LotSize = 2 * (_SLots - _BLots);
   else if (_BLots > _SLots )
      _LotSize = LotSize;
   
   //Print ("Buying Double "+ (string)_LotSize);
   if(_LotSize > 0){
      if(_Sell){
         double break_even = 0.0 ;
         if((_BLots + _LotSize  - _SLots ) > 0.01 )
            break_even = MathAbs( profit / (_BLots  - _SLots + _LotSize));
         else
            break_even = 0 ;
         Action += ";; Lot "+ (string) _LotSize + " Points " + (string) break_even;
         //Print ("Buying Double XXXX "+ (string) break_even);
         Buy_normal(_LotSize, break_even);
      }else {
         //Print ("Buying Double XXXXYY ", TakeProfit);
         Action += ";; Lot "+ (string) LotSize  + " Points " + (string) TakeProfit;
         Buy_normal(LotSize, TakeProfit);
      }
   // Refesh lots
   Total_orders();
   // Update All open oreders to break even
   //if(_BLots && _SLots)
      _Update(OP_BUY);
   }
 }

//+------------------------------------------------------------------+
//| Buy Normal Condition                                                   |
//+------------------------------------------------------------------+ 
  
 void Buy_normal(double _LotSize = 0.0,double TP = 0.0)
 {
  if(_LotSize == 0.0)
     _LotSize = LotSize;
  _LotSize = NormalizeDouble(_LotSize, 2);
  //Print ("Buying ", _LotSize);
  double LongStopLoss = 0.0;
  double LongTakeProfit = 0.0;
  //if (SL > 0) sl = NormalizeDouble(Bid + SL * Point, Digits);
   RefreshRates();
   if(StopLoss > 0) LongStopLoss = NormalizeDouble(Bid - StopLoss * RealPoint, Digits);
   if(TP > 0) LongTakeProfit = NormalizeDouble(Bid + TP * RealPoint, Digits);
   //LongTicket = OrderSend(Symbol(),OP_BUY,LotSize,Ask,0,0,0,"Buy Order",MagicNumber,0,Green);
   string OrederPlace = ";;SL " + (string) LongStopLoss + " TP " + (string) LongTakeProfit + " At " + (string) Ask + " Lot " + (string) _LotSize;
   comment = " " + Reason + " " + Action + " " + OrederPlace;
   if (OrderSend( Symbol(), OP_BUY, _LotSize, Ask, 5, NormalizeDouble(LongStopLoss,Digits), NormalizeDouble(LongTakeProfit, Digits), "Buy Order" + comment , MagicNumber,0, clrBlue) == -1)
   {
       Print("Error order Buy "+(string)ErrorDescription(GetLastError()) +comment);
       comment_trade = "Error order Buy "+(string)ErrorDescription(GetLastError()) +comment;
       print(true);
       
   }
   else{
       Print("OrderBuy placed successfully " + comment);
       comment_trade = "OrderBuy placed successfully " + comment;
       print(true);
   }
 }
//+------------------------------------------------------------------+
//| Sell Double Condition                                                   |
//+------------------------------------------------------------------+ 
  
 void Sell_double(double Max_Lots)
 {
   // TP of open sell + diff
   _Close(OP_BUY,0);
   // Refesh lots
   Total_orders();
   // open new 2x diff sell 
   double _LotSize = 0.0;
   if(Max_Lots > 0.0)
      _LotSize = Max_Lots;
   else if(_BLots == _SLots)
    _LotSize = _BLots;
   else if (_BLots > _SLots )
     _LotSize = 2 * ( _BLots - _SLots);
   else if (_SLots > _BLots)
     _LotSize = LotSize;
   
   //Print ("Selling Double "+ (string) _LotSize);
   if(_LotSize > 0){
      if(_Buy){
         double break_even = 0.0;
         if (( _SLots + _LotSize - _BLots  ) > 0.01)
            break_even = MathAbs( profit / ( _SLots + _LotSize - _BLots ));
         else
            break_even = 0 ;
         //Print ("Selling Double XXXX "+ (string) break_even);
         Action += ";; Lot "+ (string) _LotSize + " Points " + (string) break_even;
         Sell_normal(_LotSize, break_even);
      }else{
         //Print ("Selling Double XXXXZZ ",TakeProfit);
         Action += ";; Lot "+ (string) LotSize + " Points " + (string) TakeProfit;
         Sell_normal(LotSize,TakeProfit);
      }
   // Refesh lots
   Total_orders();
   // Update All open oreders to break even
   //if(_BLots && _SLots)
      _Update(OP_SELL); 
   }
 }


//+------------------------------------------------------------------+
//| Sell function                                                   |
//+------------------------------------------------------------------+    
void Sell_normal(double _LotSize = 0.0,double TP = 0.0)
 {
  if(_LotSize == 0.0)
     _LotSize = LotSize;
   _LotSize = NormalizeDouble(_LotSize, 2);
   Print ("Selling ", _LotSize);
   double SortStopLoss = 0.0;
   double SortTakeProfit = 0.0;
   RefreshRates();
   if(StopLoss > 0) SortStopLoss = NormalizeDouble(Ask + StopLoss * RealPoint, Digits);
   if(TP > 0) SortTakeProfit = NormalizeDouble(Ask - TP * RealPoint, Digits);
   string OrederPlace = ";;SL " + (string) SortStopLoss + " TP " + (string) SortTakeProfit + " At " + (string) Ask + " Lot " + (string) _LotSize;
   comment = " " + Reason + " " + Action + " " + OrederPlace;
   if (OrderSend( Symbol(), OP_SELL, _LotSize, Bid, 3, SortStopLoss, SortTakeProfit, "Sell Order"+comment, MagicNumber,0, clrRed) == -1)
      {
       Print("Error order Sell "+(string)ErrorDescription(GetLastError())+comment);
       comment_trade ="Error order Sell "+(string)ErrorDescription(GetLastError())+comment;
       print(true); 
      }
   else
      {
      Print("OrderSell placed successfully"+ comment);
      comment_trade = "OrderSell placed successfully"+ comment;
       print(true);
      }
      
 }   
 //+------------------------------------------------------------------+
//| Close Orders function                                                   |
//+------------------------------------------------------------------+    
 void _Close(int direction, double Lots){
   double price = Ask;
   if(direction == OP_SELL)
       price = Ask;
    else if(direction == OP_BUY)
       price = Bid;
   bool res = true;
   
   comment = " " + Reason + " " + Action;
   string c;
   if(Lots == 0){
   // TP of all 
   for(int i=0;i<OrdersTotal();i++)
      {
         if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES) == false) continue;
         if(OrderSymbol()==Symbol())
            if(OrderType()== direction &&(OrderMagicNumber()==MagicNumber) && (OrderProfit() > 0.0) ){
                 res = OrderClose(OrderTicket(),OrderLots(),price,3,clrBrown);
                 c = " Order #"+(string) OrderTicket()+" By Double rev profit: "+(string)  OrderTakeProfit() +" Dir "+(string)  direction + " Lots " +(string)  OrderLots();
                 if(!res){
                     Print("Error in Closing _Close ALL . Error code=", ErrorDescription(GetLastError()) , comment ,c);
                     comment_trade = "Error in Closing _Close ALL . Error code="+ ErrorDescription(GetLastError()) + comment + c;
                     print(true);
                  }else{
                     Print("Order Closed _Close ALL successfully."+ comment+ c );
                     comment_trade = "Order Closed _Close ALL successfully."+ comment+ c ;
                     print(true);
                   }
                Print(c);
            }
      } 
   } else {
   double diff = Lots;
   double prof = 0.0;
   if(diff > 0.0){
      for(int i=0;i<OrdersTotal();i++)
         {
            if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES) == false) continue;
            if (diff == 0.0) continue;
            if((OrderSymbol()==Symbol()) && (OrderType()==direction) &&(OrderMagicNumber()==MagicNumber) && (OrderProfit() > 0.0) ){
               if(diff >= OrderLots()){
                  res = OrderClose(OrderTicket(),OrderLots(),price,3,clrBrown);
                  c = "Order #"+(string) OrderTicket()+" profit: "+(string)  OrderTakeProfit();
                  if(res){
                     diff -=  OrderLots();
                     prof += OrderProfit();
                     }
               }else{
                  res = OrderClose(OrderTicket(),diff,price,3,clrBrown);
                  c = "Order #"+(string) OrderTicket()+" profit: "+(string)  OrderTakeProfit();
                  if(res){
                     diff = 0;
                     prof += OrderProfit();
                     }
               }
               if(!res){
                  Print("Error in _Close. Error code=",ErrorDescription(GetLastError()) , comment ,c);
                  comment_trade = "Error in _Close. Error code="+ErrorDescription(GetLastError()) + comment +c ;
                  print(true);
               }else{
                  Print("Order _Close successfully." + comment + c);
                  comment_trade = "Order _Close successfully." + comment+ c ;
                  print(true);
                }
            }
         }
         if(Close_Profit && prof> 0.0){
            int rev_direction = OP_BUY;
            if(direction == OP_BUY)
                rev_direction = OP_SELL;
            _Close_Profit(rev_direction,prof);
         }
      }
    } 
  }
 //+------------------------------------------------------------------+
//| Close Profit function                                                   |
//+------------------------------------------------------------------+    
 void _Close_Profit(int direction, double prof){
   double price = Ask;
   if(direction == OP_SELL)
       price = Ask;
    else if(direction == OP_BUY)
       price = Bid;
   bool res = true;
   
   comment = " " + Reason + " " + Action;
   string c;
   double prft = prof;
   // TP of all 
      for(int i=0;i<OrdersTotal();i++)
         {
            if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES) == false) continue;
            if (prft == 0.0) continue;
            if((OrderSymbol()==Symbol()) && (OrderType()==direction) &&(OrderMagicNumber()==MagicNumber) ){
            double diff =  prft + OrderProfit() - (RealPoint * MarketInfo(Symbol(),MODE_SPREAD));
               if(diff > 0.0){
                  res = OrderClose(OrderTicket(),OrderLots(),price,3,clrBrown);
                  c = "Order #"+(string) OrderTicket()+" profit: "+(string)  OrderTakeProfit();
                  if(res){
                     prft = diff;
                     }
               
               if(!res){
                  Print("Error in _Close Profit. Error code=",ErrorDescription(GetLastError()) , comment ,c);
                  comment_trade = "Error in _Close Profit. Error code="+ErrorDescription(GetLastError()) + comment +c ;
                  print(true);
               }else{
                  Print("Order _Close Profit successfully." + comment + c);
                  comment_trade = "Order _Close Profit successfully." + comment+ c ;
                  print(true);
                }
              }
            }
         }
  }
//+------------------------------------------------------------------+
//| Update Orders function                                           |
//+------------------------------------------------------------------+    

int _Update(int direction, bool clear = false){
   // Calculate Break even
   if(profit > 10){
      _Close_all();
      return(0);
   }
   Total_orders(true);
   
   double break_even = 0.0;
   if(_Sell > 0.0 && _Buy > 0.0 && (_SLots != _BLots)){
     break_even = MathAbs(RealPoint * profit / (_BLots - _SLots));
     //break_even += (RealPoint * 15);
   } else if((_Sell > 0.0 || _Buy > 0.0) &&(_SLots != _BLots)) { // Only Sell OR Buy
     break_even = RealPoint * TakeProfit;
   }else{ //Boot equal
     break_even = 0.0; //$
   }

   if(_SLots > _BLots)
      direction = OP_SELL;
   else if (_SLots < _BLots)
      direction = OP_BUY;

   comment = " " + Reason + " " + Action;      
   Print("Profit ", profit, " Break Even ", break_even , comment);
   string mode = "";
   // Update all
   bool res = true;
   
   if (break_even == 0.0 || clear){
   for(int i=0;i<OrdersTotal();i++)
      {
         if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES) == false) continue;
         if(OrderSymbol()==Symbol()&&(OrderMagicNumber()==MagicNumber))
          {
            mode = " Remove SL && TP @" ;
            res=OrderModify(OrderTicket(),OrderOpenPrice(),0,0,0,Blue);
          }
          mode += " Order " +(string) OrderTicket();
         if(!res)
            Print("Error in OrderModify OP_SELL . Error code=",ErrorDescription(GetLastError()),mode);
         else
            Print("Order modified successfully. OP_SELL", mode);
       }
   } else if(direction == OP_SELL){
      for(int i=0;i<OrdersTotal();i++)
      {
         if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES) == false) continue;
         if(OrderSymbol()==Symbol()&&(OrderMagicNumber()==MagicNumber))
          {
            if( _BLots == 0.0 ){
               if((OrderOpenPrice()-Ask) >= TakeProfit ){
                  mode = " Close ";
                  res = OrderClose(OrderTicket(),OrderLots(),Ask,3,White);
                  }
               else{
                  mode = " Change TP ";
                  res=OrderModify(OrderTicket(),OrderOpenPrice(),0,NormalizeDouble(OrderOpenPrice()-break_even,Digits),0,Blue);
                  } 
            }
            else if ( _BLots > 0.0 ){
               if(OrderType()==OP_BUY){ //StopLoss
                  mode = " OrderBUY SL @" + (string) NormalizeDouble(Bid-break_even,Digits);
                  res=OrderModify(OrderTicket(),OrderOpenPrice(),NormalizeDouble(Bid-break_even,Digits),0,0,Blue);
               }else if(OrderType()==OP_SELL){ //Tp
                  mode = " OrederSell TP @" + (string) NormalizeDouble(Ask-break_even,Digits);
                  res=OrderModify(OrderTicket(),OrderOpenPrice(),0,NormalizeDouble(Ask-break_even,Digits),0,Blue);
               }
              }
            mode += " Order " +(string) OrderTicket();
            if(!res)
               Print("Error in OrderModify OP_SELL . Error code=",ErrorDescription(GetLastError()),mode);
            else
               Print("Order modified successfully. OP_SELL", mode);
            
         }
      }
    }
   else if(direction == OP_BUY){
      for(int i=0;i<OrdersTotal();i++)
      {
         if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES) == false) continue;
         if(OrderSymbol()==Symbol()&&(OrderMagicNumber()==MagicNumber)){
            if( _SLots == 0.0 ){ //Close Buy Order
               if((Bid+OrderOpenPrice()) >= TakeProfit ){
                  mode = " Close ";
                  res = OrderClose(OrderTicket(),OrderLots(),Bid,3,Yellow);
               } else {
                  mode = " Change TP ";
                  res=OrderModify(OrderTicket(),OrderOpenPrice(),0,NormalizeDouble(OrderOpenPrice()+break_even,Digits),0,Blue);
               }
            }
            else if(_SLots > 0.0 ){
               if(OrderType()==OP_BUY){ //Tp
                  mode = " Tp @" + (string) NormalizeDouble(Bid+break_even,Digits);
                  res=OrderModify(OrderTicket(),OrderOpenPrice(),0,NormalizeDouble(Bid+break_even,Digits),0,Blue);
               }else if(OrderType()==OP_SELL){ //StopLoss
                  mode = " SL @" + (string) NormalizeDouble(Ask+break_even,Digits);
                  res=OrderModify(OrderTicket(),OrderOpenPrice(),NormalizeDouble(Ask+break_even,Digits),0,0,Blue);
               }
            }
            mode += " Order " +(string) OrderTicket();
            if(!res)
                 Print("Error in OrderModify OP_BUY. Error code=",ErrorDescription(GetLastError()),mode);
            else
                 Print("Order modified successfully. OP_BUY ", mode);
          }
      }
   }
   return(0);
}



//+------------------------------------------------------------------+

void _Close_all() 
{
   for(int i=0;i<OrdersTotal();i++)
      {
      bool res = true;
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES) == false){ 
         Print("Order Not Selected", i," Error", ErrorDescription(GetLastError()));
      continue;}
      if(OrderSymbol()==Symbol() &&(OrderMagicNumber()==MagicNumber)){   
               if (OrderType()>OP_SELL)   res = OrderDelete(OrderTicket());
               if (OrderType()==OP_SELL)  res = OrderClose(OrderTicket(),OrderLots(),Ask,3,CLR_NONE); 
               if (OrderType()==OP_BUY)   res = OrderClose(OrderTicket(),OrderLots(),Bid,3,CLR_NONE); //MarketInfo(OrderSymbol(),MODE_ASK)
            if(!res)
               Print("Error in OrderCloase _Close_all. Error code=",ErrorDescription(GetLastError()),OrderType());
            else
               Print("Order Closed successfully. _Close_all ");
         }
      }
 }
 
