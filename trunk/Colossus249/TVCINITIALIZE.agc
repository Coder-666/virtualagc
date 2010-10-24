# Copyright:	Public domain.
# Filename:	TVCINITIALIZE.agc
# Purpose:	Part of the source code for Colossus, build 249.
#		It is part of the source code for the Command Module's (CM)
#		Apollo Guidance Computer (AGC), possibly for Apollo 8 and 9.
# Assembler:	yaYUL
# Reference:	pp. 903-906 of 1701.pdf.
# Contact:	Ron Burkey <info@sandroid.org>.
# Website:	www.ibiblio.org/apollo/index.html
# Mod history:	08/22/04 RSB.	Transcribed.
#		05/14/05 RSB	Corrected website reference above.
#		2010-10-24 JL	Indentation fixes.
#
# The contents of the "Colossus249" files, in general, are transcribed 
# from a scanned document obtained from MIT's website,
# http://hrst.mit.edu/hrs/apollo/public/archive/1701.pdf.  Notations on this
# document read, in part:
#
#	Assemble revision 249 of AGC program Colossus by NASA
#	2021111-041.  October 28, 1968.  
#
#	This AGC program shall also be referred to as
#				Colossus 1A
#
#	Prepared by
#			Massachusetts Institute of Technology
#			75 Cambridge Parkway
#			Cambridge, Massachusetts
#	under NASA contract NAS 9-4065.
#
# Refer directly to the online document mentioned above for further information.
# Please report any errors (relative to 1701.pdf) to info@sandroid.org.
#
# In some cases, where the source code for Luminary 131 overlaps that of 
# Colossus 249, this code is instead copied from the corresponding Luminary 131
# source file, and then is proofed to incorporate any changes.

# Page 903
# NAME		TVCDAPON (TVC DAP INITIALIZATION AND STARTUP CALL)
# MOD NO 3					DATE 6 JUNE, 1967
# MOD BY ENGEL					LOG SECTION P40-P47
#
# FUNCTIONAL DESCRIPTION
#	PERFORMS TVCDAP INITIALIZATION (GAINS, TIMING PARAMETERS, FILTER VARIABLES, ETC.)
#	COMPUTES STEERING (S40.8) GAIN KPRIMEDT, AND ZEROES PASTDELV,+1 VARIABLE
#	MAKES INITIALIZATION CALL TO "NEEDLER" FOR TVC DAP NEEDLES-SETUP
#	PERFORMS INITIALIZATION FOR ROLL DAP
#	CALLS TVCEXECUTIVE AT TVCEXEC, VIA WAITLIST
#	CALLS TVCDAP CDU-RATE INITIALIZATION PKG AT DAPINIT VIA T5
#	MRCLEAN AND TVCINIT4 ARE POSSIBLE TVC-RESTART ENTRIES
#
# CALLING SEQUENCE:  T5LOC=2CADR(TVCDAPON,EBANK=BZERO), T5=.6SECT5
#	IN PARTICULAR, CALLED BY "IGNOVER"
#
# NORMAL EXIT MODE
#	TCF	RESUME
#
# SUBROUTINES CALLED
#	NEEDLER, MASSPROP
#
# ALARM OR ABORT EXIT MODES
#	NONE
#
# ERASABLE INITIALIZATION REQUIRED
#	CSMMASS, LEMMASS, DAPDATR1 (FOR MASSPROP SUBROUTINE)
#	TVC PAD LOADS (SEE LEVEL III DAP AND/OR P40 TESTS)
#	PACTOFF, YACTOFF, CDUX
#	TVCPHASE, T5BITS OF FLAGWRD6, FOR RESTART PROTECTION (SEE IGNOVER)
#
# OUTPUT
#	ALL TVC AND ROLL DAP ERASABLES, FLAGWRD6 (BITS 13,14), T5, WAITLIST
#
# DEBRIS
#	NONE

		COUNT*	$$/INIT
		BANK	17
		SETLOC	DAPS7
		BANK
		
		EBANK=	BZERO
		
TVCDAPON	LXCH	BANKRUPT	# T5 RUPT ARRIVAL (CALL BY DOTVCON - P40)
		EXTEND			# SAVE Q REQUIRED IN RESTART (MRCLEAN AND
		QXCH	QRUPT		#	TVCINIT4 ARE ENTRIES)
MRCLEAN		CAF	NZERO		# NUMBER TO ZERO, LESS ONE  (MUST BE ODD)
					#	TVC RESTARTS ENTER HERE  (NEW BANK)
 +1		CCS	A
		TS	CNTR
		CAF	ZERO
		TS	L
		INDEX	CNTR
		DXCH	OMEGAYC		# FIRST (LAST) TWO LOCATIONS
		CCS	CNTR
		TCF	MRCLEAN +1
# Page 904
		EXTEND			# SET UP ANOTHER T5 RUPT TO CONTINUE
		DCA	INITLOC2	#	INITIALIZATION AT TVCINIT1
		DXCH	T5LOC		# THE PHSCHK2 ENTRY (REDOTVC) AT TVCDAPON
		CAF	POSMAX		#	+3 IS IN ANOTHER BANK.  MUST RESET
		TS	TIME5		#	BBCON TOO (FULL 2CADR), FOR THAT
ENDMRC		TCF	RESUME		#	ENTRY.

TVCINIT1	LXCH	BANKRUPT
		EXTEND
		QXCH	QRUPT
		
		TC	IBNKCALL	# UPDATE IXX, IAVG/TLX FOR DAP GAINS (R03
		CADR	MASSPROP	#	OR NOUNS 46 AND 47 MUST BE CORRECT)
		
		CAE	EMDOT		# SPS FLOW RATE, SC.AT B+3 KG/CS
		EXTEND
		MP	ONETHOU
		TS	TENMDOT		# 10-SEC MASS LOSS B+16 KG
		COM
		AD	CSMMASS
		TS	MASSTMP		# DECREMENT FOR FIRST 10 SEC OF BURN
		
		CAE	DAPDATR1	# CHECK LEM-ON/OFF
		MASK	BIT14
		CCS	A
		CAF	BIT1		# LEM-ON (BIT1)
		TS	CNTR		# LEM-OFF (ZERO)
		
		INDEX	CNTR		# PICK UP LM-OFF,-ON KTLX/I
		CAE	EKTLX/I
		TS	KTLX/I
		
		TC	IBNKCALL	# COMPUTE 1/CONACC, VARK
		CADR	S40.15
		
TVCINIT2	CAE	ETVCDT/2	# LEM-ON VALUE (PAD-LOAD, CS / 2)
		TS	L
		CAF	BIT2		# LEM-OFF VALUE (4CS / 2)
		INDEX	CNTR
		CAE	A
		TS	KPRIMEDT	# (TEMP STORE)
		
		COM			# PREPARE T5TVCDT
		AD	POSMAX
		AD	BIT1
		TS	T5TVCDT
		
		CS	BIT15		# RESET SWTOVER FLAG
		MASK	FLAGWRD9
		TS	FLAGWRD9
# Page 905
		INDEX	CNTR		# PICK UP LEM-OFF,-ON KPRIME
		CAE	EKPRIME
		EXTEND
		MP	KPRIMEDT	# (TVCDT/2, BC.AT B+14 CS)
		LXCH	A		#	SC.AT PI/8	(DIMENSIONLESS)
		DXCH	KPRIMEDT
		
		INDEX	CNTR		# PICK UP LEM-OFF,-ON REPFRAC
		CAE	EREPFRAC
		TS	REPFRAC
		
		CAF	NEGONE		# PREVEN STOKE TEST UNTIL CALLED
		TS	STRKTIME
		
		CAF	NINETEEN	# SET VCNTR FOR VARIABLE-GAIN UPDATES IN
		TS	VCNTR		#	10 SECONDS (TVCEXEC 1/2 SEC RATE)
		TS	V97VCNTR	# FOR ENGFAIL (R41) LOGIC
		
		CAE	ETSWITCH	# PREPARE SWITCHOVER COUNTER
		TS	L
		DOUBLE			# (COUNTER DECREMENTS EVERY 1/2 SEC)
		LXCH	A		# LEM-OFF IN A, LEM-ON IN L
		INDEX	CNTR
		CAE	A
		AD	NEGONE
		TS	CNTR		# CNTR = 2(SWITCHOVER TIME, SEC) -1
TVCINIT3	CAE	PACTOFF		# TRIM VALUES TO TRIM-TRACKERS, OUTPUT
		TS	PDELOFF		#	TRACKERS, OFFSET-UPDATES, AND
		TS	PCMD		#	OFFSET-TRACKER FILTERS
		TS	DELPBAR		#	NOTE, LO-ORDER DELOFF, DELBAR ZEROED
		
		CAE	YACTOFF
		TS	YDELOFF
		TS	YCMD
		TS	DELYBAR
		
NEEDLEIN	CS	RCSFLAGS	# SET BIT 3 FOR INITIALIZATION PASS AND GO
		MASK	BIT3		# 	TO NEEDLER.  WILL CLEAR FOR TVC DAP
		ADS	RCSFLAGS	# 	(RETURNS AFTER CADR)
		TC	IBNKCALL
		CADR	NEEDLER
		
TVCINIT4	CAF	ZERO		# SET TVCPHASE TO INDICATE TVCDAPON-THRU-
		TS	TVCPHASE	#	NEEDLEIN INITIALIZATION FINISHED.
					#	(POSSIBLE TVC-RESTART ENTRY)
					
		CAE	CDUX		# PREPARE ROLL DAP LADDERS
		TS	OGANOW
# Page 906
					# ROLL DAPS RE-START UPON A RESTART, BUT
					#	RETAIN ORIGINAL OGAD (IGNOVER CDUX)
					
		CAF	BIT13		# IF ENGINE IS ALREADY OFF, ENGINOFF HAS
		EXTEND			#	ALREADY ESTABLISHED THE POST-BURN
		RAND	DSALMOUT	#	CSMMASS (MASSBACK DOES IT).  DON'T
		EXTEND			# 	TOUCH CSMMASS.  IF ENGINE IS ON,
		BZF	+3		#	THEN IT'S OK TO DO THE COPYCYCLE
					#	EVEN BURNS LESS THAN 0.4 SEC ARE AOK
					
		CAE	MASSTMP		# COPYCYCLE
		TS	CSMMASS
		
 +3		CAF	.5SEC		# CALL TVCEXECUTIVE (ROLLDAP CALL, ETC)
		TC	WAITLIST
		EBANK=	BZERO
		2CADR	TVCEXEC
		
		EXTEND			# CALL FOR DAPINIT
		DCA	DAPINIT5
		DXCH	T5LOC
		CAE	T5TVCDT		# (ALLOW TIME FOR RESTART COMPUTATIONS)
		TS	TIME5
		
ENDTVCIN	TCF	RESUME
NZERO		DEC	65		# MUST BE ODD FOR MRCLEAN

NINETEEN	=	VD1

ONETHOU		DEC	1000 B-13	# KG/CS B3 TO KG/10SEC B16 CONVERSION

		EBANK=	BZERO
DAPINIT5	2CADR	DAPINIT

		EBANK=	BZERO
INITLOC2	2CADR	TVCINIT1

