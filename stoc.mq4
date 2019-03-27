//+------------------------------------------------------------------+
//|                                                      Mansour.mq4 |
//|                                            Mohamed Mansour Beek. |
//|                                          https://www.mansour.com |
//+------------------------------------------------------------------+
#property copyright "Stocastic Round 1."
#property link      "https://www.DasStack.com"
#property version   "1.1"
#property strict

/********************************************************************
To do
- [ ] Close with Sell 
*********************************************************************

Day < 20 Main over Signal => Buy
Day > 80 Signal over Main => sell

4H Buy Main over Signal < 50 => Buy Lot
4H Sell Signal over Main > 50 => Sell Lot




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
extern bool Log_all                    = true;
extern bool Log_trades                 = true;
extern string PS_Ex8                   = ">> Squares ";
extern double Squares                  = 70;
extern color color1                    = Green;
extern int width1                      = 1;
extern int style1                      = 0;
extern string PS_Ex9                   = ">> Init Signal 0 None 1 Buy 2 Sell";
extern int initSignal                  = 0; //Initial Signal

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
     //timer = Hour() + ":0" + Minute();
     //RealPoint = 0.0001
//---
  //createSq();
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

  int start()
  {

   int iLoFrame = PERIOD_M30;
   int iHiFrame = PERIOD_H4;
   int iMainFrame = PERIOD_D1;
   BarD = IsBarClosed(iMainFrame,2);
   BarH = IsBarClosed(iHiFrame,1) ;
   BarM = IsBarClosed(iLoFrame,0);

   comment = "";
   comment_trade = "";
   RefreshRates();
    order_check();
   return 0;
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
int Order_Stoc = initSignal;

int UpperThreshold=80;          //Upper Threshold, default 80
int LowerThreShold=20;          //Lower Threshold, default 20
int CenterThreShold=50;          //Lower Threshold, default 20
double StochPrevMain1,StochPrevSig1,StochPrevMain,StochPrevSig,StochCurrMain,StochCurrSig;
double StochPrevMainM,StochPrevSigM,StochCurrMainM,StochCurrSigM;
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
   StochPrevMain1=iStochastic(Symbol(),PERIOD_D1,5,3,3,MODE_SMA,STO_LOWHIGH,MODE_BASE,2);
   StochPrevSig1=iStochastic(Symbol(),PERIOD_D1,5,3,3,MODE_SMA,STO_LOWHIGH,MODE_SIGNAL,2);
   StochPrevMain=iStochastic(Symbol(),PERIOD_D1,5,3,3,MODE_SMA,STO_LOWHIGH,MODE_BASE,1);
   StochPrevSig=iStochastic(Symbol(),PERIOD_D1,5,3,3,MODE_SMA,STO_LOWHIGH,MODE_SIGNAL,1);
   StochCurrMain=iStochastic(Symbol(),PERIOD_D1,5,3,3,MODE_SMA,STO_LOWHIGH,MODE_BASE,0);
   StochCurrSig=iStochastic(Symbol(),PERIOD_D1,5,3,3,MODE_SMA,STO_LOWHIGH,MODE_SIGNAL,0);
   Comment(StochPrevMain," ",StochPrevSig," ",StochCurrMain," ",StochCurrSig);
   bool over = (StochCurrMain>UpperThreshold || StochCurrSig>UpperThreshold || StochPrevMain>UpperThreshold || StochPrevSig>UpperThreshold);
   bool under = (StochCurrSig<LowerThreShold || StochCurrMain<LowerThreShold || StochPrevMain<LowerThreShold || StochPrevSig<LowerThreShold);
   
	   if( (StochPrevMain1>StochPrevSig1 || StochPrevMain>StochPrevSig) && StochCurrMain<StochCurrSig  && over ){
	      Order_Stoc=SIGNAL_SELL;
        Comment("Sell");
	   }else if( (StochPrevMain<StochPrevSig || StochPrevMain1<StochPrevSig1) && StochCurrMain>StochCurrSig  && under ){
	      Order_Stoc=SIGNAL_BUY;
        Comment("Buy");
	   }
   }

   if(BarH){ 
   StochPrevMainM=iStochastic(Symbol(),PERIOD_H4,5,3,3,MODE_SMA,STO_LOWHIGH,MODE_BASE,1);
   StochPrevSigM=iStochastic(Symbol(),PERIOD_H4,5,3,3,MODE_SMA,STO_LOWHIGH,MODE_SIGNAL,1);
   StochCurrMainM=iStochastic(Symbol(),PERIOD_H4,5,3,3,MODE_SMA,STO_LOWHIGH,MODE_BASE,0);
   StochCurrSigM=iStochastic(Symbol(),PERIOD_H4,5,3,3,MODE_SMA,STO_LOWHIGH,MODE_SIGNAL,0);
   // Comment("M",StochPrevMainM,StochPrevSigM,StochCurrMainM,StochCurrSigM);
	   if(StochPrevMainM>StochPrevSigM && StochCurrMainM<StochCurrSigM  &&  (StochCurrMainM>CenterThreShold || StochCurrSigM>CenterThreShold) && Order_Stoc==SIGNAL_SELL){
	      Sell_normal (LotSize,TakeProfit); 
	   }else if(StochPrevMainM<StochPrevSigM && StochCurrMainM>StochCurrSigM  && (StochCurrMainM<CenterThreShold || StochCurrSigM<CenterThreShold)  && Order_Stoc==SIGNAL_BUY){
	      Buy_normal (LotSize,TakeProfit);
	   }
    // print(false);

   }

  return (0);
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
// Timing
bool BarM,BarH,BarD;
bool Max_Spread_Reached;
// Conditions ADX
bool buy_condition_M,sell_condition_M ;
bool buy_condition_H,sell_condition_H ;
bool intersect_M_to_Buy,intersect_M_to_Sell;
bool intersect_H_to_Sell,intersect_H_to_Buy ;
// Main Filters
bool buy_condition_H1,sell_condition_H1 ;
bool buy_condition_H4,sell_condition_H4;

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

void takeEq(){
if(_SLots > _Buys ){
  Buy_double(_SLots-_BLots);
}
if(_SLots < _Buys ){
  Sell_double(_BLots-_SLots);
}

}
