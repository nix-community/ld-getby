#include <pthread.h>
#include <stdlib.h>
#include <netdb.h>
#include <errno.h>
#include <nss.h>
static pthread_mutex_t mutex = PTHREAD_MUTEX_INITIALIZER;
enum nss_status _nss_files_getprotobyname_r(const char*, struct protoent*,
                                            char*, size_t, int*);
struct protoent *getprotobyname(const char *name)
{
  static size_t blen;
  static struct protoent resbuf;
  static char *buf = NULL;
  struct protoent *ret = NULL;
  int errp = errno, status;
  /* This buf variable is for holding all of the characters of struct
     protoent and it will have pointers towards this buffer, which is the
     reason why we need to lock the mutex here.
   */
  pthread_mutex_lock(&mutex);
  if (buf == NULL) {
    blen = 1024;
    buf = malloc(blen);
  }
  /* Realloc the buffer repeatedly until the function no longer returns
     NSS_STATUS_TRYAGAIN.
   */
  while (buf != NULL && (
    status = _nss_files_getprotobyname_r(name, &resbuf, buf, blen, &errp)
  ) == NSS_STATUS_TRYAGAIN) {
    char *newbuf;
    blen *= 2;
    if ((newbuf = realloc(buf, blen)) == NULL) {
      errp = errno;
      free(buf);
    }
    buf = newbuf;
  }
  if (status != NSS_STATUS_SUCCESS || buf == NULL) {
    errno = errp;
    ret = NULL;
  } else {
    ret = &resbuf;
  }
  pthread_mutex_unlock(&mutex);
  return ret;
}
