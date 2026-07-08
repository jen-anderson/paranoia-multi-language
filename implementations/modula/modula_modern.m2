MODULE PARA (*(keyboard, output)*);

(*      This Modula-2 version is the work of K.Y TAN 
        and is based on the Pascal verison.

	K.Y. TAN
	Djavaheri Bros.
	697 Saturn Ct.
	Foster City, CA 94440

	(415) 341-1768
	UUCP: ...!ucbvax!dual!dbi!morris

        Please send us any bugs you find, or any improvements you make.

*)
FROM MathLib0 IMPORT sqrt,ln,exp,sin,cos;
FROM Terminal    IMPORT ReadString, ReadLn,WriteString, WriteLn;
FROM ConvertReal IMPORT RealToStr;
FROM Convert     IMPORT IntToStr;
FROM SYSTEMX     IMPORT Rmode, RoundModes;
FROM SimpleIO    IMPORT ReadChar,ReadInt,EOL;
CONST
      maxint = 2147483647;

      (* Small floating point constants. *)

      Zero = 0.0;
      Half = 0.5;
      One = 1.0;
      Two = 2.0;
      Three = 3.0;
      Four = 4.0;
      Five = 5.0;
      Eight = 8.0;
      Nine = 9.0;
      TwentySeven = 27.0;
      ThirtyTwo = 32.0;
      TwoForty = 240.0;
      MinusOne = - 1.0;
      OneAndHalf = 1.5;
      (* Integer constants *)
      NoTrials = 20;
      (* Number of tests for commutativity.  *)

   TYPE

      Guard = (Yes, No);
      Rounding = (Chopped, Rounded, Other);
      Message = ARRAY [0..40] OF CHAR;
      Class = (Flaw, Defect, SeriousDefect, Failure);
      ClassRange = [Flaw..Failure];

   VAR
      (*KEYBOARD: TEXT;*)
      str : Message;
      succ: BOOLEAN;

      MyZero: INTEGER;
      NoTimes, Index: INTEGER;
      ch: CHAR;
      AInverse, A1: REAL;
      Radix, BInverse, RadixD2, BMinusU2: REAL;
      C, CInverse: REAL;
      D, FourD: REAL;
      E0, E1, Exp2, E3, MinSqrtError: REAL;
      SqrtError, MaxSqrtError, E9: REAL;
      Third: REAL;
      F6, F9: REAL;
      H, HInverse: REAL;
      I: INTEGER;
      StickyBit, J: REAL;
      M, N, N1: REAL;
      Precision: REAL;
      Q, Q9: REAL;
      R, R9: REAL;
      T, Underflow, S: REAL;
      OneUlp, UnderflowThreshold, U1, U2: REAL;
      V, V0, V8, V9: REAL;
      W: REAL;
      X, X1, X2, X8, RandomNumber1: REAL;
      Y, Y1, Y2, RandomNumber2: REAL;
      Z, PseudoZero, Z1, Z2, Z9: REAL;
      NoErrors: ARRAY ClassRange OF INTEGER;
      Milestone: INTEGER;
      PageNo: INTEGER;
      GMult, GDiv, GAddSub: Guard;
      RMult, RDiv, RAddSub, RSqrt: Rounding;
      Continue, Break, Done, NotMonot, Monot, AnomolousArithmetic, IEEE,
            SquareRootWrong, UnderflowNotGradual: BOOLEAN;
      (* Computed constants.  *)
      (* U1  gap below 1.0, i.e, 1.0-U1 is next number below 1.0  *)
      (* U2  gap above 1.0, i.e, 1.0+U2 is next number above 1.0  *)




PROCEDURE check(x, ref : REAL);
BEGIN
       IF x = ref THEN
         RealToStr(x, str,20, 7,succ);
         WriteString(str); WriteString(" = ");
         message(str); 
       ELSE
         RealToStr(x, str,20, 7,succ);
         WriteString(str); WriteString(" <> ");
         RealToStr(ref, str,20, 7,succ);
         message(str); 
       END;
END check;




PROCEDURE message(VAR str : ARRAY OF CHAR);
BEGIN
	WriteString(str);WriteLn;
END message;





PROCEDURE Int (X: REAL): REAL;

   (*   simulates BASIC INT-function, which is defined as:
        INT(X) is the greatest integer value less than or equal to X.  *)

   PROCEDURE LargeTrunc (X: REAL): REAL;

   VAR
       start, acc, y, p: REAL;

   BEGIN (* LargeTrunc *)

          IF ABS (X) < FLOAT(maxint) THEN
             RETURN (FLOAT (TRUNC (X)) );
          ELSE
             start := ABS (X);
             acc := 0.0;

               REPEAT
                  y := start;
                  p := 1.0;

                  WHILE y > (FLOAT(maxint) - 1.0) DO
                     
                     y := y / Radix;
                     p := p * Radix;
                  END;
                  acc := acc + FLOAT(TRUNC (y)) * p;
                  start := start - FLOAT(TRUNC (y)) * p;
               UNTIL start < 1.0;

             IF X < 0.0 THEN
                RETURN( - acc);
             ELSE
                RETURN( acc );
             END;
          END;
   END LargeTrunc ;


BEGIN (* Int *)

      IF X > 0.0 THEN
         RETURN(  LargeTrunc (X) )
      ELSIF LargeTrunc (X - 0.5) = X THEN
         RETURN (X)
      ELSE
         RETURN ( LargeTrunc (X) - 1.0);
      END;
END  Int ;


PROCEDURE Sign (X: REAL): REAL;

BEGIN (* Sign *)

      IF X < 0.0 THEN
         RETURN ( - 1.0)
      ELSE
         RETURN ( + 1.0);
      END (* Sign *);
END Sign;


PROCEDURE Pause;

VAR
    ch: CHAR;

BEGIN (* Pause *)
(*
      WriteString ("To continue, press any key and newline:");
      ReadString(str);ReadLn;
*)
      WriteLn;
      WriteString ("Diagnosis resumes after Milestone No. ");
      IntToStr(Milestone,str,10,succ); message(str);
      WriteString ("               Page: ");
      IntToStr(PageNo,str,10,succ); message(str);WriteLn;
      PageNo    := PageNo + 1;
(*
      WriteString ("To continue, press any key and newline:");
      readln (KEYBOARD);
      WHILE not eoln (KEYBOARD) DO
         read (KEYBOARD, ch);
      page; 
      WriteString ("Diagnosis resumes after milestone no ", Milestone);
      WriteString ("               Page: ", PageNo);
      WriteLn;
      Milestone := Milestone + 1;
      PageNo    := PageNo + 1;
*)
END Pause ;


PROCEDURE Instructions;

BEGIN (* Instructions *)
(*
      Writeln("Lest this program stop prematurely, ",
            "i.e. before displaying");
      Writeln('         ''   End of Test   '',');
      Writeln('try to persuade the computer NOT to',
            ' terminate execution whenever an');
      Writeln('error like Over/Underflow or Division by Zero occurs,',
            ' but rather');
      Writeln('to persevere with a surrogate value after, ',
            ' perhaps, displaying some');
      Writeln('warning.  If persuasion avails naught, don''''t despair'
            , ' but run this');
      Writeln('program anyway to see how many milestones it passes,',
            ' and THEN');
      Writeln('amend it to make further progress.');
      Writeln('Answer questions with Y, y, N or n,');
      Writeln('except when indicated otherwise.');
*)
      END  Instructions ;


   PROCEDURE Heading;

      BEGIN (* Heading *)
(*
      Writeln('Users are invited to help debug and augment',
            ' this program so it will');
      Writeln('cope with unanticipated and newly uncovered',
            ' arithmetic pathologies.');
      Writeln('Please send suggestions and interesting results',
            ' to NPL or Kahan');
      Writeln('For copyright, see comment on listing.');
*)
       message("Please send suggestions and interesting results to");
       message("        Richahrd Karpinski");
       message("        Computer Center U-76");
       message("        University of California");
       message("        San Francisco, CA 94143-0704, USA");
       Writeln;
       message("In doing so, please include the following information:");
       message("        Version:  27 January 1986");
       message("        Computer:"); Writeln;
       message("        Optimization level:"); Writeln;
       message("        Other relevant compiler options:"); Writeln;
   END  Heading ;


   PROCEDURE Characteristics;

      BEGIN (* Characteristics *)
(*
      message ("  Running this program should reveal these characteristics");
      message ("  Radix= 1, 2, 4, 8, 10, 16, 100, 256 ..");
      message ("  Precision= number of significant digits carried");
      message ("  U2= Radix/Radix**Precision = One Ulp (OneUlpnit in the");
      message ("  Last Place of 1.000xxx");
      message ("  U1=1/Radix**Precision = One Ulp of numbers");
      message ("  a vIwtle less than 1.0 .");
      message ("  Adequate guard digits for Mult, Div and Sqrt");
      message ("  Arithmetic is chopped, rounded or other rounding");
      message ("  for Mult, Div, Add/Subt and StickyBitqrt");
      message ("  Sticky bit used correctly for rounding");
      message ("  UnderflowThreshold = an underflow threshold");
      message ("  E0 and PseudoZero tell whether underflow is abrupt,");
      message ("  gradual or fuzzy");
      message ("  V = an overflow threshold, roughly");
      message ("  V0  tells, roughly, whether Infinity is");
      message ("  represented.");
      message ("  Comparisions are checked for consistency with");
      message ("  subtraction and for contamination with pseudo-zeros.");
      message ("  Sqrt is tested.  Y^X is not tested.");
      message ("  Extra-precise subexpressions are revealed 
      message ("  but NOT YET tested");
      message ("  Decimal-Binary conversion is NOT YET tested for accuracy.");
*)
      END  Characteristics ;


   PROCEDURE History;

      BEGIN (* History *)
(*
      Writeln("   The program attempts to discriminate among');
      Writeln("   FLAWs, like lack of a sticky bit,');
      Writeln("   Serious DEFECTs, like lack of a guard digit, and');
      Writeln("   FAILUREs, like 2+2 = 5 .');
      Writeln("Failures may confound subsequent diagnoses.');
      WriteLn;
      Writeln("The diagnostic capabilities of this program go beyond',
            " an earlier');
      Writeln("program called ''MACHAR'', which can be found at the',
            " end of the');
      Writeln("book  ''Software Manual for the Elementary Functions',
            ''' (1980) by');
      Writeln("W. J. Cody and W. Waite. Although both programs',
            " try to discover');
      Writeln("the Radix, Precision and range (over/underflow',
            " thresholds)');
      Writeln("of the arithmetic, this program tries to cope',
            " with a wider VARiety');
      Writeln("of pathologies, and to say how well the',
            " arithmetic is implemented.");
      WriteLn;
      Writeln('The program is based upon a conventional",
            " radix representation for");
      Writeln("floating-point numbers, but also allows",
            "logrithmic encoding");
      Writeln("as used by certain early WANG machines.");
      WriteLn;
*)
      END  History ;


PROCEDURE TestCondition (K: Class; Valid: BOOLEAN; T: Message);

BEGIN (* TestCondition *)

      IF NOT Valid THEN
         
         NoErrors [K] := NoErrors [K] + 1;
         CASE K OF
            Flaw:
               WriteString ("FLAW          ");|
            Defect:
               WriteString ("DEFECT        ");|
            SeriousDefect:
               WriteString ("SERIOUS DEFECT");|
            Failure:
               WriteString ("FAILURE       ");
         END;
         WriteString (" : Violation of ");
         WriteString (T);WriteLn;
      END;
END  TestCondition ;


PROCEDURE Random() : REAL;

      VAR
         X, Y: REAL;

BEGIN (* Random *)
      X := RandomNumber1 + R9;
      Y := X * X;
      Y := Y * Y;
      X := X * Y;
      Y := X - Int (X);
      RandomNumber1 := Y + X * 0.000005;
      RETURN (RandomNumber1);
END  Random ;


PROCEDURE SqrtXMinX (ErrorKind: Class);

BEGIN (* SqrtXMinX *)

     SqrtError := ((sqrt(X * X) - X * BInverse) - (X - X * BInverse)) / OneUlp;

     IF SqrtError <> 0.0 THEN
		 
        IF SqrtError < MinSqrtError THEN
           MinSqrtError := SqrtError;
        END;

	IF SqrtError > MaxSqrtError THEN
           MaxSqrtError := SqrtError;
	END;

	J := J + 1.0;

	IF ErrorKind = SeriousDefect THEN
           WriteString ("SERIOUS ");
        END;

	message ("DEFECT      : Violation of");

    (*Writeln("sqrt( ",   X * X   , " - ",    X, ") = ", OneUlp * SqrtError)*)

         WriteString('sqrt(');
         RealToStr(X*X, str,20, 7,succ);
         WriteString(str);

         WriteString(' - ');
         RealToStr(X, str,20, 7,succ);
         WriteString(str);

         WriteString(') = ');
         RealToStr(OneUlp * SqrtError, str,20, 7,succ);
         message(str);

         message ('instead of correct value 0 .');
     END;
END  SqrtXMinX ;


PROCEDURE NewD;

BEGIN (* NewD *)

      X := Z1 * Q;
      X := Int (Half - X / Radix) * Radix + X;
      Q := (Q - X * Z) / Radix + X * X * (D / Radix);
      Z := Z - Two * X * D;
      IF Z <= Zero THEN
         Z  := - Z;
         Z1 := - Z1;
      END;
      D := Radix * D;

END  NewD ;


PROCEDURE SubRount4750;

BEGIN (* SubRount4750 *)
      IF NOT ((X - Radix < Z2 - Radix) OR (X - Z2 > W - Z2)) THEN
         
         I := I + 1;
         X2 := sqrt(X * D);
         Y2 := (X2 - Z2) - (Y - Z2);
         X2 := X8 / (Y - Half);
         X2 := X2 - Half * X2 * X2;
         SqrtError := (Y2 + Half) + (Half - X2);

         IF SqrtError < MinSqrtError THEN
            MinSqrtError := SqrtError;
         END;

         SqrtError := Y2 - Half;

         IF SqrtError > MaxSqrtError THEN
            MaxSqrtError := SqrtError;
         END;

     END;
END  SubRount4750 ;


PROCEDURE Power (X, Y: REAL): REAL;

BEGIN (* Power *)

      IF X = 1.0 THEN
         (*Power := 1.0*)
         RETURN(1.0);
      ELSE
         (*Power := exp (Y * ln (X));*)
         RETURN exp(Y * ln(X));
      END  ;

END Power ;


PROCEDURE DoesYequalX;

BEGIN (* DoesYequalX *)

  IF Y <> X THEN
         
     IF N <= 0.0 THEN
            
        NoErrors [Defect] := NoErrors [Defect] + 1;
        WriteString ('DEFECT      : Violation of');

            (* Writeln('computed (', Z, ') ^ (', Q, ') = ', V);*)

         WriteString("compute(");
         RealToStr(Z, str,20, 7,succ);
         WriteString(str);
         WriteString(") ^ (");
         RealToStr(Q, str,20, 7,succ);
         WriteString(str);
         WriteString(") = ");
         RealToStr(V, str,20, 7,succ);
         message (str);

            (* Writeln('comparison unequal to correct ', X);   *)

         WriteString(" comparison unequal to correct ");
         RealToStr(X, str,20, 7,succ);
         message (str);

            (* Writeln('; they differ by ', Y - X); *)

         WriteString(" ; they differ by ");
         RealToStr(Y - X, str,20, 7,succ);
         message (str);

    END;
         N := N + 1.0;
      (*  ... count discrepancies.  *)
  END;
 END  DoesYequalX ;


PROCEDURE SubRout3980;

BEGIN (* SubRout3980 *)

      REPEAT
         Y := Power (Z, FLOAT(I));
         Q := FLOAT(I);
         DoesYequalX;
         I := I + 1;
         IF FLOAT(I) <= M THEN
            X := Z * X;
         END;
      UNTIL (X >= W) OR (FLOAT(I) > M);

END  SubRout3980 ;


PROCEDURE PrintIfNPositive;

BEGIN (* PrintIfNPositive *)
      IF N > 0.0 THEN
         (* Writeln('Similar discrepancis have occured ', N, ' times.'); *)
         WriteString("Similar discreepacis have occured ");
         RealToStr(Q9, str,20, 7,succ);
         WriteString(str);
         message(" times.");
      END;
END  PrintIfNPositive ;


PROCEDURE TestPartialUnderflow;

BEGIN (* TestPartialUnderflow *)

      message("		Test Partial Underflow");WriteLn;

      N := 0.0;

      IF Z <> 0.0 THEN
        
         message ('Since comparison denies Z = 0, evaluating');
         message ('(Z + Z) / Z should be safe');
         WriteString ('What the machine gets for (Z + Z) / Z is: ');
         Q9 := (Z + Z) / Z;
         RealToStr(Q9, str,20, 7,succ);
         message (str);
         IF (ABS (Q9 - Two) < Radix * U2) THEN
            
            WriteString ('This is O.K., provided Over/Underflow');
            message (' has not just been signaled.');

         ELSIF (Q9 < One) OR (Q9 > Two) THEN
            
            N := 1.0;
            NoErrors [SeriousDefect] := NoErrors [SeriousDefect] + 1;
            message ('This is a VERY SERIOUS DEFECT!');

         ELSE
            
            N := 1.0;
            NoErrors [Defect] := NoErrors [Defect] + 1;
            message ('This is a DEFECT');
         END;

         V9 := Z * One;
         RandomNumber1 := V9;
         V9 := One * Z;
         RandomNumber2 := V9;
         V9 := Z / One;

         IF (Z = RandomNumber1) AND (Z = RandomNumber2)
               AND (Z = V9) THEN
            
            IF N > 0.0 THEN
               Pause
            END

         ELSE
            
            N := 1.0;
            NoErrors [Defect] := NoErrors [Defect] + 1;

            (* Writeln('DEFECT: What prints as Z = ', Z, 'compares');*)
            WriteString("DEFECT: What prints as Z = ");
            RealToStr(Z, str,20, 7,succ);
            message (str);

            WriteString ('compares different from        ');
            IF NOT (Z = RandomNumber1) THEN
               (* Writeln('Z * 1 = ', RandomNumber1); *)
               WriteString("Z * 1 = ");
               RealToStr(RandomNumber1, str,20, 7,succ);
               message (str);
            END;

            IF NOT ((Z = RandomNumber2)
                  OR (RandomNumber2 = RandomNumber1)) THEN
               (* Writeln('1 * Z = ', RandomNumber2);*)
               WriteString("1 * Z = ");
               RealToStr(RandomNumber2, str,20, 7,succ);
               message (str);
            END;

            IF NOT (Z = V9) THEN
               (* Writeln('Z / 1 = ', V9);*)
               WriteString("Z / 1 = ");
               RealToStr(V9, str,20, 7,succ);
               message (str);
            END;

            IF RandomNumber2 <> RandomNumber1 THEN
               
               NoErrors [Defect] := NoErrors [Defect] + 1;
               message ('DEFECT   Multiplication does not commute');

               (* Writeln('comparrison allegs that 1 * Z = ', RandomNumber2);*)
               WriteString("comparrison allegs that 1 * Z = ");
               RealToStr(RandomNumber2, str,20, 7,succ);
               message (str);

               (* Writeln('differs from Z * 1 = ', RandomNumber1);*)
               WriteString("differs from Z * 1 = ");
               RealToStr(RandomNumber1, str,20, 7,succ);
               message (str);
            END;

            IF N > 0.0 THEN
               Pause;
            END;
         END;
      END;
 END  TestPartialUnderflow ;


   (* BEGIN  PARA *)


PROCEDURE Milestone0;
BEGIN
(*
   WriteString ('Type any character to start the program.');
   reset (KEYBOARD,'/dev/tty5');

   WHILE NOT eoln (KEYBOARD) DO
      read (KEYBOARD, ch);
   Instructions;
   Heading;
   Pause;
   Characteristics;
   Pause;
   History;
*)
END Milestone0;


PROCEDURE Milestone7;
BEGIN

   message("------------- Milestone 7 ------------- ");
   Milestone := 7;
   message ('Program is now RUNNING tests on small Integers:');

   TestCondition (Failure, (Zero + Zero = Zero) AND (One - One = Zero)
                  AND (One > Zero)
                  AND (One + One = Two), 
                  ' 0+0=0  OR 1-1=0  OR  1>0  OR 1+1=2     '
                  );

   Z := - Zero;
   IF Z = 0.0 THEN
      
      U1 := 0.001;
      Radix := 1.0;
      TestPartialUnderflow;
      
   ELSE

      NoErrors [Failure] := NoErrors [Failure] + 1;
      message ('Comparison alleges that -0.0 is Non-zero!');
   END;

   TestCondition (Failure, (Three = Two + One) AND (Four = Three + One)
         AND (Four + Two * (- Two) = Zero)
         AND (Four - Three - One = Zero),
         ' 3=2+1, 4=3+1, 4+2*(-2)=0 OR 4-3-1=0    ');

   TestCondition (Failure, (MinusOne = - One)
         AND (MinusOne + One = Zero ) AND (One + MinusOne = Zero)
         AND (MinusOne + ABS (One) = Zero)
         AND (MinusOne + MinusOne * MinusOne = Zero),
         ' -1+1=0, (-1)+ABS(1)=0, -1+(-1)*(-1)    ');

   TestCondition (Failure, Half + MinusOne + Half = Zero,
         '   1/2  + (-1) + 1/2  = 0               ');

END Milestone7;


PROCEDURE Milestone10;
BEGIN
   WriteLn;
   message(" ---------- Milestone 10 ---------- ");
   Milestone := 10;

   WriteLn;

   TestCondition (Failure, (Nine = Three * Three)
         AND (TwentySeven = Nine * Three) AND (Eight = Four + Four)
         AND (ThirtyTwo = Eight * Four)
         AND (ThirtyTwo - TwentySeven - Four - One = Zero),
         ' 9=3*3, 27=9*3, 32=8*4, 32-27-4-1=0     ');

   TestCondition (Failure, (Five = Four + One) 
         AND (TwoForty = Four * Five * Three * Four)
         AND (TwoForty / Three - Four * Four * Five = Zero)
         AND ( TwoForty / Four - Five * Three * Four = Zero)
         AND ( TwoForty / Five - Four * Three * Four = Zero),
         ' 5=4+1,  240/3=80,  240/4=60,  240/5=48 ');

   IF NoErrors [Failure] = 0 THEN
      message (' -1, 0, 1/2, 1, 2, 3, 4, 5, 9, 27, 32 & 240 are O.K.');
   END;

   message ('Searching for Radix and Precision');
   W := One;

   REPEAT
      W := W + W;
      Y := W + One;
      Z := Y - W;
      Y := Z - One;
   UNTIL (MinusOne + ABS (Y) >= Zero);

(* .. now W is just big enough that |((W+1)-W)-1| >= 1 ... *)

   Precision := 0.0;
   Y := One;

   REPEAT
      Radix := W + Y;
      Y := Y + Y;
      Radix := Radix - W;
   UNTIL (Radix <> Zero);

   IF Radix < Two THEN
      Radix := One;
   END;

   (* Writeln('Radix = ', Radix);*)
   WriteString("Radix = ");
   RealToStr(Radix, str,20, 7,succ);
   message (str);

   IF Radix <> 1.0 THEN
      
      W := One;

      REPEAT
         Precision := Precision + One;
         W := W * Radix;
         Y := W + One;
      UNTIL (Y - W) <> One;

  (* ... now W = Radix^Precision is barely too big to satisfy (W+1)-W = 1 ... *)
   END;

   U1 := One / W;
   U2 := Radix * U1;
   (* Writeln('Closest relative separation found is U1 = ', U1);*)
      WriteString("Closest relative separation found is U1 = ");
      RealToStr(U1, str,20, 7,succ);
      message (str);
   WriteLn;
   message ('Recalculating radix and precision');
   E0 := Radix;
   E1 := U1;
   E9 := U2;
   E3 := Precision;

(* save old values *)
   X := Four / Three;
   Third := X - One;
   F6 := Half - Third;
   X := F6 + F6;
   X := ABS (X - Third);
   IF X < U2 THEN
      X := U2;
   END;

(* ... now X = (unknown no.) ulps of 1+... *)

   REPEAT
      U2 := X;
      Y := Half * U2 + ThirtyTwo * U2 * U2;
      Y := One + Y;
      X := Y - One;
   UNTIL (U2 <= X) OR (X <= Zero);

(* ... now U2 = 1 ulp of 1 + ...  *)

   X := Two / Three;
   F6 := X - Half;
   Third := F6 + F6;
   X := Third - Half;
   X := ABS (X + F6);
   IF X < U1 THEN
      X := U1;
   END;

(* ... now  X = (unknown no.) ulps of 1 -...  *)

   REPEAT
      U1 := X;
      Y := Half * U1 + ThirtyTwo * U1 * U1;
      Y := Half - Y;
      X := Half + Y;
      Y := Half - X;
      X := Half + Y;
   UNTIL (U1 <= X) OR (X <= Zero);

(* ... now U1 = 1 ulp of 1 - ...  *)

   IF U1 = E1 THEN
      message (' confirms closest relative separation U1 .')
   ELSE
      (* Writeln(' gets better closest relative separation U1 = ', U1);*)
      WriteString(" gets better closest relative separation U1 =  ");
      RealToStr(U1, str,20, 7,succ);
      message (str);
   END;

   W := One / U1;
   F9 := (Half - U1) + Half;
   Radix := Int (0.01 + U2 / U1);

   IF Radix = E0 THEN
      message ('Radix confirmed.')
   ELSE
      (* Writeln('MYSTERY: recalculated Radix = ', Radix);*)
      WriteString(" MYSTERY: recalculated Radix = ");
      RealToStr(Radix, str,20, 7,succ);
      message (str);
    END;

   TestCondition (Defect, Radix <= Eight + Eight,
         'Radix is too big: rounDOff problems     ');

   TestCondition (Flaw, (Radix = Two) OR (Radix = 10.0)
         OR (Radix = One), 'Radix is not as good as 2 OR 10.        ') ;

END Milestone10;


PROCEDURE Milestone20;
BEGIN
   WriteLn;
   message(" ---------- Milestone 20 ---------- ");
   Milestone := 20;
   WriteLn;

   TestCondition (Failure, F9 - Half < Half,
         ' (1-U1)-1/2 < 1/2 is FALSE, prog. fails?');

   X := F9;
   I := 1;
   Y := X - Half;
   Z := Y - Half;

   TestCondition (Failure, (X <> One)
         OR (Z = Zero), 'Comparison is fuzzy,X=1 but X-1/2-1/2<>1');
   X := One + U2;
   I := 0;
END Milestone20;


PROCEDURE Milestone25;
BEGIN
   WriteLn;
   message(" ---------- Milestone 25 ---------- ");
   Milestone := 25;
   WriteLn;
   BMinusU2 := Radix - One;
   BMinusU2 := (BMinusU2 - U2) + One;

   IF Radix <> One THEN
      (*begin ... BMinusU2 = nextafter(Radix, 0)  *)
      X := - TwoForty * ln(U1) / ln(Radix);
      Y := Int (Half + X);

      IF ABS (X - Y) * Four < One THEN
         X := Y;
      END;

      Precision := X / TwoForty;
      Y := Int (Half + Precision);

      IF ABS (Precision - Y) * TwoForty < Half THEN
         Precision := Y;
      END;

   END;

   (*  Purify Integers  *)

   IF (Precision <> Int (Precision)) OR (Radix = One) THEN
      
      message (' Precision cannot be characterized by an');
      message (' Integer number of sig. digits');
      message (' but, by itself, this is a minor flaw.');
   END;

   IF Radix = One THEN
      message (' lnarithmic excoding has precision characterized solely by U1.')
   ELSE
(*WriteString ('The number of significant digits of the Radix is ',Precision);*)

         WriteString( ' The number of significant digits of the Radix is ');
         RealToStr(Precision, str,20, 7,succ);
         message(str);WriteLn;
   END;

   TestCondition (SeriousDefect, U2 * Nine * Nine * TwoForty < One,
         'Precision worse than 5 decimal figures  ');

END Milestone25;


PROCEDURE Milestone30;
BEGIN
   WriteLn;
   message(" ---------- Milestone 30 ---------- ");
   Milestone := 30;
   WriteLn;
(*  Test for extra-precise subepressions  *)

   X := ABS (((Four / Three - One) - One / Four) * Three - One / Four);

   REPEAT
      Z2 := X;
      X := (One + (Half * Z2 + ThirtyTwo * Z2 * Z2)) - One;
   UNTIL (Z2 <= X) OR (X <= Zero);

   Y := ABS ((Three / Four - Two / Three) * Three - One / Four);
   Z := Y;
   X := Y;

   REPEAT
      Z1 := Z;
      Z := (One / Two - ((One / Two - (Half * Z1 + ThirtyTwo * Z1 * Z1))
            + One / Two)) + One / Two;
   UNTIL (Z1 <= Z) OR (Z <= Zero);

   REPEAT

      REPEAT
         Y1 := Y;
         Y := (Half - ((Half - (Half * Y1 + ThirtyTwo * Y1 * Y1)) + Half
               )) + Half;
      UNTIL (Y1 <= Y) OR (Y <= Zero);


      X1 := X;
      X := ((Half * X1 + ThirtyTwo * X1 * X1) - F9) + F9;

   UNTIL (X1 <= X) OR (X <= Zero);


   IF (X1 <> Y1) OR (X1 <> Z1) THEN
      
      NoErrors [SeriousDefect] := NoErrors [SeriousDefect] + 1;
      message ('SERIOUS DEFECT: Violation of');
      message ('Disagreement among the values X1, Y1, Z1');
      (* Writeln('resp. ', X1, Y1, Z1);*)
      WriteString("resp. ");
      RealToStr(X1, str,20, 7,succ);
      message (str);
      RealToStr(Y1, str,20, 7,succ);
      message (str);
      RealToStr(Z1, str,20, 7,succ);
      message (str);

      message ('are symptoms of inconsistencies introduced');
      message ('by extra precision evaluation of allegedly');
      message ('"optimized" arithmetic subexpressions.');
      message ('Possibly some part of this test is');
      message ('inconsistent.');

      IF (X1 = U1) OR (Y1 = U1) OR (Z1 = U1) THEN
         message ('That feature is not further tested by this program.') ;
      END

   ELSIF (Z1 <> U1) OR (Z2 <> U2) THEN
      
      IF (Z1 >= U1) OR (Z2 >= U2) THEN
         
         NoErrors [Failure] := NoErrors [Failure] + 1;
         WriteString ('FAILURE     : Violation of Precision: ');
         RealToStr(Precision, str,20, 7,succ);
         message (str);

         (* Writeln('U1 = ', U1, ' Z1 - U1 = ', Z1 - U1);*)

         WriteString("U1 = ");
         RealToStr(U1, str,20, 7,succ);
         message (str);
         WriteString("Z1 - U1 = ");
         RealToStr(Z1 - U1, str,20, 7,succ);
         message (str);

         (* Writeln('U2 = ', U2, ' Z2 - U2 = ', Z2 - U2);*)

         WriteString("U2 = ");
         RealToStr(U2, str,20, 7,succ);
         message (str);

         WriteString("Z2 - U2 = ");
         RealToStr(Z2 - U2, str,20, 7,succ);
         message (str);
         
      ELSIF (Z1 <= Zero) OR (Z2 <= Zero) THEN
         
         (* Writeln('Because of unusual Radix = ', Radix);*)

         WriteString("Because of unusual Radix = ");
         RealToStr(Radix, str,20, 7,succ);
         message (str);
         message (', or exact rational arithmetic a result');
         (* Writeln('Z1 = ', Z1, ' or Z2 = ', Z2);*)
         WriteString("Z1 = ");
         RealToStr(Z1, str,20, 7,succ);
         message (str);
         WriteString("or Z2 = ");
         RealToStr(Z2, str,20, 7,succ);
         message (str);
         message ('of an extra precision test is ');
         message ('inconsistent.');WriteLn;
         IF Z1 = Z2 THEN
            message ('That feature is not further tested by the program');
         END
      ELSE
         
         X := Z1 / U1;
         Y := Z2 / U2;
         IF Y > X THEN
            X := Y;
         END;
         Q := - ln(X);
         message ('Some subexpressions appear to be calculated');
         message ('extra precicely with about ');
         (* Writeln(Q / ln (Radix), 'extra B-digits i. e. ');*)
         RealToStr(Q / ln(Radix), str,20, 7,succ);
         WriteString (str);
         message (' extra B-digits i. e. ');

         (* Writeln('roughly ', Q / ln(10), " extra significant decimals.');*)
         WriteString ("roghly ");
         RealToStr(Q / ln(Radix), str,20, 7,succ);
         WriteString (str);
         message (' extra significant decimals.');
      END;
   END;
   Pause;
END Milestone30;

   

PROCEDURE Milestone35;
BEGIN
   WriteLn;
   message(" ---------- Milestone 35 ---------- ");
   Milestone := 35;
   WriteLn;
   IF Radix >= Two THEN
      
      X := W / (Radix * Radix);
      Y := X + One;
      Z := Y - X;
      T := Z + U2;
      X := T - Z;
      TestCondition (Failure, X = U2,
            'Subtraction is not normlzd X=Y,X+Z<>Y+Z!');
      IF X = U2 THEN
         message ('Subtraction is normalized, as it should.');
      END;
   END;

   WriteLn;
   message ('Checking for guard digit on *, /, and -.');
   Y := F9 * One;
   Z := One * F9;
   X := F9 - Half;
   Y := (Y - Half) - X;
   Z := (Z - Half) - X;
   X := One + U2;
   T := X * Radix;
   R := Radix * X;
   X := T - Radix;
   X := X - Radix * U2;
   T := R - Radix;
   T := T - Radix * U2;
   X := X * (Radix - One);
   T := T * (Radix - One);
   IF (X = Zero) AND (Y = Zero) AND (Z = Zero) AND (T = Zero) THEN
      GMult := Yes
   ELSE
      
      GMult := No;
      TestCondition (SeriousDefect, FALSE,
            '  * lacks guard digit, 1*X <> X         ');
   END;
   Z := Radix * U2;
   X := One + Z;
   Y := ABS ((X + Z) - X * X) - U2;
   X := One - U2;
   Z := ABS ((X - U2) - X * X) - U1;
   TestCondition (Failure, (Y <= Zero)
         AND (Z <= Zero), '  * gets too many final digits wrong.   ');
   Y := One - U2;
   X := One + U2;
   Z := One / Y;
   Y := Z - X;
   X := One / Three;
   Z := Three / Nine;
   X := X - Z;
   T := Nine / TwentySeven;
   Z := Z - T;
   TestCondition (Defect, (X = Zero) AND (Y = Zero)
         AND (Z = Zero), 'Division error > ulp, 1/3 <> 3/9 <> 9/27');
   Y := F9 / One;
   X := F9 - Half;
   Y := (Y - Half) - X;
   X := One + U2;
   T := X / One;
   X := T - X;
   IF (X = Zero) AND (Y = Zero) AND (Z = Zero) THEN
      GDiv := Yes
   ELSE
      
      GDiv := No;
      TestCondition (SeriousDefect, FALSE,
            '  Division lacks guard digit so X/1 <> X');
   END;

   X := One / (One + U2);
   Y := X - Half - Half;
   TestCondition (SeriousDefect, Y < Zero,
         '  Computed value of 1/1.000..1 >= 1.    ');
   X := One - U2;
   Y := One + Radix * U2;
   Z := X * Radix;
   T := Y * Radix;
   R := Z / Radix;
   StickyBit := T / Radix;
   X := R - X;
   Y := StickyBit - Y;
   TestCondition (Failure, (X = Zero) AND (Y = Zero),
            ' * and/or / are inconsistent            ');
   Y := One - U1;
   X := One - F9;
   Y := One - Y;
   T := Radix - U2;
   Z := Radix - BMinusU2;
   T := Radix - T;
   IF (X = U1) AND (Y = U1) AND (Z = U2) AND (T = U2) THEN
      GAddSub := Yes
   ELSE
      
      GAddSub := No;
      TestCondition (SeriousDefect, FALSE,
            '- lacks guard digit, cancellatn obscured');
   END;

   TestCondition (SeriousDefect, (F9 = One)
         OR (F9 - One < Zero), 'Precautions against / by zero impossible'
         );
   IF (GMult = Yes) AND (GDiv = Yes) AND (GAddSub = Yes) THEN
      message (' *, /, and - have guard digits, as they should');
   END;
END Milestone35;



PROCEDURE Milestone40;
BEGIN
   WriteLn;
   message(" ---------- Milestone 40 ---------- ");
   Milestone := 40;
   WriteLn;
   Pause;
   message ('Checking rounding on multiply, divide and add/subtract');
   RMult := Other;
   RDiv := Other;
   RAddSub := Other;
   RadixD2 := Radix / Two;
   A1 := Two;
   Done := FALSE;

   REPEAT

      AInverse := Radix;

      REPEAT

         X := AInverse;
         AInverse := AInverse / A1;
      UNTIL Int (AInverse) <> AInverse;

      Done := (X = One) OR (A1 > Three);

      IF NOT Done THEN
         A1 := Nine + One;
      END;
   UNTIL Done;

   IF X = One THEN
      A1 := Radix;
   END;

   AInverse := One / A1;
   X := A1;
   Y := AInverse;
   Done := FALSE;

   REPEAT

      Z := X * Y - Half;
      TestCondition (Failure, Z = Half,
            '  X * (1/X) differs from 1.             ');
      Done := X = Radix;
      X := Radix;
      Y := One / X;
   UNTIL Done;

   Y2 := One + U2;
   Y1 := One - U2;
   X := OneAndHalf - U2;
   Y := OneAndHalf + U2;
   Z := (X - U2) * Y2;
   T := Y * Y1;
   Z := Z - X;
   T := T - X;
   X := X * Y2;
   Y := (Y + U2) * Y1;
   X := X - OneAndHalf;
   Y := Y - OneAndHalf;
   IF (X = Zero) AND (Y = Zero) AND (Z = Zero) AND (T <= Zero) THEN
      
      X := (OneAndHalf + U2) * Y2;
      Y := OneAndHalf - U2 - U2;
      Z := OneAndHalf + U2 + U2;
      T := (OneAndHalf - U2) * Y1;
      X := X - (Z + U2);
      StickyBit := Y * Y1;
      S := Z * Y2;
      T := T - Y;
      Y := (U2 - Y) + StickyBit;
      Z := S - (Z + U2 + U2);
      StickyBit := (Y2 + U2) * Y1;
      Y1 := Y2 * Y1;
      StickyBit := StickyBit - Y2;
      Y1 := Y1 - Half;
      IF (X = Zero) AND (Y = Zero) AND (Z = Zero) AND (T = Zero)
            AND ( StickyBit = Zero) AND (Y1 = Half) THEN
         
         RMult := Rounded;
         message ('Multiplication appears to round correctly.');
         
      ELSIF (X + U2 = Zero) AND (Y < Zero) AND (Z + U2 = Zero)
            AND (T < Zero) AND (StickyBit + U2 = Zero)
            AND (Y1 < Half) THEN
         
         RMult := Chopped;
         message ('Multiplication appears to chop.');
         
      ELSE
         message ('* is neither chopped nor correctly rounded');
      END;

      IF (RMult = Rounded) AND (GMult = No) THEN
         message (' Multiplication inconsistent, NOTIFY AUTHOR');
      END

   ELSE
      message ('* is neither chopped nor correctly rounded');
   END;

END Milestone40;


   

PROCEDURE Milestone45;
BEGIN
   WriteLn;
   message(" ---------- Milestone 45 ---------- ");
   Milestone := 45;
   WriteLn;
   Y2 := One + U2;
   Y1 := One - U2;
   Z := OneAndHalf + U2 + U2;
   X := Z / Y2;
   T := OneAndHalf - U2 - U2;
   Y := (T - U2) / Y1;
   Z := (Z + U2) / Y2;
   X := X - OneAndHalf;
   Y := Y - T;
   T := T / Y1;
   Z := Z - (OneAndHalf + U2);
   T := (U2 - OneAndHalf) + T;
   IF NOT ((X > Zero) OR (Y > Zero) OR (Z > Zero) OR (T > Zero)) THEN
      
      X := OneAndHalf / Y2;
      Y := OneAndHalf - U2;
      Z := OneAndHalf + U2;
      X := X - Y;
      T := OneAndHalf / Y1;
      Y := Y / Y1;
      T := T - (Z + U2);
      Y := Y - Z;
      Z := Z / Y2;
      Y1 := (Y2 + U2) / Y2;
      Z := Z - OneAndHalf;
      Y2 := Y1 - Y2;
      Y1 := (F9 - U1) / F9;

      IF (X = Zero) AND (Y = Zero) AND (Z = Zero) AND (T = Zero) THEN
            IF (Y2 = Zero) AND (Y2 = Zero) AND (Y1 - Half = F9 - Half ) THEN
         
                RDiv := Rounded;
                message ('Division appears to round correctly.');
                IF GDiv = No THEN
                   message (' Division test inconsistent, NOTIFY AUTHOR');
                END
            END;
      END;

      IF (X < Zero) AND (Y < Zero) AND (Z < Zero) THEN
            IF (T < Zero) AND (Y2 < Zero) AND (Y1 - Half < F9 - Half) THEN
            
                RDiv := Chopped;
                message ('Division appears to chop.');
            END;
      END;
   END;

   IF RDiv = Other THEN
      WriteString ('/ is neither chopped nor correctly rounded');WriteLn;
   END;
   BInverse := One / Radix;
   TestCondition (Failure, (BInverse * Radix - Half = Half),
         '  Radix * ( 1 / Radix ) differs from 1. ');
END Milestone45;


PROCEDURE Milestone50;
BEGIN
   WriteLn;
   message(" ---------- Milestone 50 ---------- ");
   Milestone := 50;
   WriteLn;
   TestCondition (Failure, ((F9 + U1) - Half = Half)
         AND ((BMinusU2 + U2 ) - One = Radix - One),
         'Incomplete carry-propagation on Addition');
   X := One - U1 * U1;
   Y := One + U2 * (One - U2);
   Z := F9 - Half;
   X := (X - Half) - Z;
   Y := Y - One;
   IF (X = Zero) AND (Y = Zero) THEN
      
      RAddSub := Chopped;
      WriteString ('Add/Subtract appears to be chopped');WriteLn;

   END;

   IF GAddSub = Yes THEN
      
      X := (Half + U2) * U2;
      Y := (Half - U2) * U2;
      X := One + X;
      Y := One + Y;
      X := (One + U2) - X;
      Y := One - Y;
      IF (X = Zero) AND (Y = Zero) THEN
         
         X := (Half + U2) * U1;
         Y := (Half - U2) * U1;
         X := One - X;
         Y := One - Y;
         X := F9 - X;
         Y := One - Y;

         IF (X = Zero) AND (Y = Zero) THEN
            
            RAddSub := Rounded;
            WriteString ('Addition/Subtraction appears to round correctly');
            WriteLn;

            IF GAddSub = No THEN
               WriteString ( 'Addition/Subtraction inconsistent,NOTIFY AUTHOR');
               WriteLn;
            END

         ELSE

            WriteString ('Addition/Subtraction neither rounds nor chops.');
            WriteLn;
         END
      ELSE
         message ('Addition/Subtraction neither rounds nor chops.');
      END
   ELSE
      message ('Addition/Subtraction neither rounds nor chops.');
   END;

   S := One;
   X := One + Half * (One + Half);
   Y := (One + U2) * Half;
   Z := X - Y;
   T := Y - X;
   StickyBit := Z + T;

   IF StickyBit <> 0.0 THEN
      
      S := 0.0;
      NoErrors [Flaw] := NoErrors [Flaw] + 1;
      message ('FLAW      : Violation of');
      message ('(X - Y) + (Y - X) is non zero!');
   END;

   StickyBit := Zero;
   IF (GMult = Yes) AND (GDiv = Yes) AND (GAddSub = Yes)
         AND (RMult = Rounded) AND (RDiv = Rounded)
         AND (RAddSub = Rounded) AND (Int (RadixD2) = RadixD2) THEN
      
      message (' Checking for stick bit');
      X := (Half + U1) * U2;
      Y := Half * U2;
      Z := One + Y;
      T := One + X;

      IF (Z - One <= Zero) AND (T - One >= U2) THEN
         
         Z := T + Y;
         Y := Z - X;
         IF (Z - T >= U2) AND (Y - T = Zero) THEN
            
            X := (Half + U1) * U1;
            Y := Half * U1;
            Z := One - Y;
            T := One - X;

            IF (Z - One = Zero) AND (T - F9 = Zero) THEN
               
               Z := (Half - U1) * U1;
               T := F9 - Z;
               Q := F9 - Y;
               IF (T - F9 = Zero) AND (F9 - U1 - Q = Zero) THEN
                  
                  Z := (One + U2) * OneAndHalf;
                  T := (OneAndHalf + U2) - Z + U2;
                  X := One + Half / Radix;
                  Y := One + Radix * U2;
                  Z := X * Y;

                  IF (T = Zero) AND (X + RadixD2 * U2 - Z = Zero) THEN
                     
                     IF Radix <> Two THEN
                        
                        X := Two + U2;
                        Y := X / Two;

                        IF (Y - One = Zero) THEN
                           StickyBit := S;
                        END;
                     END;
                  END;
               END;
            END;
         END;
      END;
   END;

   IF StickyBit = One THEN
      message ('Sticky bit apparently used correctly')
   ELSE
      message ('Sticky bit used incorrectly or not at all.');
   END;

   TestCondition (Flaw, NOT ((GMult = No) OR (GDiv = No)
         OR (GAddSub = No)),
         ' No rounding and some chopping          ');
END Milestone50;

  


PROCEDURE Milestone60;
BEGIN
   WriteLn;
   message(" ---------- Milestone 60 ---------- ");
   Milestone := 60;
   WriteLn;
         WriteString ("Does Multiplication commute? Testing on ");
         IntToStr(NoTrials, str, 5, succ);
         WriteString (str);
         message(" random pairs");

   R9 := sqrt(3.0);
   RandomNumber1 := Third;
   I := 1;

   REPEAT
      X := Random();
      Y := Random();
      Z := X * Y;
      Z9 := Z - Y * X;
      I := I + 1;
   UNTIL (I > NoTrials) OR (Z9 <> Zero);

   IF I = NoTrials THEN
      
      RandomNumber1 := One + Half / Three;
      RandomNumber2 := (U2 + U1) + One;
      Z := RandomNumber1 * RandomNumber2;
      Y := RandomNumber2 * RandomNumber1;
      Z9 := (One + Half / Three) * ((U2 + U1) + One) - (One + Half /
            Three) * ((U2 + U1) + One);
   END;

   IF NOT ((I = NoTrials) OR (Z9 = Zero)) THEN
      
      NoErrors [Defect] := NoErrors [Defect] + 1;
      message ('DEFECT     : Violation of');
      message ('X * Y = Y * X trail fails.');
      
   ELSE
         WriteString (" No failures found in ");
         IntToStr(NoTrials, str, 5, succ);
         WriteString (str);
         message (" integers pairs. ");
   END;
END Milestone60;

   


PROCEDURE Milestone70;
BEGIN
   WriteLn;
   message(" ---------- Milestone 70 ---------- ");
   Milestone := 70;
   WriteLn;
   message ('Running test of square root(x)');
   TestCondition (Failure, (Zero = sqrt(Zero))
         AND (-Zero = sqrt(-Zero))
         AND (One = sqrt(One)), ' Square root of 0.0, -0.0 OR 1.0 wrong  '
         );
  WriteString("Exit test"); WriteLn;
   MinSqrtError := Zero;
   MaxSqrtError := Zero;
   J := 0.0;
   X := Radix;
   OneUlp := U2;
   SqrtXMinX (SeriousDefect);
    message("test");
   X := BInverse;
   OneUlp := BInverse * U1;
   SqrtXMinX (SeriousDefect);
    message("serci");
   X := U1;
   OneUlp := U1 * U1;
   SqrtXMinX (SeriousDefect);
   IF J <> 0.0 THEN
      
      NoErrors [SeriousDefect] := NoErrors [SeriousDefect] + 1;
      Pause;
   END;
   message ('Testing IF sqrt(X * X) = X for ');
   (* Writeln(NoTrials, ' Integers X'); *)
 
         IntToStr(NoTrials, str, 5, succ);
         WriteString(str);
         message(" Integers X");

   J := 0.0;
   X := Two;
   Y := Radix;
   IF (Radix <> One) THEN

      REPEAT
         X := Y;
         Y := Radix * Y;
      UNTIL (Y - X >= FLOAT(NoTrials));

   END;
   OneUlp := X * U2;
   I := 1;
   Continue := TRUE;

   WHILE (I < 10) AND Continue DO
      
      X := X + One;
      SqrtXMinX (Defect);

      IF J > 0.0 THEN
         
         Continue := FALSE;
         NoErrors [Defect] := NoErrors [Defect] + 1;
      END;
      I := I + 1;
   END;
   message ('Test for Sqrt monotonicity.');
   I := - 1;
   X := BMinusU2;
   Y := Radix;
   Z := Radix + Radix * U2;
   NotMonot := FALSE;
   Monot := FALSE;

   WHILE NOT (NotMonot OR Monot) DO

      
      I := I + 1;
      message("X := sqrt(X);");
      RealToStr(X, str,20, 7,succ);
      message(str);
      X := sqrt(X);
      message("Q := sqrt(Y);");
      Q := sqrt(Y);
      message("Z := sqrt(Z);");
      Z := sqrt(Z);
      IF (X > Q) OR (Q > Z) THEN
         NotMonot := TRUE
      ELSE
         
         Q := Int (Q + Half);
         IF (I > 0) OR (Radix = Q * Q) THEN
            Monot := TRUE
         ELSIF I > 0 THEN
               
               IF I > 1 THEN
                  Monot := TRUE
               ELSE
                  
                  Y := Y * BInverse;
                  X := Y - U1;
                  Z := Y + U1;
               END
         ELSE
            
            Y := Q;
            X := Y - U2;
            Z := Y + U2;
         END
     END;

   END; (* WHILE *)

   IF Monot THEN
      message ('Sqrt has passed a test for Monotonicity.')
   ELSE
      
      NoErrors [Defect] := NoErrors [Defect] + 1;
      message ('DEFECT       : Violatian of');
      WriteString ('sqrt(X) is non-monotonic for X near ');
      RealToStr(W, str,20, 7,succ);
      message (str);
   END;
END Milestone70;



PROCEDURE Milestone80;
BEGIN
   WriteLn;
   message(" ---------- Milestone 80 ---------- ");
   Milestone := 80;
   WriteLn;
   MinSqrtError := MinSqrtError + Half;
   MaxSqrtError := MaxSqrtError - Half;
   Y := (sqrt(One + U2) - One) / U2;
   SqrtError := (Y - One) + U2 / Eight;

   IF SqrtError > MaxSqrtError THEN
      MaxSqrtError := SqrtError;
   END;

   SqrtError := Y + U2 / Eight;

   IF SqrtError < MinSqrtError THEN
      MinSqrtError := SqrtError;
   END;

   Y := ((sqrt(F9) - U2) - (One - U2)) / U1;
   SqrtError := Y + U1 / Eight;

   IF SqrtError > MaxSqrtError THEN
      MaxSqrtError := SqrtError;
   END;

   SqrtError := (Y + One) + U1 / Eight;

   IF SqrtError > MaxSqrtError THEN
      MaxSqrtError := SqrtError;
   END;

   SqrtError := (Y + One) + U1 / Eight;

   IF SqrtError < MinSqrtError THEN
      MinSqrtError := SqrtError;
   END;

   OneUlp := U2;
   X := OneUlp;
   FOR Index := 1 TO 3 DO
      
      Y := sqrt((X + U1 + X) + F9);
      Y := ((Y - U2) - ((One - U2) + X)) / OneUlp;
      Z := ((U1 - X) + F9) * Half * X * X / OneUlp;
      SqrtError := (Y + Half) + Z;

      IF SqrtError < MinSqrtError THEN
         MinSqrtError := SqrtError;
      END;

      SqrtError := (Y - Half) + Z;

      IF SqrtError > MaxSqrtError THEN
         MaxSqrtError := SqrtError;
      END;

      IF ((Index = 1) OR (Index = 3)) THEN
         X := OneUlp * Sign (X) * Int (Eight / Nine * sqrt(OneUlp))
      ELSE
         
         OneUlp := U1;
         X := - OneUlp;
         
      END;
  END;
END Milestone80;

 

PROCEDURE Milestone85;
BEGIN

   WriteLn;
   message(" ---------- Milestone 85 ---------- ");
   Milestone := 85;
   WriteLn;
   SquareRootWrong := FALSE;
   AnomolousArithmetic := FALSE;
   IF Radix <> One THEN
      
      message ('testing wether Sqrt is rounded or chopped: ');
      D := Int (Half + Power (Radix, One + Precision - Int (Precision)))
         ;
   (*  ... = Radix^(1 + fract) IF Precision = Integer + fract.  *)
      X := D / Radix;
      Y := D / A1;
      IF (X <> Int (X)) OR (Y <> Int (Y)) THEN
         
         AnomolousArithmetic := TRUE;
      
      ELSE
         
         X := Zero;
         Z2 := X;
         Y := One;
         Y2 := Y;
         Z1 := Radix - One;
         FourD := Four * D;

         REPEAT
            IF Y2 > Z2 THEN
               
               Q := Radix;
               Y1 := Y;

               REPEAT
                  X1 := ABS (Q + Int (Half - Q / Y1) * Y1);
                  Q := Y1;
                  Y1 := X1;
               UNTIL X1 <= Zero;

               IF Q <= One THEN
                  
                  Z2 := Y2;
                  Z := Y; 
               END;
            END;
            Y := Y + Two;
            X := X + Eight;
            Y2 := Y2 + X;

            IF Y2 >= FourD THEN
               Y2 := Y2 - FourD;
            END;

         UNTIL Y >= D;

         X8 := FourD - Z2;
         Q := (X8 + Z * Z) / FourD;
         X8 := X8 / Eight;
         IF Q <> Int (Q) THEN
            AnomolousArithmetic := TRUE
         ELSE
            
            Break := FALSE;


            REPEAT
               X := Z1 * Z;
               X := X - Int (X / Radix) * Radix;
               IF X = One THEN
                  Break := TRUE
               ELSE
                  Z1 := Z1 - One;
               END;
            UNTIL Break OR (Z1 <= 0.0);

            IF (Z1 <= 0.0) AND (NOT Break) THEN
               AnomolousArithmetic := TRUE
            ELSE
               
               IF Z1 > RadixD2 THEN
                  Z1 := Z1 - Radix;
               END;

               REPEAT
                  NewD;
               (*UNTIL U2 * D >= F9;*)

               UNTIL U2 * D >= F9 * 0.5;


               IF D * Radix - D <> W - D THEN
                  AnomolousArithmetic := TRUE
               ELSE
                  
                  Z2 := D;
                  I := 0;
                  Y := D + (One + Z) * Half;
                  X := D + Z + Q;
                  SubRount4750;
                  Y := D + (One - Z) * Half + D;
                  X := D - Z + D;
                  X := X + Q + X;
                  SubRount4750;
                  NewD;
                  IF D - Z2 <> W - Z2 THEN
                     AnomolousArithmetic := TRUE
                  ELSE
                     
                     Y := (D - Z2) + (Z2 + (One - Z) * Half);
                     X := (D - Z2) + (Z2 - Z + Q);
                     SubRount4750;
                     Y := (One + Z) * Half;
                     X := Q;
                     SubRount4750;
                     IF I = 0 THEN
                        AnomolousArithmetic := TRUE;
                     END
                  END
               END
            END
         END;
      END;

      IF (I = 0) OR AnomolousArithmetic THEN
         
         NoErrors [Failure] := NoErrors [Failure] + 1;
         message ('FAILURE      : Violation of');
         message ('Anomolous arithmetic with Integer < Radix^Precision = ') ;
         RealToStr(W, str,20, 7,succ);
         WriteString(str);
         message ('  fails test whether Sqrt rounds or chops.');
         SquareRootWrong := TRUE;
      END
END;

   IF NOT AnomolousArithmetic THEN
      
      IF NOT ((MinSqrtError < 0.0) OR (MaxSqrtError > 0.0)) THEN
         
         RSqrt := Rounded;
         message ('Square root appears to be correctly rounded.');
      
      ELSIF (MaxSqrtError + U2 > U2 - Half) OR (MinSqrtError > Half)
            OR (MinSqrtError + Radix < Half) THEN
         SquareRootWrong := TRUE
      ELSE
         
         RSqrt := Chopped;
         message ('Square root appears to be chopped.');
      END;
   END;

   IF SquareRootWrong THEN
      
      message ('Square root is neither chopped nor correctly rounded.');

      WriteString ('Observed errors run from ');
      RealToStr(MinSqrtError - Half, str,20, 7,succ);
      message(str);

      (* Writeln('to ', Half + MaxSqrtError, ' ulps.');*)

         WriteString (" to ");
         RealToStr(Half + MaxSqrtError, str,20, 7,succ);
         WriteString (str);
         message (" ulps. ");

      TestCondition (SeriousDefect, MaxSqrtError - MinSqrtError < Radix * Radix,
                     'Sqrt gets too many last digits wrong.   ');
   END;

END Milestone85;


PROCEDURE Milestone90;
BEGIN
   WriteLn;
   WriteLn;
   message(" ---------- Milestone 90 ---------- ");
   Milestone := 90;
   WriteLn;
   Pause;
   IF Radix = - 100.0 THEN
      (*begin SKIP THIS SO FAR, PASCAL NO POWER F.  *)
      message ('Testing powers Z^i for small Integers Z and i.');
      N := 0.0;
   (*  ... test power of zero.  *)
      I := 0;
      Z := - Zero;
      M := 3.0;
      Break := FALSE;
      REPEAT
         X := One;
         SubRout3980;

         IF I <= 10 THEN
            
            I := 1023;
            SubRout3980;
         END;

         IF Z = MinusOne THEN
            Break := TRUE
         ELSE
            
            Z := MinusOne;
         (*  .. IF(-1)^N is invalid, replace MinusOne by One.  *)
            I := - 4;
         END;
     UNTIL Break;

      PrintIfNPositive;
      N1 := N;
      N := 0.0;
      Z := A1;
      M := Int (Two * ln(W) / ln(A1));
      Break := FALSE;

      REPEAT
         X := Z;
         I := 1;
         SubRout3980;
         IF Z = AInverse THEN
            Break := TRUE
         ELSE
            Z := AInverse;
         END;
      UNTIL Break;

   END;
END Milestone90;

      
   

PROCEDURE Milestone100;
BEGIN

   WriteLn;
   message(" ---------- Milestone 100 ---------- ");
   Milestone := 100;
   WriteLn;

   (*   Power of Radix have been tested,  *)
   (*          next try a few primes      *)

      M := FLOAT(NoTrials);
      Z := Three;

      REPEAT
         X := Z;
         I := 1;
         SubRout3980;


         REPEAT
            Z := Z + Two;
         UNTIL (Three * Int (Z / Three) <> Z);

      UNTIL (Z >= Eight * Three);

      IF N > 0.0 THEN
         
         message ('Error like this may invalidate financial ');
         message ('calculations involving interest rates.');
      END;

      N := N + N1;
      PrintIfNPositive;

      IF N = 0.0 THEN
         message ('... no discrepancis found.');
      END;

      IF N > 0.0 THEN
         Pause;
      END;

(*  SKIP POWER TESTS  *)

END Milestone100;

   


PROCEDURE Milestone110;
BEGIN
   WriteLn;
   message(" ---------- Milestone 110 ---------- ");
   Milestone := 110;
   WriteLn;
   message ('Seeking Underflow thresholds UnderflowThreshold and E0');
   D := U1;
   IF (Precision <> Int (Precision)) THEN
      
      D := BInverse;
      X := Precision;

      REPEAT
         D := D * BInverse;
         X := X - One;
      UNTIL X <= Zero;

   END;

   Y := One;
   Z := D;

(*  ... D is power of 1/Radix < 1.  *)

   REPEAT
      C := Y;
      Y := Z;
      Z := Y * Y;

      IF Z < 0.0000001 THEN Z := 0.0 END;

   UNTIL NOT ((Y > Z) AND (Z + Z > Z));


   Y := C;
   Z := Y * D;

   REPEAT
      Z := Y * D;
      IF Z < 0.0000001 THEN Z := 0.0 END;
   UNTIL NOT ((Y > Z) AND (Z + Z > Z));


   IF Radix < Two THEN
      HInverse := Two
   ELSE
      HInverse := Radix;
   END;
   H := One / HInverse;

(*  ... 1/HInverse = H = Min(1/Radix, 1/2)  *)

   CInverse := One / C;
   E0 := C;
   Z := E0 * H;

(*  ...1/Radix^(BIG Integer) << 1 << CInverse = 1/C  *)

   REPEAT
      Y := E0;
      E0 := Z;
      Z := E0 * H;
      IF Z < 0.0000001 THEN 
                        Z := 0.0;
      END;
      
   UNTIL NOT ((E0 > Z) AND (Z + Z > Z));

   UnderflowThreshold := E0;
   E1 := Zero;
   Q := Zero;
   E9 := U2;
   S := One + E9;
   D := C * S;
   IF D <= C THEN
      
      E9 := Radix * U2;
      S := One + E9;
      D := C * S;
      IF D <= C THEN
         
         message ('FAILURE      : Violation of');
         message ('multiplication gets too many last digits wrong.');
         NoErrors [Failure] := NoErrors [Failure] + 1;
         Underflow := E0;
         Y1 := Zero;
         PseudoZero := Z;
         Pause;
      END
   ELSE
      
      Underflow := D;
      PseudoZero := Underflow * H;
      UnderflowThreshold := Zero;

      REPEAT
         Y1 := Underflow;
         Underflow := PseudoZero;
         IF E1 + E1 <= E1 THEN
            
            Y2 := Underflow * HInverse;
            E1 := ABS (Y1 - Y2);
            Q := Y1;
            IF (UnderflowThreshold = Zero) AND (Y1 <> Y2) THEN
               UnderflowThreshold := Y1;
            END;
         END;
         PseudoZero := PseudoZero * H;
      IF PseudoZero < 0.0000001 THEN 
                        PseudoZero := 0.0;
                        END;
      UNTIL NOT ((Underflow > PseudoZero)
            AND (PseudoZero + PseudoZero > PseudoZero));

    END;
(*  Comment line 4530 .. 4560  *)
   IF PseudoZero <> Zero THEN
      
      WriteLn;
      Z := PseudoZero;
   (*  ... Test PseudoZero for "phoney- zero" violates  *)
   (*  ... PseudoZero < Underflow or PseudoZero < PseudoZero + Pseudo  ...  *)
      IF PseudoZero <= 0.0 THEN
         
         NoErrors [Failure] := NoErrors [Failure] + 1;
         message ('FAILURE      : Violation of');
         message ('Positive expressions can underflow to an ');
         message ('allegedly negative value');
         (* Writeln('PseudoZero that prints out as: ', PseudoZero);*)

         WriteString ("PseudoZero that prints out as: ");
         RealToStr(PseudoZero, str,20, 7,succ);
         message (str);

         X := - PseudoZero;
         IF X <= 0.0 THEN
            
            message ('But -PseudoZero, which should THEN be');
            (* Writeln('possitive, is''''t, it prints out as: ', X);*)

            WriteString ("possitive, is''''t, it prints out as: ");
            RealToStr(X, str,20, 7,succ);
            message (str);

         END
      ELSE
         
         NoErrors [Flaw] := NoErrors [Flaw] + 1;
         message ('FLAW        : Violation of');
         message ('Underflow can stick at an allegedly positive');
         (* Writeln('value PseudoZero that prints out as: ', PseudoZero); *)

         WriteString ("possitive, is''''t, it prints out as: ");
         RealToStr(X, str,20, 7,succ);
         message (str);

         (*END;*)
      TestPartialUnderflow;
      END;
   END;
END Milestone110;


PROCEDURE Milestone120;
BEGIN
   WriteLn;
   message(" ---------- Milestone 120 ---------- ");
   Milestone := 120;
   WriteLn;
   IF (CInverse * Y > CInverse * Y1) THEN
      
      S := H * S; (* i know now *)
      E0 := Underflow;
   END;

   IF NOT ((E1 = 0.0) OR (E1 = E0)) THEN
      
      NoErrors [Defect] := NoErrors [Defect] + 1;
      message ('DEFECT     : Violation of');
      IF E1 < E0 THEN
         
         message ('Products underflow at a higher');
         message (' threshold than dIFferences.');
         IF PseudoZero = Zero THEN
            E0 := E1;
         END
      ELSE
         
         message ('Difference underflows at a higher');
         message (' threshold than products.');
        
      END;
   END;

   message ('Smallest strictly positive number found is E0 =');
         RealToStr(E0, str,20, 7,succ);
         message (str);
   Z := E0;
   TestPartialUnderflow;
   Underflow := E0;
   IF N = 1.0 THEN
      Underflow := Y;
   END;
   I := 4;
   IF E1 = Zero THEN
      I := 3;
   END;
   IF UnderflowThreshold = Zero THEN
      I := I - 2;
   END;
   UnderflowNotGradual := TRUE;
   CASE I OF
      1:
         
         UnderflowThreshold := Underflow;
         IF (CInverse * Q) <> ((CInverse * Y) * S) THEN
            
            NoErrors [Failure] := NoErrors [Failure] + 1;
            UnderflowThreshold := Y;
            message ('FAILURE       : Violation of');
            message ('Either accuracy deteriorates as numbers');
            (* Writeln('approach a threshold UnderflowThreshold = ',
                  UnderflowThreshold);*)

            WriteString ("approach a threshold UnderflowThreshold = ");
            RealToStr(UnderflowThreshold, str,20, 7,succ);
            message (str);

           (*Writeln('coming down from ', C, ' or ELSE multiplication');*)

            WriteString ("coming down from ");
            RealToStr(C, str,20, 7,succ);
            WriteString (str);
            message (' or ELSE multiplication');

            message ('gets to many last digits wrong.');
         END;
         Pause; |
      2:
         
         NoErrors [Failure] := NoErrors [Failure] + 1;
         message ('FAILURE           Violation of');
         message ('Underflow confuses Comparison which alleges that');
         message ('Q = Y WHILE denying that |Q - Y| = 0 ; these values') ;

         (* write ('print out as Q = ', Q, ' Y = ', Y, ' |Q - Y| = ');*)

         WriteString ("print out as Q = ");
         RealToStr(Q, str,20, 7,succ);
         message (str);
         WriteString (" Y = ");
         RealToStr( Y, str,20, 7,succ);
         message (str);

         (* Writeln(ABS (Q - Y2));*)

         WriteString ("|Q - Y| = ");
         RealToStr(ABS(Q - Y2), str,20, 7,succ);
         message (str);
         UnderflowThreshold := Q; |
      3:
         
         X := X;
      (* FOR PRETTYPRINTER, IS DUMMY *) |
      4:
         IF (Q = UnderflowThreshold) AND (E1 = E0)
               AND (ABS ( UnderflowThreshold - E1 / E9) <= E1) THEN
            
            UnderflowNotGradual := FALSE;
            message ('Underflow is gradual; it incurs Absolute Error =') ;
            message ('(rounDOff in UnderflowThreshold) < E0.');
            Y := E0 * CInverse;
            Y := Y * (OneAndHalf + U2);
            X := CInverse * (One + U2);
            Y := Y / X;
            IEEE := (Y = E0);
         END;
      END; (* CASE *)

   IF UnderflowNotGradual THEN
      
      WriteLn;
      R := sqrt(Underflow / UnderflowThreshold);
      IF R <= H THEN
         
         Z := R * UnderflowThreshold;
         X := Z * (One + R * H * (One + H));
         
      ELSE
         
         Z := UnderflowThreshold;
         X := Z * (One + H * H * (One + H));
      END;

      IF NOT ((X = Z) OR (X - Z <> 0.0)) THEN
         
         NoErrors [Flaw] := NoErrors [Flaw] + 1;
         message ('FLAW     : Violation of');
         (* Writeln('X = ', X, ' is unequal to Z = ', Z);*)

         WriteString ("X = ");
         RealToStr(X, str,20, 7,succ);
         WriteString (str);
         WriteString (" is unequal to Z = ");
         RealToStr(Z, str,20, 7,succ);
         message (str);

         message ('yet X - Z yields ');
         Z9 := X - Z;
         RealToStr(Z9, str,20, 7,succ);
         message (str);
         message ('Should this NOT signal Underflow,');
         message ('This is a SERIOUS DEFECT that causes');
         message ('confusion when innocent statements like');
         message ('    IF(X = Z) THEN ... ELSE');
         message ('   (f(X) - f(Z)) / (X - Z) ...');
         message ('encounter division by Zero although actually');
         (* Writeln('X / Z = 1 + ', (X / Z - Half) - Half);*)

         WriteString ("X / Z = 1 + ");
         RealToStr((X / Z - Half) - Half, str,20, 7,succ);
         WriteString (str);
         
      END;
   END;

   (* Writeln('The Underflow threshold is ', UnderflowThreshold,
         ' below which'); *)

         WriteString ("The Underflow threshold is ");
         RealToStr( UnderflowThreshold, str,20, 7,succ);
         WriteString (str);
         message(' below which');

   message ('calculation may suffer larger Relative error THEN');
   message ('merely rounDOff.');
   Y2 := U1 * U1;
   Y := Y2 * Y2;
   Y2 := Y * U1;
   IF Y2 <= UnderflowThreshold THEN
      
      IF Y > E0 THEN
         
         NoErrors [Defect] := NoErrors [Defect] + 1;
         I := 5;
         
      ELSE
         
         NoErrors [SeriousDefect] := NoErrors [SeriousDefect] + 1;
         message ('SERIOUS ');
         I := 4;
      END;

      (* Writeln('DEFECT: Range is too narrow; U1^', I, ' Underflows.');*)

      WriteString ("DEFECT: Range is too narrow; U1^");
      IntToStr(I, str, 5, succ);
      WriteString (str);
      message (' Underflows.');
      
  END;
END Milestone120;

   


PROCEDURE Milestone130;
BEGIN
   WriteLn;
   message(" ---------- Milestone 130 ---------- ");
   Milestone := 130;
   message("SKIP this one ");
   WriteLn;
(*
   Y := - Int (Half - TwoForty * ln(UnderflowThreshold) / ln(HInverse)
) / TwoForty;
   Y2 := Y + Y;
   message ('Since underflow occurs below the threshold');
   (* Writeln('UnderflowThreshold = ( ', HInverse, ' ) ^ ( ', Y, ') only u nderflow');*)

         WriteString('UnderflowThreshould = ( ');
         RealToStr(HInverse, str,20, 7,succ);
         WriteString(str);
         WriteString(' ) ^ ( ');
         RealToStr(Y, str,20, 7,succ);
         WriteString(str);
         message(') only u nderflow');

   (* Writeln('should afflict the expression ( ', HInverse, ' ) ^ ( ', Y2, ' )');*)

         WriteString('should afflict the expression ( ');
         RealToStr(HInverse, str,20, 7,succ);
         WriteString(' ) ^ ( '); 
         RealToStr(Y2, str,20, 7,succ);
         message(str);

   message ('actually calculating yields: ');
   V9 := Power (HInverse, Y2);
   message (V9);
   IF NOT ((V9 >= 0) AND (V9 <= (Radix + Radix + E9) * UnderflowThreshol
d)) THEN
      
      NoErrors [SeriousDefect] := NoErrors [SeriousDefect] + 1;
      message ('SERIOUS DEFECT: Violation of');
      (* Writeln('this is not between 0 AND UnderflowThreshold = ', UnderflowThreshold);*)

         WriteString ('this is not between 0 AND UnderflowThreshold = ');
         RealToStr(UnderflowThreshold, str,20, 7,succ);
         WriteString(str);

      END
   ELSIF NOT (V9 > UnderflowThreshold * (One + E9)) THEN
      message ('this computed value is O.K.')
   ELSE
      
      NoErrors [Defect] := NoErrors [Defect] + 1;
      message ('DEFECT        : Violation of');
      (* Writeln('This is not between 0 AND UnderflowThreshold = ', UnderflowThreshold);*)

         WriteString ('This is not between 0 AND UnderflowThreshold = ');
         RealToStr(UnderflowThreshold, str,20, 7,succ);
         WriteString(str);

      END;
END SKIP  
*)
END Milestone130;

   


PROCEDURE Milestone140;
BEGIN
   WriteLn;
   message(" ---------- Milestone 140 ---------- ");
   Milestone := 140;
   WriteLn;
(*  ...calculate Exp2 = exp(2) = 7.389056099...  *)
   X := 0.0;
   I := 2;
   Y := Two * Three;
   Q := 0.0;
   N := 0.0;

   REPEAT
      Z := X;
      I := I + 1;
      Y := Y / FLOAT((I + 1));
      R := Y + Q;
      X := Z + R;
      Q := (Z - X) + R;
   UNTIL X <= Z;

   Z := (OneAndHalf + One / Eight) + X / (OneAndHalf * ThirtyTwo);
   X := Z * Z;
   Exp2 := X * X;
   X := F9;
   Y := X - U1;
   message ('Testing X^((X + 1) / (X - 1)) vs. exp(2) = ');
   (* Writeln(Exp2, ' as X -> 1.');*)

         RealToStr(Exp2, str,20, 7,succ);
         WriteString(str);
         message(' as X -> 1. ');

   Break := FALSE;
   I := 1;

   WHILE (NOT Break) AND (I < NoTrials) DO
      
      Z := X - BInverse;
      Z := (X + One) / (Z - (One - BInverse));
      Q := Power (X, Z - Exp2);

      IF ABS (Q) > TwoForty * U2 THEN
         
         Break := TRUE;
         N := 1.0;
         NoErrors [Defect] := NoErrors [Defect] + 1;
         message ('DEFECT        : Violation of');
         (* Writeln('Calculated (1 + ( ', (X - BInverse) - (One - BInverse
               ), ' ) ^ ( ', Z, ' )');*)

         WriteString('Calculated (1 + ( '); 
         RealToStr((X - BInverse) - (One - BInverse), str,20, 7,succ);
         WriteString(str);
         WriteString(' ) ^ ( ');
         RealToStr(Z, str,20, 7,succ);
         WriteString(str);
         message(" )");

         (* Writeln('Differs from correct value Q = ', Q);*)

         WriteString ('Differs from correct value Q = ');
         RealToStr(Q, str,20, 7,succ);
         message(str);

         message ('This much error may spoil financial');
         message ('calculations involving');
         message ('tiny interest rates.');
         
      ELSE
         
         Z := (Y - X) * Two + Y;
         X := Y;
         Y := Z;
         IF (One + (X - F9) * (X - F9) > One) THEN
            I := I + 1
         ELSIF X > One THEN
            
            IF N = 0.0 THEN
               message ('Accuracy seems adequate.');
            END;
            Break := TRUE;
            
         ELSE
            
            X := One + U2;
            Y := U2 + U2 + X;
            
         END
      END;
 END;
END Milestone140;
   


PROCEDURE Milestone150;
BEGIN
   WriteLn;
   message(" ---------- Milestone 150 ---------- ");
   Milestone := 150;
   WriteLn;
   IF PageNo = - 100 THEN
      (*begin SKIP NO POWER IN PASCAL  *)
      message ('Testing powers Z^Q at four nearly extreme values.');
      N := 0.0;
      Z := A1;
      Q := Int (Half - ln(C) / ln(A1));
      Break := FALSE;

      REPEAT
         X := CInverse;
         Y := Power (Z, Q);
         DoesYequalX;
         Q := - Q;
         X := C;
         Y := Power (Z, Q);
         DoesYequalX;
         IF Z < One THEN
            Break := TRUE
         ELSE
            Z := AInverse;
         END;
      UNTIL Break;

      PrintIfNPositive;
      IF N = 0.0 THEN
         message (' ... no discrepancies found');
      END;

      IF N > 0.0 THEN
         Pause;
      END;
   END;
(* SKIP  *)
END Milestone150;

   


PROCEDURE Milestone160;
BEGIN
   Pause;
   WriteLn;
   message(" ---------- Milestone 160 ---------- ");
   Milestone := 160;
   WriteLn;
   message('Searching for Overflow threshold:');
   message ('This will can generate an error.');
   message ('Try a few values for N, an take the');
   message ('one that just does not stop the machine');
   WriteString ('Did you find the correct value for N yet(y/n)?');
   (*readln (KEYBOARD);*)
   (*WHILE NOT EOL () DO
      ReadChar(ch);ReadLn;*)
   Break := TRUE;

   REPEAT

      (*WriteString ('N = ');*)
      (*readln (KEYBOARD);*)
(*
      WHILE NOT EOL() DO
         ReadInt (NoTimes, succ);
      END;ReadLn;
*)
      Y := - CInverse;
      V9 := HInverse * Y;
NoTimes := 20;
      FOR Index := 1 TO NoTimes DO
         
         V := Y;
         Y := V9;
         V9 := HInverse * Y;
      END;

(*
      IF (ch = 'N') OR (ch = 'n') THEN
         message ('N seems not large enough, try again.')
      ELSE
         
         message ('O.K.');
         Break := TRUE;
      END;
*)

   UNTIL Break;

   Z := V9;
   message ('Can Z = -Y overflow?');
   WriteString ('Trying it on Y = ');
   RealToStr(Y, str,20, 7,succ);
   WriteString(str);
   V9 := - Y;
   V0 := V9;
   IF (V - Y = V + V0) THEN
      message ('Seems O.K.')
   ELSE
      
      NoErrors [Flaw] := NoErrors [Flaw] + 1;
      WriteString ('finds a');
      WriteString ('FLAW      : Violation of');
      message (' -(-Y) differs from Y');
   END;

   IF Z <> Y THEN
      
      NoErrors [SeriousDefect] := NoErrors [SeriousDefect] + 1;
      message ('SERIOUS DEFECT: Violation of');
      (* Writeln('overflow past ', Y, ' shrinks to ', Z);*)

         WriteString( 'overflow past ');
         RealToStr(Y, str,20, 7,succ);
         WriteString(str);
         WriteString(' shrinks to ');
         RealToStr(Z, str,20, 7,succ);
         message(str);


      END;
   Y := V * (HInverse * U2 - HInverse);
   Z := Y + ((One - HInverse) * U2) * V;
   IF Z < V0 THEN
      Y := Z;
   END;

   IF Y < V0 THEN
      V := Y;
   END;

   IF V0 - V < V0 THEN
      V := V0;
   END;

   (* Writeln('Overflow threshold is V = ', V);*)

         WriteString ('Overflow threshold is V = ');
         RealToStr(V, str,20, 7,succ);
         message(str);

   (* Writeln('Overflow saturates at V0 = ', V0);*)

         WriteString ('Overflow saturates at V0 = ');
         RealToStr(V0, str,20, 7,succ);
         message(str);

   message ('No Overflow should ge signaled for V * 1 = ');
   V9 := V * One;
         RealToStr(V9, str,20, 7,succ);
         message(str);
   message ('                           nor for V / 1 = ');
   V9 := V / One;
         RealToStr(V9, str,20, 7,succ);
         message(str);
   message ('Any overflow signal separating this * from one');
   message ('above or below is a DEFECT.');
END Milestone160;

   


PROCEDURE Milestone170;
BEGIN
   WriteLn;
   message(" ---------- Milestone 170 ---------- ");
   Milestone := 170;
   WriteLn;
   TestCondition (Failure, (- V < V) AND (- V0 < V0)
         AND (- UnderflowThreshold < V)
         AND (UnderflowThreshold < V), 
     'Comparisons are confused by Overflow    ');
END Milestone170;

   


PROCEDURE Milestone175;
BEGIN
   WriteLn;
   message(" ---------- Milestone 175 ---------- ");
   Milestone := 175;
   WriteLn;
   
   FOR Index := 1 TO 3 DO
      
      CASE Index OF
         1:
            Z := UnderflowThreshold;|
         2:
            Z := E0;|
         3:
            Z := PseudoZero;
         END;

      IF Z <> 0.0 THEN
         
         V9 := sqrt(Z);
         Y := V9 * V9;
         IF ((Y / One - Radix * E9 < Z))
               OR (Y > (One + Radix + E9 * Z)) THEN
            
            IF V9 > U1 THEN
               
               NoErrors [SeriousDefect] := NoErrors [SeriousDefect] + 1;
               message ('SERIOUS DEFECT: Violation of');
            
            ELSE
               
               NoErrors [Defect] := NoErrors [Defect] + 1;
               message ('DEFECT      : Violation of');
            END;
            (* Writeln('Comparison alleges that what prints as Z = ', Z);*)

            WriteString ('Comparison alleges that what prints as Z = ');
            RealToStr(Z, str,20, 7,succ);
            message(str);

            (* Writeln('is to far from sqrt(Z) ^ 2 = ', Y);*)

            WriteString ('is to far from sqrt(Z) ^ 2 = ');
            RealToStr(Y, str,20, 7,succ);
            message(str);

         END;
      END;
   END; (* FOR *)
END Milestone175;

   


PROCEDURE Milestone180;
BEGIN
   WriteLn;
   message(" ---------- Milestone 180 ---------- ");
   Milestone := 180;
   WriteLn;
   IF NOT ((Radix <> 2.0) OR (Precision <> 56.0) OR (PseudoZero = Zero)
         OR ( - Zero = Zero)) THEN
      
      NoErrors [Failure] := NoErrors [Failure] + 1;
      message ('FAILURE         : Violation of');
      message ('Attemps to evaluate sqrt( Overflow threshold V)');
      
   ELSE
      
      FOR Index := 1 TO 2 DO
         
         IF Index = 1 THEN
            Z := V
         ELSE
            Z := V0;
         END;

         V9 := sqrt(Z);
         X := (One - Radix * E9) * V9;
         V9 := V9 * X;
         IF ((V9 < (One - Two * Radix * E9) * Z) OR (V9 > Z)) THEN
            
            Y := V9;
            IF X < W THEN
              
               NoErrors [SeriousDefect] := NoErrors [SeriousDefect] + 1;
               message ('SERIOUS ');
               
            ELSE
               NoErrors [Defect] := NoErrors [Defect] + 1;
            END;

            message ('DEFECT: Violation of');
            message ('Comparison alleges that Z = ');
            (* Writeln(Z, ' is too far from sqrt(Z) ^ 2 is: ', Y);*)

            RealToStr(Z, str,20, 7,succ);
            WriteString(str);

            WriteString (' is too far from sqrt(Z) ^ 2 is: ');

            RealToStr(Y, str,20, 7,succ);
            WriteString(str);

         END; (* IF *)
      END; (* FOR *)
   END;(* IF *)
END Milestone180;

   


PROCEDURE Milestone190;
BEGIN
   WriteLn;
   message(" ---------- Milestone 190 ---------- ");
   Milestone := 190;
   WriteLn;
   Pause;
   X := UnderflowThreshold * V;
   Y := Radix * Radix;

   IF NOT ((X * Y >= One) AND (X <= Y)) THEN
      
      IF ((X * Y >= U1) AND (X <= Y / U1)) THEN
         
         NoErrors [Defect] := NoErrors [Defect] + 1;
         message ('DEFECT       : Violation of');
         
      ELSE
         
         NoErrors [Flaw] := NoErrors [Flaw] + 1;
         message ('FLAW         : Violation of');
      END;

      (* Writeln('unbalanced range; UnderflowThreshold * V = ', X,
            ' is too far from 1');*)

       WriteString ('unbalanced range; UnderflowThreshold * V = ');
       RealToStr(X, str,20, 7,succ);
       WriteString(str);
       message(' is too far from 1');

  END;

END Milestone190;
   


PROCEDURE Milestone200;
BEGIN
   WriteLn;
   message(" ---------- Milestone 200 ---------- ");
   Milestone := 200;
   WriteLn;
   FOR Index := 1 TO 5 DO
      
      X := F9;

      CASE Index OF
         1:
            X := X;|
         2:
            X := One + U2;|
         3:
            X := V;|
         4:
            X := UnderflowThreshold;|
         5:
            X := Radix;
      END;

      Y := X;
      V9 := (Y / X - Half) - Half;
      IF V9 <> 0.0 THEN
         
         IF (Z = - U1) AND (I < 5) THEN
            
            NoErrors [Flaw] := NoErrors [Flaw] + 1;
            message ('FLAW     : Violation of');
            
         ELSE
            
            NoErrors [SeriousDefect] := NoErrors [SeriousDefect] + 1;
         END;
         (* Writeln('  X / X dIFfers from 1 when X = ', X);*)

         WriteString ('  X / X differs from 1 when X = ');
         RealToStr(X, str,20, 7,succ);
         message(str);

         (* Writeln('  instead, X / X - 1/2 - 1/2 = ', Z);*)

         WriteString ('  instead, X / X - 1/2 - 1/2 = ');
         RealToStr(Z, str,20, 7,succ);
         message(str);

         WriteLn;
      END;
   END;
END Milestone200;

   


PROCEDURE Milestone210;
BEGIN
   WriteLn;
   message(" ---------- Milestone 210 ---------- ");
   Milestone := 210;
   WriteLn;
   MyZero := 0;
   WriteLn;
(*
   message ('What message and/or values does Division by Zero produce?') ;
   message ('This can interupt your program. You can ');
   message ('skip this part IF you wish.');
   message ('Do you wish to compute 1 / 0? ');
  (* readln (KEYBOARD);*)
   ReadChar(ch); ReadLn;
   IF (ch = 'Y') OR (ch = 'y') THEN
*)

      (* Writeln('Trying to compute 1 / 0 produces: ', One / MyZero) *)

         WriteString ('Trying to compute 1 / 0 produces: ');
         RealToStr( One / FLOAT(MyZero), str,20, 7,succ);
         WriteString(str);

(*
   ELSE
      message ('O.K.');
      message ('Do you wish to compute 0 / 0?');
      (*readln (KEYBOARD);
      read (KEYBOARD, ch);*)
      ReadChar(ch);ReadLn;
   END;
*)

(*
   IF (ch = 'Y') OR (ch = 'y') THEN
      (* Writeln('Trying to compute 0 / 0 produces: ', MyZero / MyZero) *)
*)

         WriteString('Trying to compute 0 / 0 produces: '); 
         RealToStr(FLOAT(MyZero) / FLOAT(MyZero), str,20, 7,succ);
         WriteString(str);

(*
   ELSE
      message ('O.K.');
   END;
*)

END Milestone210;

   


PROCEDURE Milestone220;
BEGIN
   WriteLn;
   message(" ---------- Milestone 220 ---------- ");
   Milestone := 220;
   WriteLn;
   Pause;
   WriteLn;
   message ('The number of Failures encountered =        ');
   WriteString ('The number of Serious Defects encountered = ');
   (* Writeln(NoErrors [SeriousDefect]);*)

         IntToStr(NoErrors [SeriousDefect], str, 5, succ);
         message(str);

   WriteString ('The number of Defects encountered =         ');
   (* Writeln(NoErrors [Defect]);*)

         IntToStr(NoErrors [Defect], str, 5, succ);
         message(str);

   WriteString ('The number of Flaws encountered =           ');
   (* Writeln(NoErrors [Flaw]);*)

         IntToStr(NoErrors [Flaw], str, 5, succ);
         message(str);

   WriteLn;
   IF (NoErrors [Failure] + NoErrors [SeriousDefect] + NoErrors [Defect]
         + NoErrors [Flaw]) > 0 THEN
      
      IF (NoErrors [Failure] + NoErrors [SeriousDefect] + 
          NoErrors [ Defect] = 0) AND (NoErrors [Flaw] > 0) THEN
         
         message ('The arithmetic diagnosed seems ');
         message ('satisfactory though flawed.');
      END;

      IF (NoErrors [Failure] + NoErrors [SeriousDefect] = 0)
            AND ( NoErrors [Defect] > 0) THEN
         
         message ('The arithmetic diagnosed may be acceptable');
         message ('despite inconvenient Defects.');
      END;

      IF (NoErrors [Failure] + NoErrors [Defect] > 0) THEN
         
         message ('The arithmetic diagnosed has ');
         message ('unacceptable serious defects.');
      END;

      IF (NoErrors [Failure] > 0) THEN
         
         message ('fatal FAILURE may have spoiled this');
         message (' program subsequent diagnose.');
         
      END

   ELSE
      
      message ('No failures, defects nor flaws have been discovered.');
      IF NOT ((RMult = Rounded) AND (RDiv = Rounded)
            AND (RAddSub = Rounded) AND (RSqrt = Rounded)) THEN
         message ('The arithmetic diagnosed seems satisfactory')
      ELSIF (StickyBit < One) OR 
            ((Radix - Two) * (Radix - Nine - One) <> 0.0) THEN
         message ('The arithmetic diagnosed appears to be excellent!')
      ELSE
         
         message ('Rounding appears to conform to ');
         message ('the proposed IEEE standard p');
         IF (Radix = Two) AND ((Precision - Four * Three * Two) * ( Precision -
               TwentySeven - TwentySeven + One) = Zero) THEN
            message ('754')
         ELSE
            message ('854');
         END;

         IF NOT IEEE THEN
            
            message ('Except for possibly for Double Rounding');
            message ('during Gradual Underflow');
         END;
      END;
   END;
   message ('END OF TEST.');
END Milestone220;


PROCEDURE printnum(VAR comment : ARRAY OF CHAR ; num : REAL);
BEGIN
        WriteString(comment);
	RealToStr(num, str,20, 7,succ);
	message (str);
END printnum;

BEGIN (*main*)
   Rmode := Rnear;
   NoErrors [Failure] := 0;
   NoErrors [SeriousDefect] := 0;
   NoErrors [Defect] := 0;
   NoErrors [Flaw] := 0;
   PageNo := 0;


Milestone7;
Milestone10;
Milestone20;
Milestone25;
Milestone30;
Milestone35;

Milestone40;
Milestone45;
Milestone50;
Milestone60;
Milestone70;

Milestone80;
Milestone85;
Milestone90;
Milestone100;
Milestone110;
Milestone120;
Milestone140;
Milestone150;
Milestone160;
Milestone170;
Milestone175;
Milestone180;
Milestone190;
Milestone200;
Milestone210;
Milestone220;

END  PARA .