#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

#define LONGEST 100
#define IPTABLES "/usr/sbin/iptables"
#define FILTCHAIN "hotControl"
#define NATCHAIN  "hotControl"

#define RESET "/etc/init.d/firewall"

#define FORMATERROR 3
#define SECURITYERROR 4

/* Arguments:
 *
 * add-filt|add-nat|del-filt|del-nat rulenum [mac]
 *
 * Return Values:
 *
 * 0 - Success
 * 1 - ipchains error
 * 2 - ipchains incorrect formatting
 * 3 - this script formatting error
 * 4 - this script possible security problem */

int main (int argc, char *argv[])
{
  char *command, *rulenum, *mac;
  char script [LONGEST];
  int i;
  
	/* Not much error checking at the moment */
  if (argc < 3) {
    exit (FORMATERROR);
  }

  command = argv [1];
  rulenum = argv [2];
  /* check for possible exploits */
  /* TODO -- Use atoi here */
  for (i = 0; i < strlen (rulenum); i++) {
    if ( !isdigit (rulenum [i]) ) {
      exit (SECURITYERROR);
    }
  }
  
  if ( strncmp (command, "add", 3) == 0 ) {
    if (argc < 4) {
      exit (FORMATERROR);
    }

    mac = argv [3];
    /* check for possible exploits */
    if ( strlen (mac) != 17 ) {
      exit (SECURITYERROR);
    }

    if ( strcmp (command, "add-filt") == 0 ) {
      return execl (IPTABLES, "", "-I", FILTCHAIN, rulenum, "-m", "mac", 
                    "--mac-source", mac, "-j", "RETURN", (char *) NULL);
    }

    if ( strcmp (command, "add-nat") == 0 ) {
      return execl (IPTABLES, "", "-t", "nat", "-I", NATCHAIN, rulenum, "-m", 
                    "mac", "--mac-source", mac, "-j", "ACCEPT", (char *) NULL);
    }
    exit (FORMATERROR);

  } else if ( strncmp (command, "del", 3) == 0 ) {

    if ( strcmp (command, "del-filt") == 0 ) {
      return execl (IPTABLES, "", "-D", FILTCHAIN, rulenum, (char *) NULL);
    }

    if ( strcmp (command, "del-nat") == 0 ) {
      return execl (IPTABLES, "", "-t", "nat", "-D", NATCHAIN, rulenum, (char *) NULL);
    }
  } else if ( strncmp (command, "reset", 5) == 0 ) {
    return execl (RESET, "", (char *) NULL);
  }

  exit (FORMATERROR);
}

