//+------------------------------------------------------------------+
//|                                                      Mansour.mq4 |
//|                                            Mohamed Mansour Beek. |
//|                                          https://www.mansour.com |
//+------------------------------------------------------------------+
#property copyright "Stocastic EA."
#property link      "https://www.DasStack.com"
#property version   "1.6"
#property strict

/********************************************************************
To do
- [ ] Close with Sell 
**********************************************************************/

/********************************************************************
#### Actions ### 
Buy|Sell
Buy|Sell Equal
Buy|Sell Double
CloseAll; Profit
Close Buy|Sell Profit
Close Now
*********************************************************************
### Inpust ###
Orders Details => total Buy Sell Profit  ,.....
Current Square
Top Sq Buy|Sell => determine 3 states Inside|OverBuy|UnderSell => % 
*********************************************************************
check all frames 2 up and 1 new closed up => buy 

**********************************************************************/


//---- Dependencies
#import "stdlib.ex4"
   string ErrorDescription(int e);
#import

#include "helpers.mq4"



// External variables
extern string PS_Ex0                   = ">> Lot Size TP SL";
extern double LotSize                  = 0.01;
extern double DoubleFactor             = 2;
extern double StopLoss                 = 0;
extern int    adxMainLimit             = 20;
extern double TakeProfit               = 500;
extern double TakeProfitZero           = 100;
extern double TakeProfitDolar          = 2.0;
extern double TakeProfitLoss           = -100.0;
extern double Max_Spread               = 35;
extern bool STOCASTIC                  = false;
extern string PS_Ex1                   = ">> Timing and Graph";
extern int shift                       = 1;
extern int MagicNumber                 = 224455;
extern string PS_Ex2                   = ">> Entry strategy";
extern bool disableSar                 = true;
extern double TradeStep                = 0.002;
extern double TradeMax                 = 0.2;
extern string PS_Ex3                   = ">> Exit strategy";
extern double StopStep                 = 0.004;
extern double StopMax                  = 0.4;    
extern string PS_Ex4                   = ">> Close diff When Small frame change ";
extern bool Close_Reverse              = false;
extern double Min_reverse_lot          = 0.0;
extern double Max_reverse_lot          = 100.0;          
extern string PS_Ex5                   = ">> Sum Profit and Close other ";
extern bool Close_Profit               = false;
extern double Min_close_lot            = 0.0;
extern double Max_close_lot            = 100.0;
extern string PS_Ex6                   = ">> Close Rev HiFrame change ";
extern bool Close_Reverse_Hi           = false;
extern double Min_reverse_Hi_lot       = 0.0;
extern double Max_reverse_Hi_lot       = 100.0; 
extern string PS_Ex7                   = ">> File ";
extern string InpFileName              ="Mansour";       // File name
extern string InpDirectoryName         ="Data";     // Folder name
extern bool Log_all                    = false;
extern bool Log_trades                 = false;
extern string PS_Ex8                   = ">> Squares ";
extern double Squares                  = 70;
extern color color1                    = Green;
extern int width1                      = 1;
extern int style1                      = 0;
extern string PS_Ex9                   = ">> init Signal 0 Buy 1 Sell ";
extern int initSignal                  = 0;

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
  Signal = initSignal;
  createSq();
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

double adxPlsHi,adxMinusHi;
double adxPlsHi1,adxMinusHi1;
double adxMinusLo,adxPlsLo;
double adxMinusLo1,adxPlsLo1;
double adxMinusH1,adxPlsH1;
double adxMinusH11,adxPlsH11;
double adxMinusH4,adxPlsH4;
double adxMinusH41,adxPlsH41;
double adxminusM30,adxplsM30;
double adxMain,adxMainH4;

double lastP,lastM,lastH;

// Timing
bool BarM,BarH,BarD;
bool Max_Spread_Reached;
// iSAR
double trade_sar,trade_sar1,stop_sar;
// Bars
double CLOSE,CLOSE1,HIGH,LOW;
// Conditions ADX
bool buy_condition_M,sell_condition_M ;
bool buy_condition_H,sell_condition_H ;
bool intersect_M_to_Buy,intersect_M_to_Sell;
bool intersect_H_to_Sell,intersect_H_to_Buy ;
// Main Filters
bool buy_condition_H1,sell_condition_H1 ;
bool buy_condition_H4,sell_condition_H4;

// Sar
bool Sell_signal, Buy_signal ;

double upLo,downLo,upHi,downHi,upMain,downMain;
double tenkan_sen,kijun_sen,tenkan_sen1,kijun_sen1;
bool intersect_I_to_Sell,intersect_I_to_Buy ;
double stocast,stocatlast;
int Signal;
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
  int start()
  {

   int iLoFrame = PERIOD_M30;
   int iHiFrame = PERIOD_H4;
   int iMainFrame = PERIOD_D1;
   BarD = IsBarClosed(iMainFrame,2);
   BarH = IsBarClosed(iHiFrame,1) ;
   // BarM = IsBarClosed(iLoFrame,0);

   comment = "";
   comment_trade = "";
   RefreshRates();
   if(BarD || (Bid < LL[1]) || (Bid > LL[28]) ){
    createSq();
   }

   Total_orders(false);
         string s = "Status : \n   "+
      " SLt "+ (string) _SLots+                          " BLt "+ (string) _BLots+ "\n" +
      " SL "+ (string) _Sells+                          " BY "+ (string) _Buys+ "\n" +
      " Pft "+ (string) _SProfit+                        " pft "+ (string) _BProfit+ "\n" +
       "SQ "  + (string) _sq + "\n" +
      " SLt "+ (string) _SLot[_sq]+                          " BLt "+ (string) _BLot[_sq] + "\n" +
      " SL "+ (string) _Sell[_sq]+                          " BY "+ (string) _Buy[_sq] + "\n" +
      " Ttl "+ (string) profit +
      "\nH4 " + (string) Current_Hour_Stoc + "H4- " + (string) Hour_Stoc  + " D " + (string) Current_Day_Stoc + " D- " + (string) Day_Stoc
      
      ;
      Comment(s);
   if((profit >= TakeProfitDolar && Closing==1 )){ //@ Break Even
      Print("### Close All ####");
      _Close_all();
      Closing = 0;
      Total_orders();
    } 
   order_check(); 
   return(0);
   
  }


  //+------------------------------------------------------------------+
//| Order Process                                                   |
//+------------------------------------------------------------------+
bool lastBuy,lastSell;
/*********************************************************************
Day < 20 Main over Signal => Buy
Day > 80 Signal over Main => sell
4H Buy Main over Signal < 50 => Buy Lot
4H Sell Signal over Main > 50 => Sell Lot
**********************************************************************/
#define SIGNAL_NONE 0
#define SIGNAL_BUY   1
#define SIGNAL_SELL  2
#define SIGNAL_CLOSEBUY 3
#define SIGNAL_CLOSESELL 4
int Day_Stoc = initSignal;
int Current_Day_Stoc = SIGNAL_NONE ;
int Hour_Stoc = SIGNAL_NONE;
int Current_Hour_Stoc = SIGNAL_NONE;

int UpperThreshold=80;          //Upper Threshold, default 80
int LowerThreShold=20;          //Lower Threshold, default 20
int CenterThreShold=50;          //Lower Threshold, default 20
double StochPrevMain1,StochPrevSig1,StochPrevMain,StochPrevSig,StochCurrMain,StochCurrSig;
double StochPrevMainM1,StochPrevSigM1,StochPrevMainM,StochPrevSigM,StochCurrMainM,StochCurrSigM;
int order_check()
{  
  //Print("NowDIPlus="+adxPlsLo+" NowDIMinus="+adxMinusLo+" PrevDIPlus="+adxPlsLo1+" PrevDIMinus="+adxMinusLo1);
   // Lo Frame                        
   /*
  in sell case
  Day frame : signal > main and touch 80 level
  H4 frame: Signal > main above 50level
  */
   if(BarD){
	   RefreshRates();
	   StochPrevMain1=iStochastic(Symbol(),PERIOD_D1,5,3,3,MODE_SMA,STO_LOWHIGH,MODE_BASE,3);
	   StochPrevSig1=iStochastic(Symbol(),PERIOD_D1,5,3,3,MODE_SMA,STO_LOWHIGH,MODE_SIGNAL,3);
	   StochPrevMain=iStochastic(Symbol(),PERIOD_D1,5,3,3,MODE_SMA,STO_LOWHIGH,MODE_BASE,2);
	   StochPrevSig=iStochastic(Symbol(),PERIOD_D1,5,3,3,MODE_SMA,STO_LOWHIGH,MODE_SIGNAL,2);
	   StochCurrMain=iStochastic(Symbol(),PERIOD_D1,5,3,3,MODE_SMA,STO_LOWHIGH,MODE_BASE,1);
	   StochCurrSig=iStochastic(Symbol(),PERIOD_D1,5,3,3,MODE_SMA,STO_LOWHIGH,MODE_SIGNAL,1);
	   //Comment(StochPrevMain," ",StochPrevSig," ",StochCurrMain," ",StochCurrSig);
	   bool over = (StochCurrMain>UpperThreshold || StochCurrSig>UpperThreshold || StochPrevMain>UpperThreshold || StochPrevSig>UpperThreshold);
	   bool under = (StochCurrSig<LowerThreShold || StochCurrMain<LowerThreShold || StochPrevMain<LowerThreShold || StochPrevSig<LowerThreShold);
	   
	     if( (StochPrevMain1>StochPrevSig1 || StochPrevMain>StochPrevSig) && StochCurrMain<StochCurrSig  && over ){
	        Day_Stoc=SIGNAL_SELL;
	        Current_Day_Stoc = SIGNAL_SELL;
	        ObjectCreate("Sell"+(string)Time[0], OBJ_VLINE, 0, Time[0],0);
	        ObjectSet("Sell"+(string)Time[0], OBJPROP_COLOR, Red);
	        //Comment("Sell");
	     }else if( (StochPrevMain<StochPrevSig || StochPrevMain1<StochPrevSig1) && StochCurrMain>StochCurrSig  && under ){
	        Day_Stoc=SIGNAL_BUY;
	        Current_Day_Stoc = SIGNAL_BUY;
	        ObjectCreate("Buy"+(string) Time[0], OBJ_VLINE, 0, Time[0],0);
	        ObjectSet("Buy"+(string)Time[0], OBJPROP_COLOR, Blue);
	        //Comment("Buy");
	     }else if( (StochCurrMain<StochCurrSig) && Day_Stoc == SIGNAL_SELL ){
	     	Day_Stoc=SIGNAL_NONE;
	     	Day_change=1;
	     	ObjectCreate("OUT"+(string) Time[0], OBJ_VLINE, 0, Time[0],0);
	        ObjectSet("OUT"+(string)Time[0], OBJPROP_COLOR, Orange);
	     }else if( (StochCurrMain>StochCurrSig)  && Day_Stoc == SIGNAL_BUY ){
	     	Day_Stoc=SIGNAL_NONE;
	     	Day_change=1;
	     	ObjectCreate("OUT"+(string) Time[0], OBJ_VLINE, 0, Time[0],0);
	        ObjectSet("OUT"+(string)Time[0], OBJPROP_COLOR, Yellow);
	     }
	     if (StochCurrMain<StochCurrSig  && (StochCurrMain>CenterThreShold || StochCurrSig>CenterThreShold)){
	     	Current_Day_Stoc = SIGNAL_SELL;
	     	Day_change=1;
	     }else if (StochCurrMain>StochCurrSig  && (StochCurrSig<CenterThreShold || StochCurrMain<CenterThreShold)){
	     	Current_Day_Stoc = SIGNAL_BUY;
	     	Day_change=1;
	     }else {
	     	Current_Day_Stoc = SIGNAL_NONE;
	     }
   }

   if(BarH){ 
	   StochPrevMainM=iStochastic(Symbol(),PERIOD_H4,5,3,3,MODE_SMA,STO_LOWHIGH,MODE_BASE,2);
	   StochPrevSigM=iStochastic(Symbol(),PERIOD_H4,5,3,3,MODE_SMA,STO_LOWHIGH,MODE_SIGNAL,2);
	   StochCurrMainM=iStochastic(Symbol(),PERIOD_H4,5,3,3,MODE_SMA,STO_LOWHIGH,MODE_BASE,1);
	   StochCurrSigM=iStochastic(Symbol(),PERIOD_H4,5,3,3,MODE_SMA,STO_LOWHIGH,MODE_SIGNAL,1);
	   //bool over = (StochCurrMainM>UpperThresholdM || StochCurrSigM>UpperThresholdM || StochPrevMainM>UpperThresholdM || StochPrevSigM>UpperThresholdM);
	   //bool under = (StochCurrSigM<LowerThreSholdM || StochCurrMainM<LowerThreSholdM || StochPrevMainM<LowerThreSholdM || StochPrevSigM<LowerThreShold);
		if(StochPrevMainM>StochPrevSigM && StochCurrMainM<StochCurrSigM  &&  (StochCurrMainM>CenterThreShold || StochCurrSigM>CenterThreShold)){
			Hour_Stoc = SIGNAL_SELL;
		}else if(StochPrevMainM<StochPrevSigM && StochCurrMainM>StochCurrSigM  && (StochCurrMainM<CenterThreShold || StochCurrSigM<CenterThreShold)){
			Hour_Stoc = SIGNAL_BUY;
		}else {
			Hour_Stoc = SIGNAL_NONE;
		}

		if(StochCurrMainM<StochCurrSigM ){
			Current_Hour_Stoc = SIGNAL_SELL;
		}else if (StochCurrMainM>StochCurrSigM) {
			Current_Hour_Stoc = SIGNAL_BUY;
		}else {
			Current_Hour_Stoc = SIGNAL_NONE;

		}


		Total_orders(true);
   		Ordering ();

   }

 
  return (0);
 }
int Day_change=0;int Closing = 0;
 void Ordering (){
      if((Hour_Stoc == SIGNAL_BUY) && (Day_Stoc == SIGNAL_BUY) &&(Current_Day_Stoc == SIGNAL_BUY) && (_Buy[_sq] < 1)  ){ //Real buy now + ADX Buy
          Buy_normal (LotSize,TakeProfit);          
        if(_Sells>0){
        	_Update(OP_BUY,true);  
        }       
      }else if((Hour_Stoc == SIGNAL_SELL) && (Day_Stoc == SIGNAL_SELL) &&(Current_Day_Stoc == SIGNAL_SELL) && (_Sell[_sq] < 1) ){ // REal SEll now + adx Sell
          Sell_normal (LotSize,TakeProfit); 
        if(_Buys>0) {
          _Update(OP_SELL,true);    
        }
      }else if( ((Current_Day_Stoc != SIGNAL_BUY) || (Day_Stoc != SIGNAL_BUY)) && (_Buys >= LotSize) ){
        _Close(OP_BUY,0);   Day_change = 0;
        _Update(OP_BUY,true);
        Closing = 1;         
      }else if( ((Current_Day_Stoc != SIGNAL_SELL) || (Day_Stoc != SIGNAL_SELL)) && (_Sells >= LotSize) ){
        _Close(OP_SELL,0); Day_change = 0;
        _Update(OP_SELL,true); 
        Closing = 1;  
      }

      if((Hour_Stoc == SIGNAL_BUY) &&  (_Buys >= LotSize) && ((Current_Day_Stoc != SIGNAL_BUY) || (Day_Stoc != SIGNAL_BUY))  ){ //Real buy now + ADX Buy
          Buy_normal (LotSize,TakeProfit);          
          _Update(OP_BUY,true);
          Closing = 1;
      }else if((Hour_Stoc == SIGNAL_SELL) && (_Sells >= LotSize) && ((Current_Day_Stoc != SIGNAL_SELL) || (Day_Stoc != SIGNAL_SELL)) ){ // REal SEll now + adx Sell
          Sell_normal (LotSize,TakeProfit); 
          _Update(OP_SELL,true);   
          Closing = 1; 
      }
       print(false);

 	/*
 	if(Sell_ && (Signal == OP_BUY) && _Buys ){
        // Print("### Close All ####");
        // _Close_all();
        // Sell_normal (2*LotSize,TakeProfit);          
        Signal = OP_SELL;
        Sell_double(0);
        _Update(OP_BUY,false); 
        Total_orders();
        lastBuy = Buy_;
        lastSell = Sell_;
        return(0);
      }
      if((Buy_) && (Signal == OP_SELL) && _Sells ){
        // Print("### Close All ####");
        // _Close_all();
        // Buy_normal (2*LotSize,TakeProfit);          
         
        Signal = OP_BUY;
        Buy_double(0);
        _Update(OP_BUY,false); 
        Total_orders();
        lastBuy = Buy_;
        lastSell = Sell_;
        return(0);
      }
      if(Buy_ ){
        Signal = OP_BUY;
      }else if (Sell_){
        Signal = OP_SELL;
      }
      */

      /*
      else if ( Order == SIGNAL_BUY && (Signal == OP_BUY) && (_Buy[_sq] < 1)  ){
          Buy_normal (LotSize,100); 
          if(_Sells>0) 
              _Update(OP_SELL,false);  
      }else if (Order == SIGNAL_SELL && (Signal == OP_SELL) && (_Sell[_sq] < 1) ){
          Sell_normal (LotSize,100); 
          if(_Buys>0)  
            _Update(OP_SELL,false); 
      }*/

      //lastBuy = Buy_;
      //lastSell = Sell_;
  //if( (profit <= TakeProfitLoss ) && (Bid > max_q || Bid < min_q)){ //@ Break Even
    //if(_SProfit <= TakeProfitLoss || _BProfit <= TakeProfit)
      //takeEq();
  // }
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
    static datetime lastbartime[4];
    if(iTime(NULL,timeframe,1)==lastbartime[index]) // wait for new bar
        return(false);
    lastbartime[index]=iTime(NULL,timeframe,1);
    return(true);
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
    double diff =  prft + OrderProfit() - (RealPoint * MarketInfo(Symbol(),MODE_SPREAD) );
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
   Total_orders(true);
   double break_even = 0.0;
   if(_Sells > 0.0 && _Buys > 0.0 && (_SLots != _BLots)){
     break_even = MathAbs(RealPoint * profit / (_BLots - _SLots));
     break_even += (RealPoint * TakeProfitZero);
   } else if((_Sells > 0.0 || _Buys > 0.0) && (_SLots != _BLots)) { // Only Sell OR Buy
     //break_even = RealPoint * TakeProfit;
     break_even = MathAbs(RealPoint * profit / (_BLots - _SLots));
     break_even += (RealPoint * TakeProfitZero);
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
                  // OrderModify( int ticket, dbl price, dbl stoploss, dbl takeprofit, dtt expiration, clr color=CLR_NONE )
                  double sl = Bid + 10000*RealPoint;
                  res=OrderModify(OrderTicket(),OrderOpenPrice(),sl,NormalizeDouble(Ask-break_even,Digits),0,Blue);
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
                  double sl = Bid - 10000*RealPoint;
                  res=OrderModify(OrderTicket(),OrderOpenPrice(),sl,NormalizeDouble(Bid+break_even,Digits),0,Blue);
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
//| Draw ind create Qu Orders function                               |
//+------------------------------------------------------------------+

void createSq(){
  for( int i = 0; i < 30; i++ ){ 
    ObjectDelete(string(i));
  }
  for( int i = 0; i < 15 ; i++ ){ 
    string ii = string (i);
    double p1 = Bid - ((15-i)*Squares*RealPoint);
    if(i == 0){
      p1 = Bid - ((100)*Squares*RealPoint);
    }
    LL[i] = p1;
     ObjectCreate(ii,OBJ_TREND,0,0,0,0,0);
     ObjectSet(ii,OBJPROP_PRICE1,p1);
     ObjectSet(ii,OBJPROP_TIME1,StrToTime(TimeToStr(Time[0],TIME_DATE)+" "+"00:00"));
     ObjectSet(ii,OBJPROP_PRICE2,p1);
     ObjectSet(ii,OBJPROP_TIME2,StrToTime(TimeToStr(Time[0],TIME_DATE)+" "+"23:00"));
     //if(i>0)
      ObjectSet(ii,OBJPROP_RAY,false);
     //else
     // ObjectSet(ii,OBJPROP_RAY,true);
     if((i%5) ==0 )
     ObjectSet(ii,OBJPROP_COLOR,Blue);
     else
     ObjectSet(ii,OBJPROP_COLOR,color1);
     ObjectSet(ii,OBJPROP_WIDTH,width1);
     ObjectSet(ii,OBJPROP_STYLE,style1);
     ObjectSet(ii,OBJPROP_BACK,true);
     string sObjDesc = ii;  
     ObjectSetText(ii, sObjDesc,10,"Times New Roman",Black);
  }
  for( int i = 15; i < 30 ; i++ ){ 
    string ii = string (i);
    double p1 = Bid + ((i-15)*Squares*RealPoint);
    if(i == 29){
      p1 = Bid + ((100)*Squares*RealPoint);
    }
    LL[i] = p1;
     ObjectCreate(ii,OBJ_TREND,0,0,0,0,0);
     ObjectSet(ii,OBJPROP_PRICE1,p1);
     ObjectSet(ii,OBJPROP_TIME1,StrToTime(TimeToStr(Time[0],TIME_DATE)+" "+"00:00"));
     ObjectSet(ii,OBJPROP_PRICE2,p1);
     ObjectSet(ii,OBJPROP_TIME2,StrToTime(TimeToStr(Time[0],TIME_DATE)+" "+"23:00"));
     ObjectSet(ii,OBJPROP_RAY,false);
     if((i%5) ==0 )
      ObjectSet(ii,OBJPROP_COLOR,Red);
     else
      ObjectSet(ii,OBJPROP_COLOR,color1);
     ObjectSet(ii,OBJPROP_WIDTH,width1);
     ObjectSet(ii,OBJPROP_STYLE,style1);
     ObjectSet(ii,OBJPROP_BACK,true);
     string sObjDesc = ii;  
     ObjectSetText(ii, sObjDesc,10,"Times New Roman",Black);
  }
}
//+------------------------------------------------------------------+
//| Totals function                                                  |
//+------------------------------------------------------------------+

int _CountOrd,_sq;
int _Buys, _Sells, _Buy[30], _Sell[30];
double _SLots, _BLots, _SLot[30], _BLot[30];
double _SProfit, _BProfit;
double profit;
bool _q,max_q,min_q;
double LL[30];
void Total_orders(bool P = true)
{
   _CountOrd=0;
   for (int i =0;i<30 ;i++){
   _Buy[i]=0;_Sell[i]=0;
   _SLot[i]=0;_BLot[i]=0;
   }
   _SLots = 0.0; _BLots =0.0;
   _Buys=0;_Sells=0;
   profit = 0.0;
   _BProfit = 0.0; _SProfit = 0.0;
   double max = 0;
   double min = 1000;
   RefreshRates();
    for (int ii = 0;ii<29;ii++){
      if((Bid > LL[ii]) && Bid < LL[ii+1]){
          _sq = ii;
      }
    }
   for(int i=0;i<OrdersTotal();i++)
   {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES) == false) continue;
      if( (OrderSymbol()==Symbol()) && (OrderMagicNumber()==MagicNumber) )
      {
         if(OrderType()==OP_BUY){
            _CountOrd++;
            _BLots += OrderLots();
            _Buys++;
            _BProfit += OrderProfit()+OrderCommission()+OrderSwap();
            if(OrderOpenPrice() > max_q){
              max_q = OrderOpenTime();
            }
            for(int ii = 0 ; ii < 29; ii++){
            if ((OrderOpenPrice() > LL[ii] ) && (OrderOpenPrice() < LL[ii+1])){
              _Buy[ii]++;
              _BLot[ii] += OrderLots();
              }
            }
         }else if(OrderType()==OP_SELL){
            _CountOrd++;
            _Sells++;
            _SLots += OrderLots();
            _SProfit += OrderProfit()+OrderCommission()+OrderSwap();
            if(OrderOpenPrice() < min_q){
              min_q = OrderOpenTime();
            }
            for(int ii = 0 ; ii < 29; ii++){
              if ( (OrderOpenPrice() > LL[ii]) && (OrderOpenPrice() < LL[ii+1]) ){
              _Sell[ii]++;
              _SLot[ii] += OrderLots();
              }
            }
         }
         profit+=OrderProfit()+OrderCommission()+OrderSwap();
      }
    }
   if(P)
      Print("Total " + IntegerToString( _CountOrd) 
      + " Buy " + IntegerToString(_Buys) + " = " + (string) _BLots 
      + " Sell " + IntegerToString(_Sells) + " = " + (string) _SLots 
      + " Profit " + (string) profit
      );
}
//+------------------------------------------------------------------+
//| Take Equivlaent  function                                        |
//+------------------------------------------------------------------+
void takeEq(){
if(_SLots > _Buys ){
  Buy_double(_SLots-_BLots);
}
if(_SLots < _Buys ){
  Sell_double(_BLots-_SLots);
}

}
