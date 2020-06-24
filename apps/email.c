//
// Simple Email User Agent
// Bobbi June 2020
// Handles INBOX in the format created by POP65
//

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <conio.h>
#include <string.h>

char filename[80];
FILE *fp;
struct emailhdrs *headers;

// Configuration params from POP65.CFG
char cfg_server[80];         // IP of POP3 server
char cfg_user[80];           // Username
char cfg_pass[80];           // Password
char cfg_spooldir[80];       // ProDOS directory to spool email to
char cfg_inboxdir[80];       // ProDOS directory for email inbox

// Represents the email headers for one message
struct emailhdrs {
  char date[80];
  char from[80];
  char to[80];
  char cc[80];
  char subject[80];
  struct emailhdrs *next;
};

/*
 * Keypress before quit
 */
void confirm_exit(void)
{
  printf("\nPress any key ");
  cgetc();
  exit(0);
}

/*
 * Called for all non IP65 errors
 */
void error_exit()
{
  confirm_exit();
}

/*
 * Read parms from POP65.CFG
 */
void readconfigfile(void) {
    fp = fopen("POP65.CFG", "r");
    if (!fp) {
      puts("Can't open config file POP65.CFG");
      error_exit();
    }
    fscanf(fp, "%s", cfg_server);
    fscanf(fp, "%s", cfg_user);
    fscanf(fp, "%s", cfg_pass);
    fscanf(fp, "%s", cfg_spooldir);
    fscanf(fp, "%s", cfg_inboxdir);
    fclose(fp);
}

/*
 * Read EMAIL.DB
 */
void read_email_db(void) {
  struct emailhdrs *curr = NULL, *prev = NULL;
  uint16_t l;
  headers = NULL;
  sprintf(filename, "%s/EMAIL.DB", cfg_inboxdir);
  fp = fopen(filename, "rb");
  if (!fp) {
    printf("Can't open %s\n", filename);
    error_exit();
  }
  while (1) {
    curr = (struct emailhdrs*)malloc(sizeof(struct emailhdrs));
    curr->next = NULL;
    l = fread(curr, 1, sizeof(struct emailhdrs) - 2, fp);
    if (l != sizeof(struct emailhdrs) - 2) {
      free(curr);
      fclose(fp);
      return;
    }
    if (!prev)
      headers = curr;
    else
      prev->next = curr;
    prev = curr;
  }
}

/*
 * Print a header field from char postion start to end,
 * padding with spaces as needed
 */
void printfield(char *s, uint8_t start, uint8_t end) {
  uint8_t i;
  uint8_t l = strlen(s);
  for (i = start; i < end; i++)
    putchar(i < l ? s[i] : ' ');
}

/*
 * Show email summary
 */
void email_summary(void) {
  uint16_t i = 1;
  struct emailhdrs *h = headers;
  while (h) {
    printf("%02d|", i++);
    printfield(h->date, 0, 16);
    putchar('|');
    printfield(h->from, 0, 20);
    putchar('|');
    printfield(h->subject, 0, 39);
    //putchar('\r');
    h = h->next;
  }
}

void main(void) {
  videomode(VIDEOMODE_80COL);
  readconfigfile();
  read_email_db();
  email_summary();
  confirm_exit();
}

