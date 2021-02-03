#ifndef __C_FILE_DELETER_HXX__
#define __C_FILE_DELETER_HXX__

#include <cstdio>


/**
 * \brief Functor for \c FILE pointer deletion.
 */
struct CFileDeleter
{
  /**
   * \brief   Closes a given file stream using libc \c fclose.
   * \param   file  A raw pointer to the stream to close.
   */
  void
  operator ()(FILE *file) noexcept
  {
    ::fclose(file);
  }
};

#endif /* __C_FILE_DELETER_HXX__ */