' QB64 Soukoban
' Created by PJW48.net

_TITLE "PJW48 Soukoban"

DEFINT A-Z

CONST False = 0, True = NOT False

' Type for ObjSprite (Box, Wall, Player)
' 0: Empty, 1: Spot, 2: Box, 3: Box in Spot, 4: Wall, 5: Player
TYPE T_ObjSprite
    Char AS STRING * 1
    Colors AS _UNSIGNED _BYTE
END TYPE
DIM SHARED ObjSprite(0 TO 5) AS T_ObjSprite

' Player State
TYPE T_Player
    Stage AS INTEGER
    X AS _BYTE
    Y AS _BYTE
    Boxes AS INTEGER
    Goals AS INTEGER
    Moves AS INTEGER
END TYPE
DIM SHARED Player AS T_Player

' Stages (Stg, Y, X)
DIM SHARED Stages(1 TO 60, 0 TO 21, 0 TO 29) AS _BIT * 4
DIM SHARED CurrentStage(-1 TO 22, -1 TO 30) AS _BIT * 4

' Goal Records
TYPE T_Records
    Comp AS _BYTE
    Moves AS INTEGER
END TYPE
DIM SHARED Records(1 TO 60) AS T_Records

' Exit Sign (Ctrl-Break)
DIM SHARED ExitSign AS _BYTE
' Record Flag
DIM SHARED RecordFlag AS _BYTE

' Soukoban Record File
ON ERROR GOTO FileErr:
OPEN "SoukobanRecords.dat" FOR INPUT AS #1
FOR I = 1 TO 60
    INPUT #1, Records(I).Comp, Records(I).Moves
NEXT I
CLOSE #1
CreatedRecordFile:
ON ERROR GOTO 0

GameInit
StageSelect

CLS

' Save Record File
IF RecordFlag THEN
    OPEN "SoukobanRecords.dat" FOR OUTPUT AS #1
    FOR I = 1 TO 60
        PRINT #1, Records(I).Comp, Records(I).Moves
    NEXT I
    CLOSE #1
END IF

SYSTEM 0

FileErr:
RESUME NEXT

SUB GameInit
    Player.Stage = 1

    WIDTH 40
    _CONTROLCHR OFF
    ' CS Border
    FOR I = -1 TO 30
        CurrentStage(-1, I) = 4: CurrentStage(22, I) = 4
    NEXT I
    FOR J = -1 TO 22
        CurrentStage(J, -1) = 4: CurrentStage(J, 30) = 4
    NEXT J

    ' Read GaneObj Data
    FOR I = 0 TO 5
        READ TmpChr, TmpFg, TmpBg
        ObjSprite(I).Char = CHR$(TmpChr)
        ObjSprite(I).Colors = TmpBg * 32 + TmpFg
    NEXT I
    ' Char, FgCol, BgCol
    DATA 32,7,0
    DATA 250,14,0
    DATA 254,7,0
    DATA 254,12,0
    DATA 177,6,0
    DATA 2,14,0

    ' Read Stages Data
    FOR I = 1 TO 60
        READ Temp$
        FOR J = 0 TO 329
            TempASC = ASC(Temp$, J + 1) - 64
            Y = J \ 15: X = (J MOD 15) * 2
            Stages(I, Y, X) = TempASC \ 8
            Stages(I, Y, X + 1) = TempASC MOD 8
        NEXT J
    NEXT I

    DATA "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@dd`@@@@@@@@@@@@`@`@@@@@@@@@@@@b@`@@@@@@@@@@@d`Bd`@@@@@@@@@@`B@P`@@@@@@@@@d``d``@@ddd@@@@`@`d`ddd`AL@@@@`PB@@@@@@AL@@@@dd`ddDld`AL@@@@@@`@@Dd@ddd@@@@@@dddd@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
    DATA "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@dddddd@@@@@@@@@aHD@@Dd@@@@@@@@aHDB@PD@@@@@@@@aHDTd`D@@@@@@@@aH@ED`D@@@@@@@@aHDD@Pd@@@@@@@@dddDbBD@@@@@@@@@`PBBBD@@@@@@@@@`@D@@D@@@@@@@@@dddddd@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
    DATA "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@dddd@@@@@@@@@@@`@@l@@@@@@@@@@@`TPd@@@@@@@@@@@`PB`@@@@@@@@@@@dPP`@@@@@@@dddd`P`d`@@@@@@aIHD`PB@`@@@@@@dIH@B@P@`@@@@@@aIHDdddd`@@@@@@dddd@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
    DATA "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@dddd@@@@@@@@@@@`AIL@@@@@Dddddd`AIL@@@@@D@@`BB@AIL@@@@@DBRb@P`AIL@@@@@D@P@@P`AIL@@@@@DBPbBBdddd@@@@dd@P`@@`@@@@@@@`@`dddd`@@@@@@@`@B@d@@@@@@@@@@`RbPl@@@@@@@@@@`@`@d@@@@@@@@@@dddd`@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
    DATA "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@dd`@@@@@@@@@@@@`@dd`@@@@@@@@@@`bd@`@@@@@@@@@@`@@P`@@@@@@dddd`d`@`@@@@@@aIHD`PBd`@@@@@@aIH@BBPd@@@@@@@aIHDb@Pl@@@@@@@dddd`B@d@@@@@@@@@@@`PPD@@@@@@@@@@@d`dD@@@@@@@@@@@@`@D@@@@@@@@@@@@ddd@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
    DATA "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@Ddd`Dd@@@@@@@@@DI@`dl`@@@@@@@@DI@d`@`@@@@@@@@DI@@BP`@@@@@@@@DI@``P`@@@@@@@@DId``P`@@@@@@@@Dd`Pb@`@@@@@@@@@@`B`P`@@@@@@@@@@`PB@`@@@@@@@@@@`D`@`@@@@@@@@@@dddd`@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
    DATA "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@Ddd@@@@@@@@@Dddd@D`@@@@@@@@dDEdBP`@@@@@@@@`@B@@@`@@@@@@@@`B@d`@`@@@@@@@@d`ddbd`@@@@@@@@`PDdAL@@@@@@@@@`PPPIL@@@@@@@@@`@DdIL@@@@@@@@@`RDDIL@@@@@@@@@`DdDdd@@@@@@@@@dd@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
    DATA "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@Dd`@@@@@@@@@@@@D@ddddd`@@@@@@@D@@P@PP`@@@@@@@DB`P`B@`@@@@@@@D@PPD@@`@@@@@@DdB``Dd``@@@@@@DlPPPD`@`@@@@@@D@@Pb`@``@@@@@@D`B@@PPP`@@@@@@@dd@dddd`@@@@@@@Dd@d`@@@@@@@@@@D@@@`@@@@@@@@@@D@@@`@@@@@@@@@@DIII`@@@@@@@@@@DIII`@@@@@@@@@@DIII`@@@@@@@@@@Dddd`@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
    DATA "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ddd`@@@@@@@@@@@`AI`@@@@@@@@@dd`AI`@@@@@@@@@`@@AI`@@@@@@@@@`D`AI`@@@@@@@@@dD`AI`@@@@@@@@DdDddd`@@@@@@@@DBRD`@@@@@@@@Ddd@PPdd`@@@@@@d@DPP@`@`@@@@@@eB@P@B@P`@@@@@@dddBPPdd`@@@@@@@@DB@@`@@@@@@@@@@Dd`d`@@@@@@@@@@@@`D@@@@@@@@@@@@@`D@@@@@@@@@@@@@`D@@@@@@@@@@@@@dd@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
    DATA "@@@@@@@@@@@@@@@@@@@@@@@@dd@@@@@@@@@@Ddd`D@@@@@@@@@@D@@@D@@@@@@@@@@D@ddDd@@@@@Dd@dd`d`@D@@@@@dld`@RP`@D@@@@@`R@BPP@aIL`@@@@`BR`@B@aII`@@@@`P@`RBPaII`@@@@d`@`B@@aII`@@@@@`@`PPPaII`@@@@@`ddd`daII`@@@@@`@`BB@aII`@@@@@d``RBBddd`@@@@@@``B@@@`@@@@@@@@``RPRP`@@@@@@@@``@@@``@@@@@@@@`dddd``@@@@@@@@`@@@@@`@@@@@@@@dddddd`@@@@@@@@@@@@@@@@@@@"
    DATA "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@Dd`@@@@@@@@@@ddD@`@@@@@@@@@d`DdP`@@@@@@@@D`@hB@`@@@@@@@@d@PRdD`@@@@@@@@`DT`@@`@@@@@@@@``PRDDd@@@@@@@@`@P`DBDdd@@@@@Dd`@D@RD@D@@@@@Dd`dB@@@@D@@@@@DH@Dd@dddd@@@@@DIALDd`@@@@@@@@DILL@@@@@@@@@@@DIIL@@@@@@@@@@@Dddd@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
    DATA "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@dddd`@@@@@@@@@@cKcK`@@@@@@@@@@aYYY`@@@@@@@@@@cKKK`@@@@@@@@@@aYYY`@@@@@@@@@@cKKK`@@@@@@@@@@d`@d`@@@@@@@@@@@`@`@@@@@@@@@@dddDdd`@@@@@@@@`@@@@@`@@@@@@@@`PPPPP`@@@@@@@@dBBBBD`@@@@@@@@DPPPPT@@@@@@@@@D@Bj@D@@@@@@@@@D@dd`D@@@@@@@@@Dd`@dd@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
    DATA "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@Ddddd@@@@@@@@@Dd@D`Ddd@@@@@@Dd@@@`D@Dd`@@@@D@RDP`D@IH`@@@@DD@TjdDDLH`@@@@D@dDPD@@IH`@@@@DB`@BDDDLH`@@@@D@@d@dPPIH`@@@@DBD`@`DTLH`@@@@D`R@P@PBIH`@@@@@b@ddd@@d@`@@@@@`@`@Ddddd`@@@@@dd`@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
    DATA "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@dddddddd@@@@@@@`@@@@@@D@@@@@@@``ddd@@D@@@@@@@``BBBB`D@@@@@@@``@UP@dD`@@@@@@``bBBdaI`@@@@@@``@PPDaI`@@@@@@`dbRBDaI`@@@@@@`@@`dDaI`@@@@@@dd`@dDaI`@@@@@@@@dd`@@d`@@@@@@@@@@`@@`@@@@@@@@@@@ddd`@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
    DATA "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@Dd`@@@@@@@@@@@dd@`@@@@@@@@@@D`D@`@@@@@@@@@@D@PP`@@@@@@@@@DdDP@dd@@@@@@@@D@PDb@D@@@@@@@@D@`hP`T@@@@@@@@D@`@@BDd`@@@@@@D`ddT`@@`@@@@@@DBaII``@`@@@@@@D@QIYB`d`@@@@@@d@aII`@`@@@@@@@`@d`ddd`@@@@@@@`R@`D@@@@@@@@@@`D@@D@@@@@@@@@@ddd@D@@@@@@@@@@@@Ddd@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
    DATA "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@dd`@@@@@@@@@@@@`@d@@@@@@@@@@@@`@D@dd@@@@@@@@@`PDd`D@@@@@@@@@`BPP@T@@@@@@@@@deDP@D`@@@@@@@@D@d@PPd@@@@@@@@DB@dD`L@@@@@@@@D@bdPDL@@@@@@@@Dd@BIdL@@@@@@@@@`@DKIL@@@@@@@@@`RDIIL@@@@@@@@@`Ddddd@@@@@@@@@`D@@@@@@@@@@@@@dd@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
    DATA "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@Dddd@@@@@@@@Dddd@@D@@@@@@@@D@@DBjD@@@@@@@@DRD@Ddddd@@@@@@DDdIIId@D@@@@@@D@BIIIdDD@@@@@@DDdIII@@D@@@@@@d@Dd`d`bd@@@@@@`DP@`B@``@@@@@@`BBR@`T``@@@@@@`@PPdbP``@@@@@@dd`@@P@``@@@@@@@@d`d`@``@@@@@@@@@`@@`@`@@@@@@@@@dddd@`@@@@@@@@@@@@Dd`@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
    DATA "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@dddddd@@@@@@@@@`A@d@D@@@@@@@@@`a@@ED@@@@@@Ddd`dILDd`@@@@@d@dILd`@@dd@@@@`PdIH@BD@PD@@@@`@@ID``dD`D@@@@ddTdTB@`@`d@@@@Dd@`@DbBP``@@@@D@BP``P`T``@@@@D@@@@@@@@@`@@@@Ddddddddd@`@@@@@@@@@@@@Dd`@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
    DATA "@@@@@@@@@@@@@@@@@@@Ddd`@@@@@@@@@@@D@Edd@@@@@@@@@DddB@D@@@@@@@@@D@D`@Dd`@@@@@@@DBd@d@@`@@@@@@@D@D@dd``@@@@@@@DDRB@@``@@@@@@@D@PPd```@@@@@@@DD@B@```@@@@@@@DD@b`@``@@@@@@@dDd`@```@@@@@@@`B@dd```dd@@@@D`@B@@B@d`Dd`Ddd@d`PTBD@AII`D@@D`@@D@d@aII`DBRP@Dddbd@DLa`D`@D`@@@@@@DII`@d@ddddddd`@II`@D@`@@@@@@dd`D`@Dd`@@@@@@@@dd@@@@@@@@@@@@@@@@"
    DATA "@@@@@@@@@@@@@@@@@@@@@dddddd@@@@@@@@@aIIIIL@@@@@@@@daaaaaL@@@@@@@@`@IIIIL@@@@@@@@eBBBCKL@@@@@@@DdddDddd@@@@@@dd@D@@d@`@@@@@D`@BD@@`Pd@@@@@D@b`d`db@D`@@@@DB@PP@`PPP`@@@@D@`Pd@@@DP`@@@@D@BddTdbd@`@@@@Dd`D`@`@D@`@@@@@@bD`@``R@`@@@@@@`@`P`B@@`@@@@@@d``RD@Pd`@@@@@@@``@DBD`@@@@@@@@`ddddD@@@@@@@@@`@@@@D@@@@@@@@@dddddd@@@@@@@@@@@@@@@@@@@"
    DATA "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ddddd@@@@@@@@@@aHD@D@@@@@@@@@@aH@@D@@@@@@@@@@aHD@dd@@@@@@@@Dddd@`D`@@@@@@@D@@@@@@`@@@@@@@D@`D`D@`@@@@@@Dd`d@ddD`@@@@@@D@PDddD@`@@@@@@DDB@PDB@`@@@@@@DEPB@D@D`@@@@@@Dd`dDddd@@@@@@@@@`@D@@@@@@@@@@@@ddd@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
    DATA "@@@@@@@@@@@@@@@@@@@@@@@dd@@@@@@@Dddddd`Ddd@@@@@D@@`D@PD@D`@@@@DBBB@P`PP@`@@@@DbB@DE`P@P`@@@@d`@ddddddD`@@@@`BB`DIII`T@@@@@``@`DIIIdD@@@@@`D`dDAII`D@@@@@``@@BIIIBD@@@@@``PdDIII`D@@@@@`BB`DIII`T@@@@@`P@`Dbdd`D@@@@@`PPddBB@PT@@@@@dD@@BBBB@Dd@@@@D@dddB@@P@D@@@@D@@@@DDdddD@@@@DdddDP@@@@D@@@@@@@D@Dddddd@@@@@@@Ddd@@@@@@@@@@@@@@@@@@@@@@"
    DATA "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@Dddd@@@@@@@@@@@D@`Dd`@@@@@@@@@DBbD@d@@@@@@dddd@`D@Dddd`@@aIHDBbD@T@`@`@@aILD@@DPD@@@`@@aLH@B`DB@@b@`@@aIEd@bDPD@`@`@@aIHdB`@@Tddd`@@dddd@bTPD@@@@@@@@@DB`D@T@@@@@@@@@D@`D@D@@@@@@@@@Dd`Ddd@@@@@@@@@@@dd@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
    DATA "@@@@@@@@@@@@@@@@@@Ddddd`@@@@@@@@@DIIIIdd@@@@@@@@DLLII`D@@@@@@@@DIIIIRD@@@@@@@@D@@Ad`Dd`@@@@@Ddddd@P`@`@@@@@D@@B@BB@P`@@@@@D@`@D@PT@`@@@@@D`dd`@`D@`@@@@@DB@@D@Dd``@@@@@d@T@DD`D@`@@@@@`@Dbd`@D@d@@@@@`P@BD@`D@D@@@@@dd`@DD``dD`@@@@@@b``B@PP@`@@@@@@e`BbR@`@`@@@@@@d`B@@@dd`@@@@@@@d@`D@`@@@@@@@@@Ddddd`@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
    DATA "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@dd@@@@@@@@@@Ddd`Ddd@@@@@Dddd@@@D@D@@@@@D@@@PPdDDD@@@@@D@ddB@`@@L@@@@@D@@@P``dLL@@@@@DbddPPPdLL@@@@@D@@D@@ddLd@@@@@DB@Ddd`DLL@@@DddbRd@@@lLL@@@D@@@`@DTTdHL@@@DDd`bRR@@`IL@@@DD@@P@@`@`IL@@@DD@D`d@@DdIL@@@DDddbddd@ddd@@@D@@@@`@D@`@@@@@Ddddd`@Dd`@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
    DATA "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@Ddddd@@@@@@@@@@D@@@D@@@@@@@@@@D@@@Dd`@@@@@@@@D`ddD@`@@@@@@@@D`ed@@`@@@@@@@@DBRB@R`@@@@@@@@D@`dB@`@@@@@@@@D@`d@Pdd@@@@@@@Dd`BRB`D@@@@@@@@`@d@AIL@@@@@@@@``@`aHL@@@@@@@@`@``dIL@@@@@@@@dd`PDIL@@@@@@@@@@d@Ddd@@@@@@@@@@Ddd@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
    DATA "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@dddddddd`@@@@@@aI@D@@`@d`@@@@DaII@T```P`@@@@DIII`B@`B@`@@@@DIII`D@```d@@@@DddddB@P``Dd@@@@D@@DTbD`d@D@@@@d@B@@`PB@DD@@@@`D`d``DddTD@@@@`PR@@B@B@@D@@@@`P@BdPddddD@@@@ddd`ED`@@Dd@@@@@@@ddd@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
    DATA "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ddd`@@@@@@@@@@@eD@`@@@@@@@@@@@`P@`@@@@@@@@@@DdD``@@@@@@@@@ddB@`d@@@@@@@@@`@@@`D`@@@@@@@@`PTd`P`@@@@@@@@`RD@`B`@@@@@@@@b@P@b@`@@@@@@@D`BT@BPd@@@@@@@DBPD@`BD@@@@@@@D@@Dd`PD@@@@@@@D@bdId@D@@@@@@@DdAaILdd@@@@@@@@DAIIId@@@@@@@@@DII@AL@@@@@@@@@Dddddd@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
    DATA "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@Ddd@@@@@@@@dddDd@Dd`@@@@dd`@DdBB@P`@@Dd`D`bB@@P`@`@@DII@BPPPB@DT`@@DIDD``@dbdD@`@@DII@@`d`@D@@`@@DII@@`d@PDdP`@@DIddd@PD@ddD`@@Dd`@D@Dd@@hD@@@@@@@Dddddddd@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
    DATA "@@@@@@@@@@@@@@@@@@@Ddd@@@@@@@@@@@@D@Dddd@@@@@@@@@DBDd@D@@@@@@@@@DB@@RD@@@@@@@@@D`dd@D@@@@@@@@@d``DDd@@@@@@@@@`@`Dl`@@@@@@@@@`R@@P`@@@@@@@@@`@``Pdd@@@@@@@@dd``@`D@@@@@@@@D@Bdd@D@@@@@@@@D@P@@PD@@@@@@@@D`@dd`d@@@@@@@@Ddddd`D@@@@@@@@dII`PBD@@@@@@@@aII`R`D@@@@@@@@aHI`PBD@@@@@@@@aIIP@`D@@@@@@@@d@ddddd@@@@@@@@Dd`@@@@@@@@@@@@@@@@@@@@@@@"
    DATA "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ddd`@@@@@@@@@@@`D@dd`@@@@@@@@D`D@aId`@@@@@@@D@T@aI@`@@@@@@@DBDRAI@`@@@@@@@D@T@aIA`@@@@@@@D@DBdddd@@@@@@@Db@@@BBD@@@@@@@D`D@RD@D@@@@@@@@ddd@dRl@@@@@@@@@@D@@@d@@@@@@@@@@Dddd`@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
    DATA "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@dd@@@@@@@@@@@@@`Ddddd@@@@@@@@D`D`l@D@@@@@@@@D@TBB@Dd`@@@@@@DPB@`PT@d@@@@@@d@T`bB@@D@@@@@@`D@``@RPD@@@@@@`P@B@T`dd@@@@@@`PPb`D@`@@@@@@@d@d`DdP`@@@@@@@D@aIH@@`@@@@@@@DdaIILd`@@@@@@@@DIIdd@@@@@@@@@@DIL`@@@@@@@@@@@DIL@@@@@@@@@@@@Ddd@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
    DATA "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@dd@@@@@@@@@@@dd`D@@@@@@@@@@D`@@T@@@@@@@@@@dB@dDd@@@@@@@@@ePP`PD@@@@@@@@@ddD`@T@@@@@@@@@DIIbBD@@@@@@@@@DII`@T@@@@@@@@@DII@RD`@@@@@@@@DIH`P@`@@@@@@@@DddbB@`@@@@@@@@@@@`@d`@@@@@@@@@@@bDd@@@@@@@@@@@@`D@@@@@@@@@@@@@dd@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
    DATA "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@Dddddd`@@@@@@@@D`@@d@`@@@@@@@@D`@P@P`@@@@@@@@Dd`dBP`@@@@@@@@D@BD@@`@@@@@@@@DBRDDd`@@@@@@@@D@DDBD`@@@@@@@@D@`D@P`@@@@@@@@DB`T@@`@@@@@@@@D@ALDd`@@@@@@@@DdaHPe`@@@@@@@@DIILB``@@@@@@@@DaIL@P`@@@@@@@@DdId@@`@@@@@@@@Dddddd`@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
    DATA "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@Dddddd`Ddd`@@@@D@D@@eddII`@@@@D@BT@@@AII`@@@@D@DDd@D`II`@@@@D`dDd@`@II`@@@@@`PP@@`dDd`@@@@@`BBd@`@@@`@@@@Dd``Dd`dD``@@@@D@`b@D`d@@`@@@@DB@PDD`ddd`@@@@DDBB@@``@@@@@@@D@PdD```@@@@@@@DBP@@R@`@@@@@@@D`dDdB@`@@@@@@@@`@DD@@`@@@@@@@@dddDdd`@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
    DATA "@@@@@@@@@@@@@@@@@@@@Dd`@@@@@@@@@@@Dd@d@@@@@@@@@@dd@PD@@@@@@@@@@`@PPDd`@@@@@@@@`P@`P@`dd@@@@@@`D@`@P`aL@@@@@@dTPddTdaL@@@@@@D@DddD`IL@@@@@@DTDedD`AL@@@@@@DD@@P@@IL@@@@@@D@Dd`d`AL@@@@@@DdD``D`IL@@@@@@@dPddPdaL@@@@@@@`@d@@`aL@@@@@@D`Rd@P`dd@@@@@@D@@BRP`@@@@@@@@DBDd@@`@@@@@@@@D@DDdd`@@@@@@@@Ddd@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
    DATA "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ddddd`@@@@@@@@@aIIH@dddd`@@@@@aIIH@`D`@`@@@@@aLdB@@P@@`@@@@@aIBBD@d`@`@@@@@aIbdd`@D@`@@@@@d`@D@DPDBd`@@@@@`BPPPBd@P`@@@@@`B@DT@d@@`@@@@@d`dD@Pddd`@@@@@D@PPdD`@@@@@@@@D@@PB@`@@@@@@@@D`@``@`@@@@@@@@@ddedd`@@@@@@@@@@@d`@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
    DATA "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@Ddddd@@@@@@@@@@DII@D`@@@@@@@@@DLL@Pd@@@@@@@@@dII``l`@@@@@@@@`II`D@d@@@@@@@@`@@bDbD@@@@@@@@dDd@P@D@@@@@@@@DPBBB`D@@@@@@@@DD@PPdD@@@@@@@@D@d`D`D@@@@@@@@D@@dD`d@@@@@@@@D@P`B@`@@@@@@@@DdPP@d`@@@@@@@@@D@dd`@@@@@@@@@@Dd`@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
    DATA "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@Dd@@@@@@@@@@@@@dLd@@@@@@@@@@@@aIL@@@@@@ddddddaIL@@@@@D`@d@@DaILdd@@@D@Rd@PlaIH@D@@@D@@@RB`AIL@D@@@D@PdBP`aIL@d@@@D@PdB@`dDd@`@@@D`dd`d`@@@@`@@@D`@PBDddDd@`@@@DBd`DDddDDd`@@@D@B@D@@@D@@@@@@D@PbBBd`D@@@@@@DBR`P@`dd@@@@@@D@@`BP`@@@@@@@@Ddd`@d`@@@@@@@@@@@dd`@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
    DATA "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@Dd`@@@@@@@@@DdddE`@@@@@@@@@D@@B@`@@@@@@@@@D@BdB`@@@@@@@@@DbaI``@@@@@@@@@@`QI@`@@@@@@@@@@`aA`d@@@@@@@@@@`@`bD@@@@@@@@@@b@P@D@@@@@@@@@@`Dddd@@@@@@@@@@dd@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
    DATA "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@dd`@@@@@@@@@@@D`@d@@@@@@@@@@@d@@D@@@@@@@@@@D`BPD@@@@@@@@@@dBPBD@@@@@@@@@@`P@BD@@@@@@Dd`@`@RDdd@@@@@D@ddddD`@D@@@@@DI@@@@@BRl@@@@@DLDdddD`@d@@@@@DLDdddHbBd`@@@@DIIIIIH`@P`@@@@Ddddddd`B@`@@@@@@@@@@@d@d`@@@@@@@@@@@Dd`@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
    DATA "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@Dddd`@@@@@@@@@@Dl`@dd@@@@@@@@@DB@B@D@@@@@@@@@D@PPRT@@@@@@@@@DBTD@D@@@@@@@@@dP@B@D@@@@@@@@@`B@RRT`@@@@@@@@`Td``@`@@@@@@@@`BII`@`@@@@@@@@`dIIbP`@@@@@@@@`dII@D`@@@@@@@@`@II`D@@@@@@@@@dDIIbT@@@@@@@@@DDII`D@@@@@@@@@D@@@@D@@@@@@@@@Dd`dTd@@@@@@@@@@@`@D@@@@@@@@@@@@ddd@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
    DATA "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@dddddd@@@@@@@@@`@@@@D`@@@@@@@@`DDRB@`@@@@@@@@bDT@dE`@@@@@@@D`dDBDD`@@@@@@@D@BDPDD@@@@@@@@D@DB@DD@@@@@@@@D`PP@dD@@@@@@@@D@`D`BD@@@@@@@@D@@dBTD@@@@@@@dddR@D@D@@@@@@@aIL@dddd@@@@@@@aaID`@@@@@@@@@@aIH@`@@@@@@@@@@aIH@`@@@@@@@@@@dddd`@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
    DATA "@@@@@@@@@@@@@@@@@@@ddd@@@@@@@@@@Ddd@D@@@@@@@@@@D@DDDdd@@@@@@@@DBD@P@Ddd`@@@@@dPDdD`@@@`@@@@d`BPPP`D`@dd`@@`@@@P@dddD`@`@@`Dddd`e@DD@``@@dDd@@@ddDTD@`@@DDdDd`dID@BD`@@D@PB@bdIDT`D`@@D@```@@IdD`P`@@Dd`@`dDI`@B@`@@@@dd`@DI```D`@@@@@@dddI`@`d@@@@@@@@@DIdd`D@@@@@@@@@DI@@@D@@@@@@@@@D`Dd@d@@@@@@@@@@dddd`@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
    DATA "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@Dddd@@@@@@@@@Ddd@`Dd`@@@@@@@D@D@B@@`@@@@@@ddDRD`d@`@@@@@D`@@DD@dDd@@@@@D@d`TPB@PD@@@@@DIH@DD`D@D@@@@@DIL@@h`d`d@@@@@DIL@d`B@PD@@@@@Dddd`d@D@D@@@@@@@@@@Ddddd@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
    DATA "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@dddd`Dd`@@@@@@@`@d@dd@`@@@@@@@`@P@`B@`@@@@@@@`DD``@@dd@@@@@@dB@BBTD@D@@@@@@dd@`DBB@D@@@@dd`Dd`@DdIL@@@@`@bD@`ddIIL@@@@`@@D@``dIIL@@@@dddD@b@DdIL@@@@@D@D``T@DIL@@@@@d@@@B@TDdd@@@@D`RT`DB@D@@@@@@D@D@`d`Dd@@@@@@D@B@bEdd@@@@@@@Ddd@`@`@@@@@@@@@@Dddd`@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
    DATA "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@dd`@@@@@@@@@@@@`@`@@@@@@@@@@@@``ddd@@@@@@@@@@`@@Bldd`@@@@@@@`PdPd`@`@@@@@@@`ddB@@P`@@@@@@@`dd``DPdd@@@@@D`Dd`dP@@D@@@@@D@T@PDD`dD@@@@@D@@@@DDILD@@@@@Ddd`Dd@IHD@@@@@@@@ddDDILD@@@@@@@@@@DDdDD@@@@@@@@@@D@@@D@@@@@@@@@@Ddddd@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
    DATA "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@dd@@@@@@@@@@@@@`D`@@@@@@@@@@@@`@d@@@@@@@@@@@@`RD`@@@@@@@@@@db@Pd@@@@@@@@Dd`@B@D@@@@@@@Dd@`dd`D@@@@@@@D@@`aIJD@@@@@@@DD@BAILD@@@@@@@D@P`aYLD@@@@@@@Dd@ddDdD@@@@@@@@Dd`j@dT`@@@@@@@@@d`P@@`@@@@@@@@@@`D`@`@@@@@@@@@@dddd`@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
    DATA "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@Dddddd`@@@@@@@@dI@@`@`@@@@@@@DaKB@@P`@@@@@@@dIY``bD`@@@@@@@aKLDDB@`@@@@@DdaI`D@@``@@@@@D@dD@@@@@`@@@@@DEPPd`DDD`@@@@@DB@B@DD@D@@@@@@DdR@DDDDD@@@@@@@D@B@DDDdd@@@@@@DB`dd`@@D@@@@@@DP@`@`@`D@@@@@@D@d`@d@@D@@@@@@D@`@@D@@d@@@@@@Dd`@@Ddd`@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
    DATA "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@Ddddddd@@@@@@@@D@@d`@D@@@@@@@@D@@BB@dd@@@@@@Dd``@PP@D@@@@@@dB@bddBBD@@@@@d`@``@d`BD@@@@@`PB@`B@`dd@@@@@`dTd`b`B@d`@@@@`d@d````B@`@@@@`@EP@P@`P``@@@@dd`D@d@`T@`@@@@@aIDddPD@``@@@@@aIII`RDP``@@@@@aIII`@@@@`@@@@@aIIIddd`D`@@@@@dddd`@@dd@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
    DATA "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@DddDd`@@@@@@@@@DILD@dd@@@@@@@@DILd@PD@@@@@@@@DIIdB@Td@@@@@@@DaIL`@PD@@@@@@@DdIHdBBD@@@@@@@DD`@D@PD@@@@@@@D@dDDdDd`@@@@@@DBDDPB@@`@@@@@@D@PhP@B@`@@@@@@D@DBBPPd`@@@@@@D@ddd@d`@@@@@@@DD`@Dd`@@@@@@@@Dd@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
    DATA "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@Dd`@@@@@@@@@@@@d@dd`@@@@@@@@@@`@@@`dd`@@@@@@@`Td@d`@`@@@@@@@aL@TD@``@@@@@@@aL@@@R`d`@@@@@@a\D@bB@@dd`@@@@aL@d@@Db`@`@@@@aZ@P`d@P@@`@@@@aL`B@D@Ddd`@@@@a\bd@Ddd@@@@@@@aHBDdd@@@@@@@@@`DED@@@@@@@@@@@dddd@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
    DATA "@@@@@@@@@@@@@@@@@@@@Ddddd`@@@@@@@@@D@d`@`@@@@@@@@@DB@B@`@@@@@@@@@D@ddT`@@@@@@@@@D``D@`@@@@@@@@@d@aX@`@@@@@@@@@`DaL@`@@@@@@@@@`ha\D`@@@@@@@@@`baLP`@@@@@@@@@`PaL@`@@@@@@@@@``c\@`@@@@@@@@@`PaLT`@@@@@@@@@`@A\@`@@@@@@@@Dd@`D@`@@@@@@@@d@@dd@`@@@@@@@@`DdddT`@@@@@@@@`P@@B@`@@@@@@@@`D`@`@`@@@@@@@@dddddd`@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
    DATA "@@@@@@@@@@@@@@@@@dddddddddd`@@@@`@d@`@`@`@`@@@@`P@@P@P@P@d@@@DddD@`@d`dTd@@@D@DDbddd@D@D@@@DB@DAIIL@DBD@@@D``DAIILdd@D@@@D`ddddaL@DDd@@@D@@@@@aLB@D@@@@DD`d`daL``Dd@@@DD@D@DaL`d`D@@@D@E@@@QL@@@D@@@DD@D@D`D@D`D@@@DddDdddddd`d@@@D@@@@@`@`@BD@@@DB@`PPP@``@D@@@DDT`T@dD`@DD@@@D@PRDd`PBDDD@@@D@@@@@`@`@@D@@@Dddddddddddd@@@@@@@@@@@@@@@@@"
    DATA "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@Ddddddddddd@@@@d@@@@@@@@@D@@@@`@BD@@@dD@D@@@@`Ddd`d`DT`d@@@@dT@DbaIH@``@@@@`D@@PaIL```@@@@`P```aIL`@`@@@@`PbP@aILb``@@@@``UTbaIL`@`@@@@`@RP@aIL@@`@@@@`B`@`dddBd`@@@@d@`dbPB@BD@@@@@d@@DB@Pd@D@@@@@Ddd@D@Dddd@@@@@@@Ddddd@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
    DATA "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ddddd@@@@@@@@@@`@@@Dd`@@@@@@@@`dddD@d@@@@@@@@``PPPBD@@@@@@@@`@@@b@D@@@@@@@@db@R`Dd@@@@@@@@@`D``T`@@@@@@@@@dT@BE`@@@@@@@@@D@PPd`@@@@@@@@@DD@B@`@@@@@@@@@DD`@``@@@@@@@@@d@dd``@@@@@@@@@`@@@@`@@@@@@@@@aIIId`@@@@@@@@@aIII`@@@@@@@@@@dddd`@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
    DATA "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@Dd`@@@@@@@@Ddddd@d@@@@@@@@d@P@@BDdd@@@@@@`@dD`@dIL@@@@@@`bPPRbdIL@@@@@@``@E@`@IL@@@@@@`B`dbP@IL@@@@@@`PBPBDaIL@@@@@@db@@@Dddd@@@@@@@`Dddd@@@@@@@@@@dd@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
    DATA "@@@@@@@@@@@@@@@@@@@@@@Ddd`@@@@@@@@@Ddd@@`@@@@@@@@@D@dD@dd`@@@@@@@D@CLI`@`@@@dd`ddBaaI@@`@@@`@d`D`cIIdD`@@@`P@@D`aLIdD@@@Ddd``@`cLddD@@@D@DBb``aLddD@@@DB@P@@`cH@DD@@@D`d@Pd``D`DD@@@@`B@Pd`dd`dD@@@@dbdbd`Dd`dD@@@Dd``@@@@d`DD@@@D@P`Bdd@dbTldd@D@@@P``Dd`DT@D@Dd``B``@@@@@@D@@@`B@`d@d@dddd@@@d@d`Dddd`@@@@@@Dd`@@@@@@@@@@@@@@@@@@@@@@@@@"
    DATA "@@@@@@@@@@@@@@@@@@@Dd`@@@@@@@@@@@@D@`@@@@@@@@@@@@D@dddd@@@@@@Dddd@`@@D@@@@@@D@DDDDD@D`@@@@@DB@@B@d@P`@@@@@d`TD@``@@dddd`@`B@`B``RD@DD@`D``@`@@d`@BDD@`D@b@DDd@`DBTD@`D@@T`PD@D`PDDD`ddPP`@D`D@B@@I``D@@d``PPd`DdK``@@d@RE@P@@dII``D`D`@PDT@dIIY`dD@PDDBd@dIIYd`dD`B@`P`DIIYd`@`@BDd`@`IIYd`@@`@`D@`D@IYd`@@@dddd@ddddd`@@@@@@@@@@@@@@@@@@@"
    DATA "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@dd`@@@@@@@@@@@@`@dd@@@@@@@@@@@`P@Dd`Dd`@@@@@@`@`T@dd@`@@ddddd``@P@`@`@@aH@@`PDd``D@`@@aJ@`@PD@P`PL`@@a\DBBD`D`@DL@@@aLPh`@d@@RDL@@@aLBB@PPd@D`L@@@aZP`d@BDTBDL@@@aL@@@d@D@@DL@@@aLddd@d`dddL`@@`R@@@@@@@@@Yd@@`Ddddddddd`AL@@dd@@@@@@@@ddd@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"

END SUB

SUB Ingame (Stg)
    ReGame:
    InitStage Stg
    LOCATE 10, 34: COLOR 14: PRINT USING " #####"; Player.Boxes;
    LOCATE 13, 34: COLOR 10: PRINT USING " #####"; Player.Goals;
    DO
        IF _EXIT THEN
            ' Ctrl-Break
            ExitSign = True
            EXIT SUB
        END IF

        SELECT CASE _KEYHIT
            CASE 18432 ' Up
                DX = 0: DY = -1: GOSUB KeyProc
            CASE 20480 ' Down
                DX = 0: DY = 1: GOSUB KeyProc
            CASE 19200 ' Left
                DX = -1: DY = 0: GOSUB KeyProc
            CASE 19712 ' Right
                DX = 1: DY = 0: GOSUB KeyProc
            CASE 82, 114 'R
                GOTO ReGame
            CASE 27 'ESC
                EXIT SUB
        END SELECT
        IF Player.Boxes = Player.Goals THEN
            GOTO GameComplete
        END IF
    LOOP
    'GoSub
    KeyProc:
    X = Player.X: Y = Player.Y
    SELECT CASE CurrentStage(Y + DY, X + DX)
        CASE 0 TO 1 ' Empty OR Spot
            GOSUB ValidMove
        CASE 2, 3 ' Box
            IF CurrentStage(Y + DY * 2, X + DX * 2) <= 1 THEN
                ' Dest is empty or spot
                GOSUB BoxMove
                GOSUB ValidMove
            END IF
    END SELECT
    RETURN

    'Gosub
    ValidMove:
    K = CurrentStage(Y, X)
    COLOR ObjSprite(K).Colors MOD 32, ObjSprite(K).Colors \ 32
    LOCATE Y + 2, X + 2: PRINT ObjSprite(K).Char;
    COLOR ObjSprite(5).Colors MOD 32, ObjSprite(5).Colors \ 32
    LOCATE Y + DY + 2, X + DX + 2: PRINT ObjSprite(5).Char;
    Player.X = X + DX: Player.Y = Y + DY
    Player.Moves = Player.Moves + 1
    LOCATE 16, 34: COLOR 11: PRINT USING " #####"; Player.Moves;
    RETURN

    'Gosub
    BoxMove:
    IF CurrentStage(Y + DY, X + DX) = 3 THEN
        ' Exit Spot Box
        Player.Goals = Player.Goals - 1
    END IF
    CurrentStage(Y + DY, X + DX) = CurrentStage(Y + DY, X + DX) - 2
    IF CurrentStage(Y + DY * 2, X + DX * 2) = 1 THEN
        ' Enter Spot Box
        Player.Goals = Player.Goals + 1
    END IF
    CurrentStage(Y + DY * 2, X + DX * 2) = CurrentStage(Y + DY * 2, X + DX * 2) + 2
    K = CurrentStage(Y + DY * 2, X + DX * 2)
    COLOR ObjSprite(K).Colors MOD 32, ObjSprite(K).Colors \ 32
    LOCATE Y + DY * 2 + 2, X + DX * 2 + 2: PRINT ObjSprite(K).Char;
    LOCATE 13, 34: COLOR 10, 0: PRINT USING " #####"; Player.Goals;
    RETURN

    GameComplete:
    LOCATE 22, 34: COLOR 13: PRINT "Great!";
    IF NOT Records(Player.Stage).Comp THEN
        Records(Player.Stage).Comp = True
        Records(Player.Stage).Moves = Player.Moves
        RecordFlag = True
    ELSEIF Records(Player.Stage).Moves > Player.Moves THEN
        Records(Player.Stage).Moves = Player.Moves
        RecordFlag = True
    END IF
    LOCATE 19, 34: COLOR 9, 0: PRINT USING " #####"; Records(Stg).Moves;
    LOCATE 25, 1: COLOR 15, 1
    PRINT "  Ent.: Next Stage / ESC: Stage Select  ";

    DO
        IF _EXIT THEN
            ' Ctrl-Break
            ExitSign = True
            EXIT SUB
        END IF

        SELECT CASE _KEYHIT
            CASE 13 'Enter
                Player.Stage = Player.Stage + 1
                IF Player.Stage > 60 THEN
                    Player.Stage = 1
                END IF
                GOTO ReGame
            CASE 27 'ESC
                EXIT SUB
        END SELECT
    LOOP

END SUB

SUB InitStage (Stg)
    Player.Moves = 0
    Player.Boxes = 0
    Player.Goals = 0
    FOR J = 0 TO 21
        FOR I = 0 TO 29
            SELECT CASE Stages(Stg, J, I)
                CASE 2 ' Normal Box
                    CurrentStage(J, I) = 2
                    Player.Boxes = Player.Boxes + 1
                CASE 3 ' Spot Box
                    CurrentStage(J, I) = 3
                    Player.Boxes = Player.Boxes + 1
                    Player.Goals = Player.Goals + 1
                CASE 5 ' Player
                    CurrentStage(J, I) = 0
                    Player.X = I: Player.Y = J
                CASE ELSE
                    CurrentStage(J, I) = Stages(Stg, J, I)
            END SELECT
        NEXT I
    NEXT J
    ShowStage Stg
END SUB

SUB ShowStage (Stg)
    COLOR 7, 0: CLS
    LOCATE 25, 1: COLOR 0, 7
    PRINT "  Arrow: Move / R: Restart / ESC: Exit  ";

    ' Box
    LOCATE 2, 34: COLOR 15, 0: PRINT CHR$(3);
    COLOR 7, 0
    LOCATE 1, 1: PRINT CHR$(218) + STRING$(30, 196) + CHR$(183);
    FOR J = 2 TO 24
        LOCATE J, 1: PRINT CHR$(179) + SPACE$(30) + CHR$(186);
    NEXT J
    LOCATE 24, 1: PRINT CHR$(212) + STRING$(30, 205) + CHR$(188);
    LOCATE 2, 36: PRINT "PJW48";
    LOCATE 3, 33: PRINT "Soukoban";
    LOCATE 5, 33: PRINT CHR$(218) + STRING$(6, 196) + CHR$(183);
    FOR J = 6 TO 19
        IF J MOD 3 = 2 THEN
            LOCATE J, 33: PRINT CHR$(195) + STRING$(6, 196) + CHR$(182);
        ELSE
            LOCATE J, 33: PRINT CHR$(179) + SPACE$(6) + CHR$(186);
        END IF
    NEXT J
    LOCATE 20, 33: PRINT CHR$(212) + STRING$(6, 205) + CHR$(188);

    LOCATE 6, 34: COLOR 15: PRINT "Stage";: LOCATE 7, 34: COLOR 12: PRINT USING "   ###"; Stg;
    LOCATE 9, 34: COLOR 15: PRINT "Boxes";
    LOCATE 12, 34: COLOR 15: PRINT "Goals";
    LOCATE 15, 34: COLOR 15: PRINT "Moves";: LOCATE 16, 34: COLOR 11: PRINT "     0";
    LOCATE 18, 34: COLOR 15: PRINT "Best";
    LOCATE 19, 34
    IF Records(Stg).Comp THEN
        COLOR 9: PRINT USING " #####"; Records(Stg).Moves;
    ELSE
        COLOR 8: PRINT " -----";
    END IF

    FOR J = 0 TO 21
        FOR I = 0 TO 29
            K = Stages(Stg, J, I)
            COLOR ObjSprite(K).Colors MOD 32, ObjSprite(K).Colors \ 32
            LOCATE J + 2, I + 2
            PRINT ObjSprite(K).Char;
        NEXT I
    NEXT J
    COLOR 7, 0
END SUB

SUB StageSelect
    Redraw:
    COLOR 7, 0: CLS
    LOCATE 21, 3
    PRINT "Stage ..   Comp.: ...   Moves: #####"
    LOCATE 23, 5: COLOR 13: PRINT "Home Page";
    LOCATE 23, 16: COLOR 11: PRINT "https://en.pjw48.net/";
    LOCATE 25, 1: COLOR 0, 7
    PRINT " Arrow: Move / Ent.: Select / ESC: Quit ";
    LOCATE 2, 2: COLOR 11, 0: PRINT "PJW48 Soukoban"
    LOCATE 2, 28: COLOR 15: PRINT "Stage Select"
    FOR I = 0 TO 59
        X = (I MOD 10) * 4 + 1: Y = (I \ 10) * 3 + 3
        IF Records(I + 1).Comp THEN
            COLOR 14
        ELSE
            COLOR 7
        END IF
        LOCATE Y + 1, X + 1: PRINT USING "##"; I + 1;
    NEXT I
    COLOR 15
    GOSUB DrawLine

    DO
        IF _EXIT THEN
            ' Ctrl-Break
            EXIT SUB
        END IF
        SELECT CASE _KEYHIT
            CASE 18432 ' Up
                D = -10: GOSUB KeyProc
            CASE 20480 ' Down
                D = 10: GOSUB KeyProc
            CASE 19200 ' Left
                D = -1: GOSUB KeyProc
            CASE 19712 ' Right
                D = 1: GOSUB KeyProc
            CASE 13 ' Enter
                Ingame Player.Stage
                GOTO Redraw:
            CASE 27 'ESC
                EXIT SUB
        END SELECT

        IF ExitSign THEN
            EXIT SUB
        END IF
    LOOP

    'GoSub
    KeyProc:
    GOSUB RemoveLine
    Player.Stage = Player.Stage + D
    IF ABS(D) >= 10 THEN
        IF Player.Stage >= 70 THEN
            Player.Stage = 1
        ELSEIF Player.Stage > 60 THEN
            Player.Stage = Player.Stage - 59
        ELSEIF Player.Stage <= -9 THEN
            Player.Stage = 60
        ELSEIF Player.Stage <= 0 THEN
            Player.Stage = Player.Stage + 59
        END IF
    ELSE
        IF Player.Stage > 60 THEN
            Player.Stage = Player.Stage - 60
        ELSEIF Player.Stage <= 0 THEN
            Player.Stage = Player.Stage + 60
        END IF
    END IF
    GOSUB DrawLine
    RETURN

    'GoSub
    DrawLine:
    I = Player.Stage - 1
    X = (I MOD 10) * 4 + 1: Y = (I \ 10) * 3 + 3
    COLOR 15
    LOCATE Y, X: PRINT CHR$(201); STRING$(2, 205); CHR$(187);
    LOCATE Y + 1, X: PRINT CHR$(186);: LOCATE Y + 1, X + 3: PRINT CHR$(186);
    LOCATE Y + 2, X: PRINT CHR$(200); STRING$(2, 205); CHR$(188);
    LOCATE 21, 9: PRINT USING "##"; Player.Stage;
    IF Records(Player.Stage).Comp THEN
        COLOR 14
        LOCATE 21, 21: PRINT "Yes";
        LOCATE 21, 34: PRINT USING "#####"; Records(Player.Stage).Moves;
    ELSE
        COLOR 8
        LOCATE 21, 21: PRINT " No";
        LOCATE 21, 34: PRINT "-----";
    END IF
    RETURN

    'GoSub
    RemoveLine:
    I = Player.Stage - 1
    X = (I MOD 10) * 4 + 1: Y = (I \ 10) * 3 + 3
    LOCATE Y, X: PRINT "    ";
    LOCATE Y + 1, X: PRINT " ";: LOCATE Y + 1, X + 3: PRINT " ";
    LOCATE Y + 2, X: PRINT "    ";
    RETURN

END SUB
