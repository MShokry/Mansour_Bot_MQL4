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
// External variables
extern string PS_Ex0                   = ">> Lot Size TP SL";
extern double LotSize                  = 0.01;
extern int    Max_Order                = 1;



double RealPoint;
/******************************************************
- [x] Take order when Touch screen (Box) 
- [x] One order / Square
- [x] Sl when Closed reverse => [ ] Then Take orders to make zero at next level
***************************************************/
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
  /******************* AT Touch ******************************/
  RefreshRates();
  LL[0] = HL[18];
  HL[9] = LL[9];
  if (Signal == OP_SELL){
    for (int ii = 9;ii<19;ii++){
        if((Bid < HL[ii]) && Bid > HL[ii+1]){
          _sq = ii;
        }
    }
  }
  if (Signal == OP_BUY){
    for (int ii = 0;ii<10;ii++){
      if((Bid > LL[ii]) && Bid < LL[ii+1]){
          _sq = ii;
        }
    }
  }

  /******************* AT Touch ******************************/
  double open = iOpen(NULL,PERIOD_H1,0); //Curretn Open Price
  if (Signal == OP_BUY){
      if ((open > LL[1] ) && (Bid <= LL[1]) ){
        if (Signal == OP_BUY && (_Buy[0] < Max_Order &&  _Buy[1] < Max_Order)){         
             Print( "Place Order Buy" );
             if (OrderSend( Symbol(), OP_BUY, LotSize, Ask, 5, 0 ,LL[2] , "Buy Touch @ " + (string) _sq , MagicNumber,0, clrBlue) == -1)
             {
                Print("Error order Buy "+(string)ErrorDescription(GetLastError()) ); 
             }
                print();   
            }
      }
    }else if (Signal == OP_SELL){
      if ((open < HL[10] ) && (Bid >= HL[10]) ){
        if (Signal == OP_SELL && (_Sell[9] < Max_Order) && (_Sell[10] < Max_Order) ){
                 Print( "Place Order Sell" );
                 if (OrderSend( Symbol(), OP_SELL, LotSize, Bid, 5, 0, HL[11], "Sell Touch @ " + (string) _sq, MagicNumber,0, clrBrown) == -1)
                {
                  Print("Error order Sell "+(string)ErrorDescription(GetLastError()) );
                }
                print();   
              }
      }
    }
  Total_orders(BarH);
  /****************** Normal Close ****************************/
  if(BarH){
  RefreshRates();
  print();
  open = iOpen(NULL,PERIOD_H1,1);
  Amro();
  _Update();
  Total_orders(BarH);
  if(Bid > LL[1]){
      Signal = OP_BUY;
      _Close(OP_SELL);
  }else if(Bid < HL[10]){
      Signal = OP_SELL;
      _Close(OP_BUY);
  }

  for(int ii = 1 ; ii < 10; ii++){
      if ((open > LL[ii-1] )&& (open < LL[ii]) && (Bid > LL[ii]) ){
             Print( "SQ" , (string) ii );
             _sq = ii;
        if (Signal == OP_BUY && _Buy[ii] < Max_Order ){         
             Print( "Place Order Buy" );
             if (OrderSend( Symbol(), OP_BUY, LotSize, Ask, 5, 0 ,LL[ii+1] , "Buy Close @ " + (string) _sq , MagicNumber,0, clrBlue) == -1)
             {
                 Print("Error order sell "+(string)ErrorDescription(GetLastError()) );
                 //print();   
             }
            }
            print();
            break;
        }
   }
   for(int ii = 10 ; ii < 18; ii++){
     if ( (open < HL[ii-1]) && (open > HL[ii]) && (Bid <  HL[ii])){
             Print( "SQ" , (string) ii );
             _sq = ii;
             if (Signal == OP_SELL && _Sell[ii] < Max_Order){
                 Print( "Place Order Sell" );
                 if (OrderSend( Symbol(), OP_SELL, LotSize, Bid, 5, 0, HL[ii+1], "Sell Close @ "+ (string) _sq, MagicNumber,0, clrRed) == -1)
                {
                   Print("Error order Buy "+(string)ErrorDescription(GetLastError()) );
                   //print();   
                }
              }
         print();
         break;
         }
    }
   }
  
   print();

  }
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
//---
   
  }
//+------------------------------------------------------------------+
  
void print(bool trade = false){
      Total_orders();
      string s = "Status : \n  "+ 
      "SQ "  + (string) _sq +
      " SLt "+ (string) _Sell[_sq]+                          " BLt "+ (string) _Buy[_sq] + "\n" +
      " SLt "+ (string) _SLots+                          " BLt "+ (string) _BLots+ "\n" +
      " Pft "+ (string) _SProfit+                        " pft "+ (string) _BProfit+ "\n" +
      " Ttl "+ (string) profit ;
      Comment(s);          
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
int _CountOrd, _Buy[30], _Sell[30],_sq;
double _SLots,_BLots;
double _SProfit, _BProfit;
double profit;
bool _q;

void Total_orders(bool P = false)
{
   _CountOrd=0;
   for (int i =0;i<30 ;i++){
   _Buy[i]=0;_Sell[i]=0;
   }
   LL[0] = HL[18];
   HL[9] = LL[9];
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
            _BLots += OrderLots();
            _BProfit += OrderProfit()+OrderCommission()+OrderSwap();
            for(int ii = 0 ; ii < 10; ii++){
            if ((OrderOpenPrice() > LL[ii] )&& (OrderOpenPrice() < LL[ii+1])){
              _Buy[ii]++;
              }
            }
         }else if(OrderType()==OP_SELL){
            _CountOrd++;
            _SLots += OrderLots();
            _SProfit += OrderProfit()+OrderCommission()+OrderSwap();
            for(int ii = 9 ; ii < 18; ii++){
              if ( (OrderOpenPrice() < HL[ii]) && (OrderOpenPrice() > HL[ii+1]) ){
              _Sell[ii]++;

              }
            }
         }
         profit+=OrderProfit()+OrderCommission()+OrderSwap();
      }
   }
   
   if(P){
      Print("Total " + IntegerToString( _CountOrd) 
      + " Buy " , _Buy[_sq] , " = " + (string) _BLots 
      + " Sell " + IntegerToString(_Sell[_sq]) + " = " + (string) _SLots 
      + " Profit " + (string) profit
      );
    }
}

//+-------------------------------------------------------------------+
//| Close Orders function                                             |
//+-------------------------------------------------------------------+    
 void _Close(int direction){
   double price = Ask;
   if(direction == OP_SELL)
       price = Ask;
    else if(direction == OP_BUY)
       price = Bid;
   res = true;
   string c;
   // TP of all 
   for(int i=0;i<OrdersTotal();i++)
      {
         if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES) == false) continue;
         if(OrderSymbol()==Symbol() && OrderType()== direction &&(OrderMagicNumber()==MagicNumber)){
                 res = OrderClose(OrderTicket(),OrderLots(),price,3,clrBrown);
                 c = " Order #"+(string) OrderTicket()+" By Double rev profit: "+(string)  OrderTakeProfit() +" Dir "+(string)  direction + " Lots " +(string)  OrderLots();
                 if(!res){
                     Print("Error in Closing _Close ALL . Error code=", ErrorDescription(GetLastError()) ,c);
                     print();
                  }else{
                     Print("Order Closed _Close ALL successfully." + c );
                     print();
                   }
                Print(c);
            }
      } 
  }
//+-------------------------------------------------------------------+
//| Update  function                                                  |
//+-------------------------------------------------------------------+  
/*
break_even = MathAbs(RealPoint * profit / (_BLots - _SLots));
_BLots = (break_even * _SLots + RealPoint * profit)/break_even
*/

bool res;
void _Update(){
  RefreshRates();
   for(int i=0;i<OrdersTotal();i++)
   {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES) == false) continue;
      if(OrderSymbol()==Symbol()&&(OrderMagicNumber()==MagicNumber))
      {
         if(OrderType()==OP_BUY){
            for(int ii = 0 ; ii < 10; ii++){
              if ((OrderOpenPrice() > LL[ii] )&& (OrderOpenPrice() < LL[ii+1]) && OrderTakeProfit() != LL[ii+1] ){
                  res=OrderModify(OrderTicket(),OrderOpenPrice(),0,LL[ii+1],0,Blue);
                  if(!res)
                     Print("Error in OrderModify OP_BUY . Error code=",ErrorDescription(GetLastError()));
                  else
                     Print("Order modified successfully. OP_BUY to LL " , ii+1);
                }
            }
         }else if(OrderType()==OP_SELL){
            for(int ii = 9 ; ii < 18; ii++){
              if ( (OrderOpenPrice() < HL[ii]) && (OrderOpenPrice() > HL[ii+1]) && OrderTakeProfit() != HL[ii+1] ){
                res=OrderModify(OrderTicket(),OrderOpenPrice(),0,HL[ii+1],0,Blue);
                if(!res)
                   Print("Error in OrderModify OP_SELL . Error code=",ErrorDescription(GetLastError()));
                else
                   Print("Order modified successfully. OP_SELL to HL " , ii+1);
              }
            }
         }
      }
   }
}
