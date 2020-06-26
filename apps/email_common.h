/////////////////////////////////////////////////////////////////
// EMAIL_COMMON.H
// Definitions shared between pop65.c and email.c
// Bobbi June 2020
/////////////////////////////////////////////////////////////////

// Configuration params from POP65.CFG
char cfg_server[80];         // IP of POP3 server
char cfg_user[80];           // Username
char cfg_pass[80];           // Password
char cfg_spooldir[80];       // ProDOS directory to spool email to
char cfg_inboxdir[80];       // ProDOS directory for email inbox

// Represents the email headers for one message
struct emailhdrs {
  uint16_t emailnum;         // Name of file is EMAIL.n (n=emailnum)
  char     status;           // 'N' new, 'R' read, 'D' deleted
  uint16_t skipbytes;        // How many bytes to skip over the headers
  char     date[40];
  char     from[80];
  char     to[80];
  char     cc[80];
  char     subject[80];
#ifdef EMAIL_C
  struct emailhdrs *next;    // Used in email.c only for linked list
#endif
};

