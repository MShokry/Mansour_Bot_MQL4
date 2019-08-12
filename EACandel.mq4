//+------------------------------------------------------------------+
//|                                                   Candles EA.mq4 |
//|                                            Mahmoud Shokry      . |
//|                                         https://www.dasstack.com |
//+------------------------------------------------------------------+
#property copyright "Candles EA."
#property link      "https://www.DasStack.com"
#property version   "1.1"
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
extern double TakeProfit               = 25;
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
extern double Squares                  = 100;
extern color color1                    = Yellow;
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
   int iLoFrame = PERIOD_M30;
   int iHiFrame = PERIOD_H4;//PERIOD_H4;
   int iMainFrame = PERIOD_D1;//PERIOD_D1;  
int start()
  {
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
#define STRONG_BUY   4
#define WEEK_BUY  3
#define WEEK_SELL 2
#define STRONG_SELL 1 

int Day_Stoc = initSignal;
int Current_Day_Stoc = SIGNAL_NONE ;
int Hour_Stoc = SIGNAL_NONE;
int Current_Hour_Stoc = SIGNAL_NONE;

int UpperThreshold=80;          //Upper Threshold, default 80
int LowerThreShold=20;          //Lower Threshold, default 20
int CenterThreShold=50;          //Lower Threshold, default 20
double StochPrevMain1,StochPrevSig1,StochPrevMain,StochPrevSig,StochCurrMain,StochCurrSig;
double StochPrevMainM1,StochPrevSigM1,StochPrevMainM,StochPrevSigM,StochCurrMainM,StochCurrSigM;

int Day_change=0;int Closing = 0;

int old_bus;int old_sells;
int order_check()
{  
  //Print("NowDIPlus="+adxPlsLo+" NowDIMinus="+adxMinusLo+" PrevDIPlus="+adxPlsLo1+" PrevDIMinus="+adxMinusLo1);
   // Lo Frame                        
   /*
  in sell case
  Day frame : signal > main and touch 80 level
  H4 frame: Signal > main above 50level
  */

		Total_orders(true);
    int d1 = CheckBars(PERIOD_D1);
    int h4 = CheckBars(PERIOD_H4);
    int h1 = CheckBars(PERIOD_H1);
    int m30 = CheckBars(PERIOD_M30);
    int m15 = CheckBars(PERIOD_M15);
    int m5 = CheckBars(PERIOD_M5);
    int m1 = CheckBars(PERIOD_M1);
    if(True){
      string s = "Status# : \n   "+
      " Ask "+ (string) Ask+                        " Bid "+ (string) Bid+ "\n" +
      " D1 "+ (string) d1+                          " H4 "+ (string) h4+ "\n" +
      " H1 "+ (string) h1+                          " M30 "+ (string) m30+ "\n" +
      " M15 "+ (string) m15+                        " M5 "+ (string) m5+ "\n" +
      " M1 "+ (string) m1+                          "\n" 
      ;
      Comment(s);
    }

    if((_Buys < old_bus) || (_Sells < old_sells)){
      Sleep( 60000 );
      old_bus = _Buys;
      old_sells = _Sells;
      return 0;
    }
    old_bus = _Buys;
    old_sells = _Sells;

      if( (d1 == SIGNAL_NONE) || (h4 == SIGNAL_NONE) || (h1 == SIGNAL_NONE) || (m30 == SIGNAL_NONE) || (m15 == SIGNAL_NONE) || (m5 == SIGNAL_NONE) || (m1 == SIGNAL_NONE) ){
        return 0;
      }
      if( ((d1+h4) >= (STRONG_BUY + WEEK_BUY)) && (h1 == STRONG_BUY) && (m30 == STRONG_BUY) && (m15 >= WEEK_BUY) && (m5 >= WEEK_BUY) && (m1 >= WEEK_BUY)  && (_Buy[_sq] == 0) && (_Buy[_sq1] == 0) ){ //Real buy now + ADX Buy
          Buy_normal (LotSize,TakeProfit);           
      }else if( ((d1+h4) <= (STRONG_SELL + WEEK_SELL)) && (h1 == STRONG_SELL) && (m30 == STRONG_SELL) && (m15 <= WEEK_SELL) && (m5 <= WEEK_SELL) && (m1 <= WEEK_SELL)  && (_Sell[_sq] == 0) && (_Sell[_sq1] == 0) ){ // REal SEll now + adx Sell
          Sell_normal (LotSize,TakeProfit);
      }
       return 0;
 }

//+------------------------------------------------------------------+
//| Check Bars function                                                   |
//+------------------------------------------------------------------+
int CheckBars(int timeframe)
{
    RefreshRates();
    double high  = iHigh(Symbol(),timeframe,0);
    double low   = iLow(Symbol(),timeframe,0);
    double open  = iOpen(Symbol(),timeframe,0);

    bool askin =  (Ask >= low) && (Ask <= high);
    bool bidin = (Bid >= low) && (Bid <= high);
    bool buy_  = Bid > open;
    bool sell_ = Bid < open;
    if (askin && bidin && buy_) return STRONG_BUY;
    if ( bidin && buy_) return WEEK_BUY;
    if (askin && bidin && sell_) return STRONG_SELL;
    if (bidin && sell_) return WEEK_SELL;
    return SIGNAL_NONE;

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
      ObjectSet(ii,OBJPROP_COLOR,Blue);
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

int _CountOrd,_sq,_sq1;
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
      if((Ask > LL[ii]) && Ask < LL[ii+1]){
          _sq1 = ii;
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
