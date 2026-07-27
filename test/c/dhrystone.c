#pragma GCC optimize ("O1", "no-strict-aliasing")
#include <stdint.h>
#include <stdarg.h>



int putchar(int c) {
    return c;
}

int puts(const char* s) {
    while (*s) {
        putchar(*s++);
    }
    putchar('\n');
    return 0;
}

void* memcpy(void* dest, const void* src, unsigned int n) {
    char* d = (char*)dest;
    const char* s = (const char*)src;
    while (n--) {
        *d++ = *s++;
    }
    return dest;
}

void print_str(const char *s) {
    while (*s) putchar(*s++);
}

void print_dec(long val) {
    if (val < 0) {
        putchar('-');
        val = -val;
    }
    char buf[32];
    int idx = 0;
    if (val == 0) {
        putchar('0');
        return;
    }
    while (val > 0) {
        buf[idx++] = '0' + (val % 10);
        val /= 10;
    }
    for (int i = idx - 1; i >= 0; i--) {
        putchar(buf[i]);
    }
}

int printf(const char *fmt, ...) {
    return 0;
}

/* Custom string implementations to avoid dependencies on standard libraries */
char* strcpy(char* dest, const char* src) {
    char* d = dest;
    while ((*d++ = *src++));
    return dest;
}

int strcmp(const char* s1, const char* s2) {
    while (*s1 && (*s1 == *s2)) {
        s1++;
        s2++;
    }
    return *(unsigned char*)s1 - *(unsigned char*)s2;
}

/* RISC-V Cycle measurement macros */
#define read_csr(reg) ({ unsigned long __tmp; \
  asm volatile ("csrr %0, " #reg : "=r"(__tmp)); \
  __tmp; })

#define setStats(x)

/* =========================================================================
 * Dhrystone Benchmark Declarations & Definitions
 * ========================================================================= */

#define Version "C, Version 2.2"

#define HZ 8333333
#define Too_Small_Time 1
#define CLOCK_TYPE "rdcycle()"
#define Start_Timer() Begin_Time = read_csr(mcycle)
#define Stop_Timer() End_Time = read_csr(mcycle)

#define Mic_secs_Per_Second     1000000
#define NUMBER_OF_RUNS          10000 /* Default number of runs */

#ifdef  NOSTRUCTASSIGN
#define structassign(d, s)      memcpy(&(d), &(s), sizeof(d))
#else
#define structassign(d, s)      d = s
#endif

typedef enum {Ident_1, Ident_2, Ident_3, Ident_4, Ident_5} Enumeration;

#define Null 0 
#define true  1
#define false 0

typedef int     One_Thirty;
typedef int     One_Fifty;
typedef char    Capital_Letter;
typedef int     Boolean;
typedef char    Str_30 [32];  /* 31 chars + 1 null byte */
typedef int     Arr_1_Dim [50];
typedef int     Arr_2_Dim [50] [50];

typedef struct record {
    struct record *Ptr_Comp;
    Enumeration    Discr;
    union {
        struct {
            Enumeration Enum_Comp;
            int         Int_Comp;
            char        Str_Comp [31];
        } var_1;
        struct {
            Enumeration E_Comp_2;
            char        Str_2_Comp [31];
        } var_2;
        struct {
            char        Ch_1_Comp;
            char        Ch_2_Comp;
        } var_3;
    } variant;
} Rec_Type, *Rec_Pointer;

/* Global Variables: */
Rec_Pointer     Ptr_Glob,
                Next_Ptr_Glob;
int             Int_Glob;
Boolean         Bool_Glob;
char            Ch_1_Glob,
                Ch_2_Glob;
int             Arr_1_Glob [50];
int             Arr_2_Glob [50] [50];

Boolean         Done;

long            Begin_Time,
                End_Time,
                User_Time;
long            Microseconds,
                Dhrystones_Per_Second;

#define REG register
Boolean Reg = true;

/* Forward declarations */
void Proc_1 (Rec_Pointer Ptr_Val_Par);
void Proc_2 (One_Fifty *Int_Par_Ref);
void Proc_3 (Rec_Pointer *Ptr_Ref_Par);
void Proc_4 (void);
void Proc_5 (void);
void Proc_6 (Enumeration Enum_Val_Par, Enumeration *Enum_Ref_Par);
void Proc_7 (One_Fifty Int_1_Par_Val, One_Fifty Int_2_Par_Val, One_Fifty *Int_Par_Ref);
void Proc_8 (Arr_1_Dim Arr_1_Par_Ref, Arr_2_Dim Arr_2_Par_Ref, int Int_1_Par_Val, int Int_2_Par_Val);
Enumeration Func_1 (Capital_Letter Ch_1_Par_Val, Capital_Letter Ch_2_Par_Val);
Boolean Func_2 (Str_30 Str_1_Par_Ref, Str_30 Str_2_Par_Ref);
Boolean Func_3 (Enumeration Enum_Par_Val);

void debug_printf(const char* str, ...) {
    // Empty debug printf
}

/* =========================================================================
 * Dhrystone Functions from dhrystone.c
 * ========================================================================= */

#pragma GCC optimize ("no-inline")

void Proc_6 (Enumeration Enum_Val_Par, Enumeration *Enum_Ref_Par) {
    *Enum_Ref_Par = Enum_Val_Par;
    if (! Func_3 (Enum_Val_Par))
        *Enum_Ref_Par = Ident_4;
    switch (Enum_Val_Par) {
        case Ident_1: 
            *Enum_Ref_Par = Ident_1;
            break;
        case Ident_2: 
            if (Int_Glob > 100)
                *Enum_Ref_Par = Ident_1;
            else 
                *Enum_Ref_Par = Ident_4;
            break;
        case Ident_3: 
            *Enum_Ref_Par = Ident_2;
            break;
        case Ident_4: 
            break;
        case Ident_5: 
            *Enum_Ref_Par = Ident_3;
            break;
    }
}

void Proc_7 (One_Fifty Int_1_Par_Val, One_Fifty Int_2_Par_Val, One_Fifty *Int_Par_Ref) {
    One_Fifty Int_Loc;
    Int_Loc = Int_1_Par_Val + 2;
    *Int_Par_Ref = Int_2_Par_Val + Int_Loc;
}

void Proc_8 (Arr_1_Dim Arr_1_Par_Ref, Arr_2_Dim Arr_2_Par_Ref, int Int_1_Par_Val, int Int_2_Par_Val) {
    REG One_Fifty Int_Index;
    REG One_Fifty Int_Loc;

    Int_Loc = Int_1_Par_Val + 5;
    Arr_1_Par_Ref [Int_Loc] = Int_2_Par_Val;
    Arr_1_Par_Ref [Int_Loc+1] = Arr_1_Par_Ref [Int_Loc];
    Arr_1_Par_Ref [Int_Loc+30] = Int_Loc;
    for (Int_Index = Int_Loc; Int_Index <= Int_Loc+1; ++Int_Index)
        Arr_2_Par_Ref [Int_Loc] [Int_Index] = Int_Loc;
    Arr_2_Par_Ref [Int_Loc] [Int_Loc-1] += 1;
    Arr_2_Par_Ref [Int_Loc+20] [Int_Loc] = Arr_1_Par_Ref [Int_Loc];
    Int_Glob = 5;
}

Enumeration Func_1 (Capital_Letter Ch_1_Par_Val, Capital_Letter Ch_2_Par_Val) {
    Capital_Letter        Ch_1_Loc;
    Capital_Letter        Ch_2_Loc;

    Ch_1_Loc = Ch_1_Par_Val;
    Ch_2_Loc = Ch_1_Loc;
    if (Ch_2_Loc != Ch_2_Par_Val)
        return (Ident_1);
    else {
        Ch_1_Glob = Ch_1_Loc;
        return (Ident_2);
    }
}

Boolean Func_2 (Str_30 Str_1_Par_Ref, Str_30 Str_2_Par_Ref) {
    REG One_Thirty        Int_Loc;
    Capital_Letter    Ch_Loc;

    Int_Loc = 2;
    while (Int_Loc <= 2) {
        if (Func_1 (Str_1_Par_Ref[Int_Loc], Str_2_Par_Ref[Int_Loc+1]) == Ident_1) {
            Ch_Loc = 'A';
            Int_Loc += 1;
        }
    }
    if (Ch_Loc >= 'W' && Ch_Loc < 'Z')
        Int_Loc = 7;
    if (Ch_Loc == 'R')
        return (true);
    else {
        if (strcmp (Str_1_Par_Ref, Str_2_Par_Ref) > 0) {
            Int_Loc += 7;
            Int_Glob = Int_Loc;
            return (true);
        }
        else 
            return (false);
    }
}

Boolean Func_3 (Enumeration Enum_Par_Val) {
    Enumeration Enum_Loc;
    Enum_Loc = Enum_Par_Val;
    if (Enum_Loc == Ident_3)
        return (true);
    else 
        return (false);
}

/* =========================================================================
 * Dhrystone Functions from dhrystone_main.c
 * ========================================================================= */

int main (void) {
    One_Fifty       Int_1_Loc;
    REG   One_Fifty       Int_2_Loc;
    One_Fifty       Int_3_Loc;
    REG   char            Ch_Index;
    Enumeration     Enum_Loc;
    Str_30          Str_1_Loc;
    Str_30          Str_2_Loc;
    REG   int             Run_Index;
    REG   int             Number_Of_Runs;

    Number_Of_Runs = NUMBER_OF_RUNS;

    /* Allocating struct variables using stack */
    Next_Ptr_Glob = (Rec_Pointer) __builtin_alloca (sizeof (Rec_Type));
    Ptr_Glob = (Rec_Pointer) __builtin_alloca (sizeof (Rec_Type));

    Ptr_Glob->Ptr_Comp                    = Next_Ptr_Glob;
    Ptr_Glob->Discr                       = Ident_1;
    Ptr_Glob->variant.var_1.Enum_Comp     = Ident_3;
    Ptr_Glob->variant.var_1.Int_Comp      = 40;
    strcpy (Ptr_Glob->variant.var_1.Str_Comp, "DHRYSTONE PROGRAM, SOME STRING");
    strcpy (Str_1_Loc, "DHRYSTONE PROGRAM, 1'ST STRING");

    Arr_2_Glob [8][7] = 10;

    debug_printf("\n");
    debug_printf("Dhrystone Benchmark, Version %s\n", Version);
    if (Reg) {
        debug_printf("Program compiled with 'register' attribute\n");
    } else {
        debug_printf("Program compiled without 'register' attribute\n");
    }
    debug_printf("Using %s, HZ=%d\n", CLOCK_TYPE, HZ);
    debug_printf("\n");

    Done = false;
    while (!Done) {
        debug_printf("Trying %d runs through Dhrystone:\n", Number_Of_Runs);

        setStats(1);
        Start_Timer();

        for (Run_Index = 1; Run_Index <= Number_Of_Runs; ++Run_Index) {
            Proc_5();
            Proc_4();
            Int_1_Loc = 2;
            Int_2_Loc = 3;
            strcpy (Str_2_Loc, "DHRYSTONE PROGRAM, 2'ND STRING");
            Enum_Loc = Ident_2;
            Bool_Glob = ! Func_2 (Str_1_Loc, Str_2_Loc);
            while (Int_1_Loc < Int_2_Loc) {
                Int_3_Loc = 5 * Int_1_Loc - Int_2_Loc;
                Proc_7 (Int_1_Loc, Int_2_Loc, &Int_3_Loc);
                Int_1_Loc += 1;
            }
            Proc_8 (Arr_1_Glob, Arr_2_Glob, Int_1_Loc, Int_3_Loc);
            Proc_1 (Ptr_Glob);
            for (Ch_Index = 'A'; Ch_Index <= Ch_2_Glob; ++Ch_Index) {
                if (Enum_Loc == Func_1 (Ch_Index, 'C')) {
                    Proc_6 (Ident_1, &Enum_Loc);
                    strcpy (Str_2_Loc, "DHRYSTONE PROGRAM, 3'RD STRING");
                    Int_2_Loc = Run_Index;
                    Int_Glob = Run_Index;
                }
            }
            Int_2_Loc = Int_2_Loc * Int_1_Loc;
            Int_1_Loc = Int_2_Loc / Int_3_Loc;
            Int_2_Loc = 7 * (Int_2_Loc - Int_3_Loc) - Int_1_Loc;
            Proc_2 (&Int_1_Loc);
        }

        Stop_Timer();
        setStats(0);

        User_Time = End_Time - Begin_Time;

        if (User_Time < Too_Small_Time) {
            printf("Measured time too small to obtain meaningful results\n");
            Number_Of_Runs = Number_Of_Runs * 10;
            printf("\n");
        } else {
            Done = true;
        }
    }

    int failed = 0;
    if (Int_Glob != 5) failed = 1;
    else if (Bool_Glob != 1) failed = 2;
    else if (Ch_1_Glob != 'A') failed = 3;
    else if (Ch_2_Glob != 'B') failed = 4;
    else if (Arr_1_Glob[8] != 7) failed = 5;
    else if (Arr_2_Glob[8][7] != Number_Of_Runs + 10) failed = 6;
    else if (Next_Ptr_Glob->Discr != 0) failed = 7;
    else if (Next_Ptr_Glob->variant.var_1.Enum_Comp != 1) failed = 8;
    else if (Next_Ptr_Glob->variant.var_1.Int_Comp != 18) failed = 9;
    else if (strcmp(Next_Ptr_Glob->variant.var_1.Str_Comp, "DHRYSTONE PROGRAM, SOME STRING") != 0) failed = 10;
    else if (Int_1_Loc != 5) failed = 11;
    else if (Int_2_Loc != 13) failed = 12;
    else if (Int_3_Loc != 7) failed = 13;
    else if (Enum_Loc != 1) failed = 14;
    else if (strcmp(Str_1_Loc, "DHRYSTONE PROGRAM, 1'ST STRING") != 0) failed = 15;
    else if (strcmp(Str_2_Loc, "DHRYSTONE PROGRAM, 2'ND STRING") != 0) failed = 16;

    if (failed != 0) {
        *((volatile uint32_t*) 0x00480014) = 0xEEEE0000 | failed;
        *((volatile uint32_t*) 0x00480000) = 1; // Test fail
    } else {
        *((volatile uint32_t*) 0x00480014) = Number_Of_Runs;
        *((volatile uint32_t*) 0x00480014) = User_Time;
        *((volatile uint32_t*) 0x00480000) = 0; // Test pass
    }

    *((volatile uint32_t*) 0x00480000) = 2; // Halt simulation

    return 0;
}

void Proc_1 (Rec_Pointer Ptr_Val_Par) {
    REG Rec_Pointer Next_Record = Ptr_Val_Par->Ptr_Comp;  
    structassign (*Ptr_Val_Par->Ptr_Comp, *Ptr_Glob); 
    Ptr_Val_Par->variant.var_1.Int_Comp = 5;
    Next_Record->variant.var_1.Int_Comp = Ptr_Val_Par->variant.var_1.Int_Comp;
    Next_Record->Ptr_Comp = Ptr_Val_Par->Ptr_Comp;
    Proc_3 (&Next_Record->Ptr_Comp);
    if (Next_Record->Discr == Ident_1) {
        Next_Record->variant.var_1.Int_Comp = 6;
        Proc_6 (Ptr_Val_Par->variant.var_1.Enum_Comp, &Next_Record->variant.var_1.Enum_Comp);
        Next_Record->Ptr_Comp = Ptr_Glob->Ptr_Comp;
        Proc_7 (Next_Record->variant.var_1.Int_Comp, 10, &Next_Record->variant.var_1.Int_Comp);
    } else {
        structassign (*Ptr_Val_Par, *Ptr_Val_Par->Ptr_Comp);
    }
}

void Proc_2 (One_Fifty *Int_Par_Ref) {
    One_Fifty  Int_Loc;  
    Enumeration   Enum_Loc = Ident_1;

    Int_Loc = *Int_Par_Ref + 10;
    do {
        if (Ch_1_Glob == 'A') {
            Int_Loc -= 1;
            *Int_Par_Ref = Int_Loc - Int_Glob;
            Enum_Loc = Ident_1;
        }
    } while (Enum_Loc != Ident_1);
}

void Proc_3 (Rec_Pointer *Ptr_Ref_Par) {
    if (Ptr_Glob != Null)
        *Ptr_Ref_Par = Ptr_Glob->Ptr_Comp;
    Proc_7 (10, Int_Glob, &Ptr_Glob->variant.var_1.Int_Comp);
}

void Proc_4 (void) {
    Boolean Bool_Loc;
    Bool_Loc = Ch_1_Glob == 'A';
    Bool_Glob = Bool_Loc | Bool_Glob;
    Ch_2_Glob = 'B';
}

void Proc_5 (void) {
    Ch_1_Glob = 'A';
    Bool_Glob = false;
}
