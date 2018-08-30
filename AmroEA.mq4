//+------------------------------------------------------------------+
//|                                                           mm.mq4 |
//|                                            Mohamed Mansour Beek. |
//|                                          https://www.mansour.com |
//+------------------------------------------------------------------+
#property copyright "Mohamed Mansour Beek."
#property link      "https://www.mansour.com"
#property version   "1.00"
#property strict

//---- Dependencies
#import "stdlib.ex4"
   string ErrorDescription(int e);
#import

extern int MagicNumber                 = 22445511;

#include "amro.mq4"

/****************************************************/
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- create timer
  EventSetTimer(60);
  RealPoint = RealPipPoint(Symbol());
  Signal = -1;
//---
   return(INIT_SUCCEEDED);
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
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//--- destroy timer
   EventKillTimer();
      
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   //Print( "Tick" );
   int box = 0 ;
   RefreshRates();
   bool BarH = IsBarClosed(PERIOD_H1,0) ;
   Total_orders(BarH);
   if(BarH){
      RefreshRates();
    double open = iOpen(NULL,PERIOD_H1,1);
      Amro();
      if(Bid > LL[1]){
        Signal = OP_BUY;
      }else if(Bid < HL[10]){
        Signal = OP_SELL;
      }

   for(int ii = 1 ; ii < 10; ii++){
      if ((open > LL[ii-1] )&& (open < LL[ii]) && (Bid > LL[ii]) ){
               // Place Order
             Comment( "SQ" , (string) ii , " Open " , open ," Bid " , Bid , " LL ", LL[ii-1] ," - ", LL[ii] );
             Print( "SQ" , (string) ii );
        if (Signal == OP_BUY && _Buy == 0 ){         
             Print( "Place Order Buy" );
             if (OrderSend( Symbol(), OP_BUY, 0.01, Ask, 5, 0 ,LL[ii+1] , "Buy Order" , MagicNumber,0, clrBlue) == -1)
             {
                 Print("Error order Buy "+(string)ErrorDescription(GetLastError()) );
                 //print();   
             }
            }
            break;
        }
   }
   for(int ii = 10 ; ii < 18; ii++){
     if ( (open < HL[ii-1]) && (open > HL[ii]) && (Bid <  HL[ii])){
             // Place Order
             Comment( "SQ" , (string) ii , " Open " , open ," Bid " , Bid , " LL ", HL[ii-1] ," - ", HL[ii] );
             Print( "SQ" , (string) ii );
             if (Signal == OP_SELL && _Sell == 0){
                 Print( "Place Order Sell" );
                 if (OrderSend( Symbol(), OP_SELL, 0.01, Bid, 5, 0, HL[ii+1], "Sell Order", MagicNumber,0, clrRed) == -1)
                {
                   Print("Error order Buy "+(string)ErrorDescription(GetLastError()) );
                   //print();   
                }
              }
         break;
         }
    }

    
   

   }
  }
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
//---
   
  }
//+------------------------------------------------------------------+

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
int _CountOrd, _Buy, _Sell;
double _SLots,_BLots;
double _SProfit, _BProfit;
double profit;
bool _q;

void Total_orders(bool P = true)
{
   _CountOrd=0;_Buy=0;_Sell=0;
   _SLots = 0.0; _BLots =0.0;
   profit = 0.0;
   _BProfit = 0.0; _SProfit = 0.0;
   double max = 0;
   double min = 1000;
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
            if(OrderOpenPrice() > max){
               max = OrderOpenPrice();
            }   
         }else if(OrderType()==OP_SELL){
            _CountOrd++;
            _Sell++;
            _SLots += OrderLots();
            _SProfit += OrderProfit()+OrderCommission()+OrderSwap();
            if(OrderOpenPrice() < min){
               min = OrderOpenPrice();
            }
         }
         profit+=OrderProfit()+OrderCommission()+OrderSwap();
      }
   }
   if(max != 0 && min != 1000){
    double sp = MarketInfo(Symbol(),MODE_SPREAD);
    double dif = (max - min) / RealPoint;
   } else {
    _q = true;
   }
   if(P){
      Print("Total " + IntegerToString( _CountOrd) 
      + " Buy " + IntegerToString(_Buy) + " = " + (string) _BLots 
      + " Sell " + IntegerToString(_Sell) + " = " + (string) _SLots 
      + " Profit " + (string) profit
      );
    }
}

