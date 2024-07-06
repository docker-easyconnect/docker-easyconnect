#define _GNU_SOURCE
#include <string.h>
#include <stdlib.h>
#include <errno.h>

int getlogin_r(char *buf, size_t bufsize) {
  const char *login = getenv("FAKE_LOGIN");
  if (!login)
    return ENXIO;
  size_t len = strlen(login);
  if (len + 1 > bufsize)
    return ERANGE;
  strcpy(buf, login);
  return 0;
}

const char *getlogin() {
  const char *login = getenv("FAKE_LOGIN");
  if (!login)
    return 0;
  return login;
}
