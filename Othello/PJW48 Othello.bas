' PJW48 Othello
' Created by PJW48
' https://en.pjw48.net/

_TITLE "PJW48 Othello"

DEFINT A-Z

CONST False = 0, True = NOT False

TYPE T_Player
    'Name AS STRING * 12
    Score AS _BYTE
    CPU AS _BYTE
END TYPE
DIM SHARED Player(1 TO 2) AS T_Player

TYPE T_GameStatus
    Turn AS _BYTE
    PassStreak AS _BYTE
    SFlag AS _BYTE '0: Ready, 1: Suspended, 2: Start
    X AS _BYTE
    Y AS _BYTE
END TYPE
DIM SHARED GameStatus AS T_GameStatus

DIM SHARED Board(-1 TO 8, -1 TO 8) AS _UNSIGNED _BIT * 2 ' Board (8x8) / 0: Empty, 1: Spot, 2: Black(1), 3: White(2)
DIM SHARED CPUMoves(0 TO 63) AS _BYTE ' For Computer Moves

' Exit Sign (Ctrl-Break)
DIM SHARED ExitSign AS _BYTE

' End of Definition

GameInit
GameProcess

SYSTEM 0

SUB DrawHelp
    SELECT CASE GameStatus.SFlag
        CASE 0, 1
            LOCATE 17, 53: COLOR 10, 0: PRINT "1";: COLOR 2, 0: PRINT " ...... 1P Toggle";
            LOCATE 18, 53: COLOR 10, 0: PRINT "2";: COLOR 2, 0: PRINT " ...... 2P Toggle";
            IF GameStatus.SFlag = 1 THEN
                LOCATE 19, 53: COLOR 10, 0: PRINT "Enter";: COLOR 2, 0: PRINT " ... Continue";
                LOCATE 20, 53: COLOR 10, 0: PRINT "R";: COLOR 2, 0: PRINT " ..... Game Reset";
            ELSE
                LOCATE 19, 53: COLOR 10, 0: PRINT "Enter";: COLOR 2, 0: PRINT " ...... Start";
                LOCATE 20, 53: COLOR 2, 0: PRINT "                  ";
            END IF
            LOCATE 21, 53: COLOR 10, 0: PRINT "ESC";: COLOR 2, 0: PRINT " ......... Quit";
        CASE 2
            LOCATE 17, 53: COLOR 10, 0: PRINT "Arrow";: COLOR 2, 0: PRINT " ..... Cursor";
            LOCATE 18, 53: COLOR 10, 0: PRINT "Z";: COLOR 2, 0: PRINT " ...... Set Piece";
            LOCATE 19, 53: COLOR 2, 0: PRINT "                  ";
            LOCATE 20, 53: COLOR 2, 0: PRINT "                  ";
            LOCATE 21, 53: COLOR 10, 0: PRINT "ESC";: COLOR 2, 0: PRINT " ... Suspension";
    END SELECT
END SUB

SUB DrawPiece (Y, X)
    LOCATE 6 + Y * 2, 15 + X * 4
    SELECT CASE Board(Y, X)
        CASE 0: COLOR , 0: PRINT " "; ' Empty
        CASE 1: COLOR 10, 0: PRINT CHR$(249); ' Valid Spot
        CASE 2: COLOR 7, 0: PRINT CHR$(1); ' Black
        CASE 3: COLOR 15, 0: PRINT CHR$(2); ' White
    END SELECT
END SUB

SUB GameInit
    RANDOMIZE TIMER
    FOR I = 1 TO 2
        Player(I).CPU = False
    NEXT I

    FOR I = 0 TO 63
        READ CPUMoves(I)
    NEXT I
    ' CPUMoves L1, L2, L3, L4, L5, L6
    DATA 0,7,56,63: DATA 27,28,35,36: 'First: Four Corner (0 to 3), Core (4 to 7)
    DATA 18,19,20,21,26,29,34,37,42,43,44,45: 'Second: Core (8 to 19)
    DATA 2,3,4,5,16,23,24,31,32,39,40,47,58,59,60,61: 'Third: Edge (20 to 35)
    DATA 10,11,12,13,17,22,25,30,33,38,41,46,50,51,52,53: 'Fourth: Edge 2 (36 to 51)
    DATA 1,6,8,15,48,55,57,62: 'Fifth: C Square (52 to 59)
    DATA 9,14,49,54: 'Sixth: X Square (60 to 63)

    ' Draw
    COLOR 15, 0: CLS: LOCATE 2, 34, , 0, 31
    PRINT "PJW48 Othello"
    LOCATE 24, 21: COLOR 13: PRINT "Created by PJW48";
    LOCATE 24, 40: COLOR 11: PRINT "https://en.pjw48.net/";

    COLOR 10, 0
    FOR J = 0 TO 1: FOR I = 0 TO 7
            LOCATE 4 + J * 18, 15 + I * 4: PRINT CHR$(65 + I);
            LOCATE 6 + I * 2, 11 + J * 36: PRINT CHR$(49 + I);
    NEXT I, J

    COLOR 2, 0
    FOR J = 5 TO 21
        LOCATE J, 13
        SELECT CASE J
            CASE 5 'Top Edge
                PRINT CHR$(201);
                FOR I = 1 TO 7: PRINT STRING$(3, 205); CHR$(209);: NEXT I
                PRINT STRING$(3, 205); CHR$(187);
            CASE 21 'Bottom Edge
                PRINT CHR$(200);
                FOR I = 1 TO 7: PRINT STRING$(3, 205); CHR$(207);: NEXT I
                PRINT STRING$(3, 205); CHR$(188);
            CASE 9, 17
                PRINT CHR$(199); STRING$(3, 196); CHR$(197); STRING$(3, 196); CHR$(206);
                PRINT STRING$(3, 196); CHR$(197); STRING$(3, 196); CHR$(197); STRING$(3, 196); CHR$(197);
                PRINT STRING$(3, 196); CHR$(206); STRING$(3, 196); CHR$(197); STRING$(3, 196); CHR$(182);
            CASE 7, 11, 13, 15, 19
                PRINT CHR$(199);
                FOR I = 1 TO 7: PRINT STRING$(3, 196); CHR$(197);: NEXT I
                PRINT STRING$(3, 196); CHR$(182);
            CASE ELSE
                PRINT CHR$(186);
                FOR I = 1 TO 7: PRINT SPACE$(3); CHR$(179);: NEXT I
                PRINT SPACE$(3); CHR$(186);
        END SELECT
    NEXT J
    FOR J = 5 TO 14
        LOCATE J, 53
        SELECT CASE J
            CASE 5: PRINT CHR$(201); STRING$(16, 205); CHR$(187);
            CASE 14: PRINT CHR$(200); STRING$(16, 205); CHR$(188);
            CASE 7, 10:
                PRINT CHR$(186); " ";
                COLOR 14: PRINT "MAN";
                COLOR 2: PRINT SPACE$(3); "Score"; SPACE$(4); CHR$(186);
            CASE 8: PRINT CHR$(199); STRING$(16, "-"); CHR$(182);
            CASE 11: PRINT CHR$(199); STRING$(16, 196); CHR$(182);
            CASE ELSE: PRINT CHR$(186); SPACE$(16); CHR$(186);
        END SELECT
    NEXT J
    LOCATE 6, 55: COLOR 2, 0: PRINT "Player 1 ";: COLOR 7, 0: PRINT "BLACK";
    LOCATE 9, 55: COLOR 2, 0: PRINT "Player 2 ";: COLOR 15, 0: PRINT "WHITE";

END SUB

SUB GameProcess
    ' Before Start
    BeforeStart:
    DrawHelp

    DO
        IF _EXIT THEN EXIT SUB

        SELECT CASE _KEYHIT
            CASE 49 '1
                Player(1).CPU = NOT Player(1).CPU
                LOCATE 7, 55
                IF Player(1).CPU THEN COLOR 6: PRINT "CPU"; ELSE COLOR 14: PRINT "MAN";
            CASE 50 '2
                Player(2).CPU = NOT Player(2).CPU
                LOCATE 10, 55
                IF Player(2).CPU THEN COLOR 6: PRINT "CPU"; ELSE COLOR 14: PRINT "MAN";
            CASE 13 'Enter
                EXIT DO
            CASE 27 'ESC
                EXIT SUB ' Quit
        END SELECT
    LOOP
    GameStart
    IF ExitSign THEN EXIT SUB
    GOTO BeforeStart

END SUB

SUB GameStart
    GameStatus.SFlag = 2 ' Start Flag
    DrawHelp

    FOR I = 1 TO 200
        ' CPU L1 Swap
        A = INT(RND * 4): B = INT(RND * 4)
        SWAP CPUMoves(A), CPUMoves(B)
        ' CPU L2 Swap
        A = INT(RND * 12) + 8: B = INT(RND * 12) + 8
        SWAP CPUMoves(A), CPUMoves(B)
        ' CPU L3 Swap
        A = INT(RND * 16) + 20: B = INT(RND * 16) + 20
        SWAP CPUMoves(A), CPUMoves(B)
        ' CPU L4 Swap
        A = INT(RND * 16) + 36: B = INT(RND * 16) + 36
        SWAP CPUMoves(A), CPUMoves(B)
        ' CPU L5 Swap
        A = INT(RND * 8) + 52: B = INT(RND * 8) + 52
        SWAP CPUMoves(A), CPUMoves(B)
        ' CPU L6 Swap
        A = INT(RND * 4) + 60: B = INT(RND * 4) + 60
        SWAP CPUMoves(A), CPUMoves(B)
    NEXT I

    ' Game Reset
    FOR I = 1 TO 2
        Player(I).Score = 2
    NEXT I
    GameStatus.Turn = 1
    GameStatus.PassStreak = 0

    ' Clear Board
    FOR J = 0 TO 7: FOR I = 0 TO 7
            IF (I = 3 OR I = 4) AND (J = 3 OR J = 4) THEN
                ' 4 Cores
                Board(J, I) = 3 - ((I + J) MOD 2)
            ELSE
                Board(J, I) = 0
            END IF
            DrawPiece J, I
    NEXT I, J

    DO
        IF _EXIT THEN ExitSign = True: EXIT SUB
        Scoring
        TurnStart:
        KeyFlag = False

        IF Player(1).Score + Player(2).Score >= 64 THEN
            ' Full Board
            EXIT DO
        ELSEIF Player(1).Score <= 0 OR Player(2).Score <= 0 THEN
            ' Eliminated
            ValidCnt = ValidCheck
            EXIT DO
        ELSEIF GameStatus.PassStreak >= 2 THEN
            ' Both Pass
            EXIT DO
        END IF

        COLOR 2, 0
        LOCATE 12, 55: PRINT "Player "; CHR$(48 + GameStatus.Turn); " ";
        ' Valid Move Check
        ValidCnt = ValidCheck
        IF ValidCnt = 0 THEN
            ' No Valid Moves
            LOCATE 12, 64, 0: COLOR 10, 0: PRINT " PASS";
            GameStatus.PassStreak = GameStatus.PassStreak + 1
            IF Player(GameStatus.Turn).CPU OR GameStatus.PassStreak >= 2 THEN
                SLEEP 1
            ELSE
                LOCATE 13, 55: PRINT "Press any key.";
                SLEEP
            END IF
            GameStatus.Turn = 3 - GameStatus.Turn
        ELSE
            ' Valid Moves
            LOCATE 13, 55: PRINT "              ";
            LOCATE 12, 64: COLOR 10, 0: PRINT "Turn ";: LOCATE 12, 68, 1
            GameStatus.PassStreak = 0

            IF Player(GameStatus.Turn).CPU THEN
                SLEEP 1
                FOR K = 0 TO 63
                    GameStatus.Y = CPUMoves(K) \ 8
                    GameStatus.X = CPUMoves(K) MOD 8
                    IF Board(GameStatus.Y, GameStatus.X) = 1 THEN
                        SetStone GameStatus.Y, GameStatus.X
                        GameStatus.Turn = 3 - GameStatus.Turn
                        EXIT FOR
                    END IF
                NEXT K
            ELSE
                LOCATE 6 + GameStatus.Y * 2, 15 + GameStatus.X * 4, 1, 0, 31
                DO
                    IF _EXIT THEN ExitSign = True: EXIT SUB
                    SELECT CASE _KEYHIT
                        CASE 18432 ' Up
                            GameStatus.Y = GameStatus.Y - 1
                            IF GameStatus.Y < 0 THEN GameStatus.Y = 7
                            KeyFlag = True
                        CASE 20480 ' Down
                            GameStatus.Y = GameStatus.Y + 1
                            IF GameStatus.Y > 7 THEN GameStatus.Y = 0
                            KeyFlag = True
                        CASE 19200 ' Left
                            GameStatus.X = GameStatus.X - 1
                            IF GameStatus.X < 0 THEN GameStatus.X = 7
                            KeyFlag = True
                        CASE 19712 ' Right
                            GameStatus.X = GameStatus.X + 1
                            IF GameStatus.X > 7 THEN GameStatus.X = 0
                            KeyFlag = True
                        CASE 90, 122 ' Z
                            IF Board(GameStatus.Y, GameStatus.X) = 1 THEN
                                SetStone GameStatus.Y, GameStatus.X
                                GameStatus.Turn = 3 - GameStatus.Turn
                                KeyFlag = True
                            END IF
                        CASE 27 ' ESC
                            GOTO Suspension
                            KeyFlag = True
                    END SELECT
                LOOP UNTIL KeyFlag
            END IF
        END IF
    LOOP

    COLOR 2, 0
    LOCATE 12, 55: PRINT "  GAME  OVER  ";
    LOCATE 13, 55, 0: COLOR 10, 0
    _DELAY 1
    IF Player(1).Score > Player(2).Score THEN
        PRINT "Player 1  Win!";
    ELSEIF Player(1).Score < Player(2).Score THEN
        PRINT "Player 2  Win!";
    ELSE
        PRINT "  Draw  Game  ";
    END IF
    GameStatus.SFlag = 0
    DrawHelp
    _KEYCLEAR
    EXIT SUB

    Suspension:
    GameStatus.SFlag = 1
    DrawHelp
    COLOR 2, 0
    LOCATE 12, 55, 0: PRINT "Game Suspended";
    DO
        IF _EXIT THEN ExitSign = True: EXIT SUB

        SELECT CASE _KEYHIT
            CASE 49 '1
                Player(1).CPU = NOT Player(1).CPU
                LOCATE 7, 55
                IF Player(1).CPU THEN COLOR 6: PRINT "CPU"; ELSE COLOR 14: PRINT "MAN";
            CASE 50 '2
                Player(2).CPU = NOT Player(2).CPU
                LOCATE 10, 55
                IF Player(2).CPU THEN COLOR 6: PRINT "CPU"; ELSE COLOR 14: PRINT "MAN";
            CASE 13 'Enter
                GameStatus.SFlag = 2
                DrawHelp
                GOTO TurnStart
            CASE 82, 114 'R
                LOCATE 12, 55, 0: PRINT " Game Aborted.";
                GameStatus.SFlag = 0
                DrawHelp
                EXIT SUB ' Quit
            CASE 27 'ESC
                ExitSign = True
                EXIT SUB ' Quit
        END SELECT
    LOOP

END SUB

SUB Scoring
    Player(1).Score = 0: Player(2).Score = 0
    FOR J = 0 TO 7: FOR I = 0 TO 7
            K = Board(J, I) - 1
            IF K >= 1 THEN Player(K).Score = Player(K).Score + 1
    NEXT I, J
    COLOR 10, 0
    LOCATE 7, 67: PRINT USING "##"; Player(1).Score
    LOCATE 10, 67: PRINT USING "##"; Player(2).Score
END SUB

SUB SetStone (Y, X)
    A = GameStatus.Turn + 1
    B = 4 - GameStatus.Turn
    Board(Y, X) = A
    DrawPiece Y, X

    FOR dY = -1 TO 1
        FOR dX = -1 TO 1
            ChkFlag = False
            IF dY = 0 AND dX = 0 THEN dX = 1 'Prevent Infinite Loop
            IF Board(Y + dY, X + dX) = B THEN 'Check Opponent's Piece
                K = 2
                DO
                    IF Board(Y + dY * K, X + dX * K) = A THEN 'Check Own Piece
                        ChkFlag = True
                        EXIT DO
                    ELSEIF Board(Y + dY * K, X + dX * K) < 2 THEN 'Check Empty
                        EXIT DO
                    END IF
                    K = K + 1
                LOOP UNTIL Y + dY * K < 0 OR Y + dY * K > 7 OR X + dX * K < 0 OR X + dX * K > 7

                IF ChkFlag THEN
                    FOR L = 1 TO K - 1
                        Board(Y + dY * L, X + dX * L) = A
                        DrawPiece Y + dY * L, X + dX * L
                    NEXT L
                END IF
            END IF
        NEXT dX
    NEXT dY

END SUB

FUNCTION ValidCheck
    ValidCnt = 0
    FOR J = 0 TO 7: FOR I = 0 TO 7
            IF Board(J, I) >= 2 THEN GOTO SkipCheck 'Skip non empty cell
            V = 0
            FOR dY = -1 TO 1
                FOR dX = -1 TO 1
                    IF dY = 0 AND dX = 0 THEN dX = 1 'Prevent Infinite Loop
                    IF Board(J + dY, I + dX) = 4 - GameStatus.Turn THEN 'Check Opponent's Piece
                        K = 2
                        DO
                            IF Board(J + dY * K, I + dX * K) = GameStatus.Turn + 1 THEN 'Check Own Piece
                                V = 1
                                EXIT DO
                            ELSEIF Board(J + dY * K, I + dX * K) < 2 THEN 'Check Empty
                                EXIT DO
                            END IF
                            K = K + 1
                        LOOP UNTIL J + dY * K < 0 OR J + dY * K > 7 OR I + dX * K < 0 OR I + dX * K > 7
                    END IF
                NEXT dX
            NEXT dY
            ValidCnt = ValidCnt + V
            Board(J, I) = V
            DrawPiece J, I
            SkipCheck:
    NEXT I, J
    ValidCheck = ValidCnt
END FUNCTION
