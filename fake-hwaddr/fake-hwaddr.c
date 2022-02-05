#define _GNU_SOURCE
#include <dlfcn.h>
#include <net/if.h>
#include <net/if_arp.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define SIOCGIFHWADDR 0x8927

static char no_fake_hwaddr = 1;
static unsigned char hwaddr[6];
static int (*glibc_ioctl)(int, unsigned long, void *);

static void __attribute__((constructor)) init(void) {
  glibc_ioctl = dlsym(RTLD_NEXT, "ioctl");
  char *fake_hwaddr = getenv("FAKE_HWADDR");
  if (fake_hwaddr) {
    if (sscanf(fake_hwaddr, "%2hhx:%2hhx:%2hhx:%2hhx:%2hhx:%2hhx", hwaddr,
               hwaddr + 1, hwaddr + 2, hwaddr + 3, hwaddr + 4,
               hwaddr + 5) == 6 ||
        sscanf(fake_hwaddr, "%2hhx-%2hhx-%2hhx-%2hhx-%2hhx-%2hhx", hwaddr,
               hwaddr + 1, hwaddr + 2, hwaddr + 3, hwaddr + 4, hwaddr + 5) == 6)
      no_fake_hwaddr = 0;
    else
      printf("FAKE_HWADDR format error!\n");
  }
}

int ioctl(int fd, unsigned long request, void *arg) {
  if (request != SIOCGIFHWADDR || no_fake_hwaddr)
    return glibc_ioctl(fd, request, arg);
  int ret = glibc_ioctl(fd, SIOCGIFHWADDR, arg);
  if (ret != -1 && ((struct ifreq *)arg)->ifr_hwaddr.sa_family == ARPHRD_ETHER)
    memcpy(((struct ifreq *)arg)->ifr_hwaddr.sa_data, hwaddr, 6);
  return ret;
}