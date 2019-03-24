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
//| Print Function                                                   |
//+------------------------------------------------------------------+ 
  
void print(bool trade = false){
      Total_orders();
      if(!trade){
      string s = "Status : \n   "+
      " SLt "+ (string) _SLots+                          " BLt "+ (string) _BLots+ "\n" +
      " SL "+ (string) _Sells+                          " BY "+ (string) _Buys+ "\n" +
      " Pft "+ (string) _SProfit+                        " pft "+ (string) _BProfit+ "\n" +
       "SQ "  + (string) _sq + "\n" +
      " SLt "+ (string) _SLot[_sq]+                          " BLt "+ (string) _BLot[_sq] + "\n" +
      " SL "+ (string) _Sell[_sq]+                          " BY "+ (string) _Buy[_sq] + "\n" +
      " Ttl "+ (string) profit ;
      Comment(s);
      ObjectCreate("S1", OBJ_TEXT, 0, 0, 0, 0);
      // Set pixel co-ordinates from top left corner (use OBJPROP_CORNER to set a different corner)
      ObjectSet("S1", OBJPROP_XDISTANCE, 100);
      ObjectSet("S1", OBJPROP_YDISTANCE, 50);
      // Set text, font, and colour for object
      ObjectSetText("S1", s, 10, "Arial", Red);

      Print("Status : BH  ", buy_condition_H ," SH  ", sell_condition_H  ,
             "SQ "  + (string) _sq + "\n" +
      " SLt "+ (string) _SLot[_sq]+                          " BLt "+ (string) _BLot[_sq] + "\n" +
      " SL "+ (string) _Sell[_sq]+                          " BY "+ (string) _Buy[_sq] + "\n" +
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
    string var1=TimeToStr(TimeCurrent(),TIME_DATE|TIME_SECONDS);
     if(Log_all) 
      FileWriteString(file_handle,var1 + str + comment +"\r\n");
     if(Log_trades && trade)
      FileWriteString(file_handle_trade,var1 + str + comment_trade +"\r\n");
}

//+------------------------------------------------------------------+
//| Buy Double Condition                                             |
//+------------------------------------------------------------------+ 
  
 void Buy_double(double Max_Lots)
 {
  if(Close_Reverse_Hi && ((_SLots + _BLots) < Max_reverse_Hi_lot) && ((_SLots + _BLots) > Min_reverse_Hi_lot)){
   // TP of open sell + diff
   _Close(OP_SELL,0);
 }
   // Refesh lots
   Total_orders();
   // open new 2x diff sell 
   double _LotSize = 0.0;
   if(Max_Lots > 0.0)
      _LotSize = Max_Lots;
   else if (_SLots >= _BLots)
      _LotSize = DoubleFactor * ( _SLots - _BLots);
   else if (_BLots > _SLots )
      _LotSize = LotSize;
   
   //Print ("Buying Double "+ (string)_LotSize);
   if(_LotSize > 0){
      if(_Sells){
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
  if(Close_Reverse_Hi && ((_SLots + _BLots) < Max_reverse_Hi_lot) && ((_SLots + _BLots) > Min_reverse_Hi_lot)){
     // TP of open sell + diff
    _Close(OP_BUY,0);
  }
   // Refesh lots
   Total_orders();
   // open new 2x diff sell 
   double _LotSize = 0.0;
   if(Max_Lots > 0.0)
      _LotSize = Max_Lots;
   else if (_BLots >= _SLots )
      _LotSize = DoubleFactor *  (_BLots - _SLots);
   else if (_SLots > _BLots)
      _LotSize = LotSize;
   
   //Print ("Selling Double "+ (string) _LotSize);
   if(_LotSize > 0){
      if(_Buys){
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
         if(OrderSymbol()==Symbol()){
          if(OrderStopLoss() > 0.0){ continue;} 
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
         if(Close_Profit &&( prof> 0.0 )&& ((_SLots + _BLots) < Max_close_lot) && ((_SLots + _BLots) > Min_close_lot)){
            int rev_direction = OP_BUY;
            if(direction == OP_BUY)
                rev_direction = OP_SELL;
            _Close_Profit(rev_direction,prof);
         }
      }
    } 
  }
//+------------------------------------------------------------------+
//| Close  function                                                   |
//+------------------------------------------------------------------+   

void _Close_all() 
{
   for(int i=0;i<OrdersTotal();i++)
      {
      bool res = true;
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES) == false){ 
        Print("Order Not Selected", i," Error", ErrorDescription(GetLastError()));
        continue;
      }
      if(OrderSymbol()==Symbol() &&(OrderMagicNumber()==MagicNumber)){   
              RefreshRates();
               if (OrderType()>OP_SELL)   res = OrderDelete(OrderTicket());
               if (OrderType()==OP_SELL)  res = OrderClose(OrderTicket(),OrderLots(),Ask,10,CLR_NONE); 
               if (OrderType()==OP_BUY)   res = OrderClose(OrderTicket(),OrderLots(),Bid,10,CLR_NONE); //MarketInfo(OrderSymbol(),MODE_ASK)
            if(!res)
               Print("Error in OrderCloase _Close_all. Error code=",ErrorDescription(GetLastError()),OrderType());
            else
               Print("Order Closed successfully. _Close_all ");
         }
      }
 }
 


//+------------------------------------------------------------------+
//| expert start function                                            |
//+------------------------------------------------------------------+
// #define SIGNAL_NONE 0
// #define SIGNAL_BUY   1
// #define SIGNAL_SELL  2
// #define SIGNAL_CLOSEBUY 3
// #define SIGNAL_CLOSESELL 4
// int Order = SIGNAL_NONE;

// int UpperThreshold=80;          //Upper Threshold, default 80
// int LowerThreShold=20;          //Lower Threshold, default 20
// int stocastic() {
//    Order = SIGNAL_NONE;
//    double StochPrev=iStochastic(Symbol(),PERIOD_H1,5,3,3,MODE_SMA,STO_LOWHIGH,MODE_BASE,1);
//    double StochCurr=iStochastic(Symbol(),PERIOD_H1,5,3,3,MODE_SMA,STO_LOWHIGH,MODE_BASE,0);
//    if(StochPrev<LowerThreShold && StochCurr>LowerThreShold){
//       Order=SIGNAL_BUY;
//    }else if(StochPrev>UpperThreshold && StochCurr<UpperThreshold){
//       Order=SIGNAL_SELL;
//    }else if(StochCurr>UpperThreshold){
//       Order=SIGNAL_CLOSEBUY;
//    }else if(StochCurr<LowerThreShold){
//       Order=SIGNAL_CLOSESELL;
//    }
// return(0);
// }
//+------------------------------------------------------------------+
